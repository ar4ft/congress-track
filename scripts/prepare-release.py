"""Check release prerequisites and import credentials into an ephemeral keychain."""
import base64
import json
import os
from pathlib import Path
import re
import secrets
import shlex
import subprocess
import sys
import urllib.request
from release_config import metadata, validate_credentials, validate_progression, validate_tag


def run(command):
    result = subprocess.run(command, capture_output=True, text=True)
    if result.returncode:
        # Some tool errors include credential arguments; don't forward their output.
        raise ValueError("Credential setup command failed: " + command[0] + " " + command[1])
    return result.stdout


def check_release(value):
    validate_tag(value, os.environ.get("RELEASE_TAG", ""))
    if os.environ.get("GITHUB_REPOSITORY") != value["repository"]:
        raise ValueError("Release workflow must run in " + value["repository"])
    head = run(["git", "rev-parse", "HEAD"]).strip()
    tagged = run(["git", "rev-parse", os.environ["RELEASE_TAG"] + "^{commit}"]).strip()
    if head != tagged:
        raise ValueError("Checked-out commit must match the release tag")
    previous = subprocess.run(["gh", "api", "repos/" + value["repository"] + "/releases/latest"], capture_output=True, text=True)
    if previous.returncode:
        if "404" not in previous.stderr:
            raise ValueError("Unable to inspect the latest published release")
    else:
        release = json.loads(previous.stdout)
        asset = next((asset for asset in release["assets"] if asset["name"] == "release-metadata.json"), None)
        if asset is None:
            raise ValueError("Latest release is missing release-metadata.json; confirm its build number before proceeding")
        try:
            with urllib.request.urlopen(asset["browser_download_url"], timeout=30) as response:
                validate_progression(value, json.load(response))
        except ValueError:
            raise
        except Exception:
            raise ValueError("Unable to verify the previous release's build metadata") from None
    existing = subprocess.run(["gh", "api", "repos/" + value["repository"] + "/releases/tags/" + os.environ["RELEASE_TAG"]], capture_output=True, text=True)
    if existing.returncode == 0 and not json.loads(existing.stdout)["draft"]:
        raise ValueError("This tag already has a published release; increase the version/build")
    if existing.returncode != 0 and "404" not in existing.stderr:
        raise ValueError("Unable to inspect the target release")


def prepare():
    validate_credentials()
    value = metadata()
    check_release(value)
    folder = Path(os.environ["RUNNER_TEMP"]) / "CongressTrack-release"
    folder.mkdir(mode=0o700, exist_ok=True)
    certificate = folder / "DeveloperID.p12"
    certificate.write_bytes(base64.b64decode("".join(os.environ["MACOS_CERTIFICATE_BASE64"].split()), validate=True))
    apple_key = folder / "AuthKey.p8"
    apple_key.write_text(os.environ["APPLE_API_PRIVATE_KEY"])
    sparkle_key = folder / "sparkle-private-key"
    sparkle_key.write_text(os.environ["SPARKLE_PRIVATE_KEY"].strip())
    for file in (certificate, apple_key, sparkle_key):
        file.chmod(0o600)
    keychain = folder / "release.keychain-db"
    prior_keychains = shlex.split(run(["security", "list-keychains", "-d", "user"]))
    (folder / "prior-keychains.json").write_text(json.dumps(prior_keychains))
    password = secrets.token_urlsafe(40)
    run(["security", "create-keychain", "-p", password, str(keychain)])
    run(["security", "set-keychain-settings", "-lut", "21600", str(keychain)])
    run(["security", "unlock-keychain", "-p", password, str(keychain)])
    run(["security", "import", str(certificate), "-k", str(keychain), "-P", os.environ["MACOS_CERTIFICATE_PASSWORD"], "-T", "/usr/bin/codesign", "-T", "/usr/bin/security"])
    run(["security", "list-keychains", "-d", "user", "-s", str(keychain)] + prior_keychains)
    run(["security", "set-key-partition-list", "-S", "apple-tool:,apple:,codesign:", "-s", "-k", password, str(keychain)])
    identities = run(["security", "find-identity", "-v", "-p", "codesigning", str(keychain)])
    matches = [identity for identity in re.findall(r'"(Developer ID Application:[^"\n]+)"', identities)
               if identity.endswith("(" + os.environ["APPLE_TEAM_ID"] + ")")]
    if len(matches) != 1:
        raise ValueError("Certificate must provide one Developer ID Application identity matching APPLE_TEAM_ID")
    run(["xcrun", "notarytool", "store-credentials", "CongressTrack-ci", "--key", str(apple_key),
         "--key-id", os.environ["APPLE_API_KEY_ID"], "--issuer", os.environ["APPLE_API_ISSUER_ID"], "--keychain", str(keychain)])
    settings = {
        "CONGRESSTRACK_SIGNING_IDENTITY": matches[0], "CONGRESSTRACK_NOTARY_PROFILE": "CongressTrack-ci",
        "CONGRESSTRACK_NOTARY_KEYCHAIN": str(keychain), "CONGRESSTRACK_SPARKLE_KEY_FILE": str(sparkle_key),
    }
    with open(os.environ["GITHUB_ENV"], "a") as output:
        for key, val in settings.items():
            output.write(key + "=" + val + "\n")
    print("Release prerequisites verified and credentials imported into an ephemeral keychain.")


if __name__ == "__main__":
    try:
        prepare()
    except (ValueError, KeyError) as error:
        sys.exit(str(error))
