import base64
import importlib.util
import json
from pathlib import Path
import sys
import tempfile
import unittest
from unittest.mock import patch

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "scripts"))
import release_config as config

spec = importlib.util.spec_from_file_location("appcast", ROOT / "scripts/validate-appcast.py")
appcast = importlib.util.module_from_spec(spec)
spec.loader.exec_module(appcast)


class ReleaseTests(unittest.TestCase):
    def environment(self):
        return {
            "MACOS_CERTIFICATE_BASE64": base64.b64encode(b"test certificate").decode(),
            "MACOS_CERTIFICATE_PASSWORD": "test", "APPLE_API_PRIVATE_KEY": "-----BEGIN PRIVATE KEY-----test",
            "SPARKLE_PRIVATE_KEY": base64.b64encode(bytes(range(32))).decode(),
            "SPARKLE_PUBLIC_KEY": base64.b64encode(bytes(range(32))).decode(),
            "APPLE_TEAM_ID": "TESTTEAM", "APPLE_API_KEY_ID": "TESTKEY", "APPLE_API_ISSUER_ID": "TESTISSUER",
        }

    def test_missing_credentials_name_missing_fields_without_exposing_values(self):
        environment = self.environment()
        del environment["APPLE_API_PRIVATE_KEY"]
        with self.assertRaises(ValueError) as error:
            config.validate_credentials(environment)
        self.assertIn("APPLE_API_PRIVATE_KEY", str(error.exception))
        self.assertNotIn("BEGIN PRIVATE KEY", str(error.exception))

    def test_release_tag_must_match_metadata(self):
        value = config.metadata()
        config.validate_tag(value, "v" + value["version"])
        for invalid in ["main", "v0.1.0", "v1.0.0-beta.1"]:
            with self.assertRaises(ValueError): config.validate_tag(value, invalid)

    def test_automatic_actions_cannot_sign_even_with_credentials(self):
        for event in ["push", "pull_request", "schedule"]:
            environment = self.environment() | {"GITHUB_ACTIONS": "true", "GITHUB_EVENT_NAME": event}
            with self.assertRaisesRegex(ValueError, "manually"):
                config.validate_credentials(environment)
        config.validate_credentials(self.environment() | {"GITHUB_ACTIONS": "true", "GITHUB_EVENT_NAME": "workflow_dispatch"})

    def test_release_cannot_downgrade_build_or_marketing_version(self):
        with self.assertRaises(ValueError): config.validate_progression({"build": 3, "version": "0.3.0"}, {"build": 4, "version": "0.2.0"})
        with self.assertRaises(ValueError): config.validate_progression({"build": 4, "version": "0.2.0"}, {"build": 3, "version": "0.3.0"})
        config.validate_progression({"build": 4, "version": "0.4.0"}, {"build": 3, "version": "0.3.0"})

    def test_development_build_has_no_update_feed_or_public_key(self):
        import plistlib
        with tempfile.TemporaryDirectory() as directory, patch.dict(config.os.environ, {}, clear=True):
            file = Path(directory) / "Info.plist"
            config.write_plist(file)
            info = plistlib.loads(file.read_bytes())
            self.assertNotIn("SUPublicEDKey", info)
            self.assertNotIn("SUFeedURL", info)

    def test_production_configuration_enforces_signed_feed_and_archive(self):
        import plistlib
        environment = self.environment() | {"CONGRESSTRACK_RELEASE": "1", "RELEASE_TAG": "v" + config.metadata()["version"]}
        with tempfile.TemporaryDirectory() as directory, patch.dict(config.os.environ, environment, clear=True):
            file = Path(directory) / "Info.plist"
            config.write_plist(file)
            info = plistlib.loads(file.read_bytes())
            self.assertTrue(info["SURequireSignedFeed"])
            self.assertTrue(info["SUVerifyUpdateBeforeExtraction"])
            self.assertTrue(info["SUAutomaticallyUpdate"])
            self.assertFalse(info["SUSendProfileInfo"])

    def test_invalid_sparkle_key_is_rejected(self):
        environment = self.environment(); environment["SPARKLE_PUBLIC_KEY"] = "bad key"
        with self.assertRaises(ValueError): config.validate_credentials(environment)

    def test_appcast_rejects_wrong_archive_size_version_or_origin(self):
        value = config.metadata()
        prefix = "https://github.com/ar4ft/congress-track/releases/download/v" + value["version"] + "/"
        signature = base64.b64encode(bytes(64)).decode()
        with tempfile.TemporaryDirectory() as directory:
            archive = Path(directory) / "CongressTrack-macOS.zip"; archive.write_bytes(b"archive")
            feed = Path(directory) / "appcast.xml"
            xml = '<rss xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle"><channel><item>' \
                '<sparkle:version>{build}</sparkle:version><sparkle:shortVersionString>{version}</sparkle:shortVersionString>' \
                '<sparkle:minimumSystemVersion>14.0</sparkle:minimumSystemVersion>' \
                '<enclosure url="{url}" length="{length}" sparkle:edSignature="{signature}"/></item></channel></rss>'
            fields = dict(build=value["build"], version=value["version"], url=prefix + archive.name, length=7, signature=signature)
            feed.write_text(xml.format(**fields))
            self.assertEqual(appcast.validate(feed, archive, prefix, value), signature)
            for changed in [dict(length=8), dict(build=0), dict(url="https://example.com/update.zip"), dict(signature="bad")]:
                feed.write_text(xml.format(**(fields | changed)))
                with self.assertRaises(ValueError): appcast.validate(feed, archive, prefix, value)


if __name__ == "__main__":
    unittest.main()
