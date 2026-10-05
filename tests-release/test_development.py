import hashlib
import importlib.util
import json
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "scripts"))
spec = importlib.util.spec_from_file_location("development", ROOT / "scripts/publish-development.py")
development = importlib.util.module_from_spec(spec)
spec.loader.exec_module(development)


class DevelopmentReleaseTests(unittest.TestCase):
    commit = "a" * 40

    def environment(self):
        return {
            "GITHUB_EVENT_NAME": "push", "GITHUB_REF": "refs/heads/main", "GITHUB_SHA": self.commit,
            "GITHUB_REPOSITORY": "ar4ft/congress-track", "GITHUB_RUN_ID": "1234", "GITHUB_RUN_ATTEMPT": "1",
            "CONGRESSTRACK_RELEASE": "0",
        }

    def packages(self, directory):
        for name in development.PACKAGES:
            (directory / name).write_bytes(b"development package")

    def test_only_main_pushes_or_manual_unsigned_actions_can_publish(self):
        value = development.metadata()
        environment = self.environment()
        for changes in [
            {"GITHUB_EVENT_NAME": "pull_request"}, {"GITHUB_EVENT_NAME": "schedule"},
            {"GITHUB_REF": "refs/heads/feature"}, {"GITHUB_REF": "refs/tags/v0.3.0"},
            {"CONGRESSTRACK_RELEASE": "1"}, {"GITHUB_REPOSITORY": "fork/congress-track"},
            {"GITHUB_RUN_ID": ""}, {"GITHUB_RUN_ATTEMPT": "0"},
        ]:
            with self.subTest(changes=changes), self.assertRaises(ValueError):
                development.development_tag(value, environment | changes)
        automatic = development.development_tag(value, environment)
        manual = development.development_tag(value, environment | {"GITHUB_EVENT_NAME": "workflow_dispatch", "GITHUB_REF": "refs/heads/feature"})
        self.assertEqual(automatic, manual)
        retry = development.development_tag(value, environment | {"GITHUB_RUN_ATTEMPT": "2"})
        self.assertNotEqual(automatic, retry)

    def test_publish_stages_assets_and_never_updates_latest_or_appcast(self):
        with tempfile.TemporaryDirectory() as temporary:
            directory = Path(temporary)
            self.packages(directory)
            with patch.object(development.subprocess, "check_output", return_value=self.commit), patch.object(
                development.subprocess, "run", return_value=subprocess.CompletedProcess([], 1)
            ) as run:
                development.publish(directory, self.environment())
            commands = [call.args[0] for call in run.call_args_list]
            self.assertEqual([command[2] for command in commands], ["view", "create", "upload", "edit"])
            for command in [commands[1], commands[3]]:
                self.assertIn("--prerelease", command)
                self.assertIn("--latest=false", command)
            self.assertIn("--draft", commands[1])
            self.assertEqual(commands[1][commands[1].index("--target") + 1], self.commit)
            self.assertIn("--draft=false", commands[3])
            self.assertFalse(any("appcast.xml" in argument for command in commands for argument in command))
            manifest = json.loads((directory / "development-metadata.json").read_text())
            self.assertEqual(manifest["commit"], self.commit)
            for flag in ["developerIDSigned", "notarized", "automaticUpdates"]:
                self.assertFalse(manifest[flag])
            for line in (directory / "SHA256SUMS").read_text().splitlines():
                digest, name = line.split("  ")
                self.assertEqual(digest, hashlib.sha256((directory / name).read_bytes()).hexdigest())

    def test_failed_upload_leaves_release_unpublished(self):
        def command(arguments, **kwargs):
            if arguments[2] == "upload":
                raise subprocess.CalledProcessError(1, arguments)
            return subprocess.CompletedProcess(arguments, 1)
        with tempfile.TemporaryDirectory() as temporary:
            directory = Path(temporary)
            self.packages(directory)
            with patch.object(development.subprocess, "check_output", return_value=self.commit), patch.object(
                development.subprocess, "run", side_effect=command
            ) as run, self.assertRaises(subprocess.CalledProcessError):
                development.publish(directory, self.environment())
            self.assertNotIn("edit", [call.args[0][2] for call in run.call_args_list])

    def test_published_prereleases_cannot_be_overwritten(self):
        with tempfile.TemporaryDirectory() as temporary:
            directory = Path(temporary)
            self.packages(directory)
            with patch.object(development.subprocess, "check_output", return_value=self.commit), patch.object(
                development.subprocess, "run", return_value=subprocess.CompletedProcess([], 0, '{"isDraft":false}')
            ) as run, self.assertRaisesRegex(ValueError, "overwrite"):
                development.publish(directory, self.environment())
            self.assertEqual(run.call_count, 1)

    def test_incomplete_assets_stable_feed_and_wrong_commit_are_rejected(self):
        with tempfile.TemporaryDirectory() as temporary:
            directory = Path(temporary)
            with self.assertRaisesRegex(ValueError, "incomplete"):
                development.publish(directory, self.environment())
            self.packages(directory)
            feed = directory / "appcast.xml"
            feed.write_text("stable feed")
            with self.assertRaisesRegex(ValueError, "update feed"):
                development.publish(directory, self.environment())
            feed.unlink()
            with patch.object(development.subprocess, "check_output", return_value="b" * 40), self.assertRaisesRegex(ValueError, "source commit"):
                development.publish(directory, self.environment())


if __name__ == "__main__":
    unittest.main()
