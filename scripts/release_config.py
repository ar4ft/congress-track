"""Public release metadata and production prerequisites; never emits secret values."""
import base64
import json
import os
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parent.parent
SECRET_NAMES = ("MACOS_CERTIFICATE_BASE64", "MACOS_CERTIFICATE_PASSWORD", "APPLE_API_PRIVATE_KEY", "SPARKLE_PRIVATE_KEY")
VARIABLE_NAMES = ("APPLE_TEAM_ID", "APPLE_API_KEY_ID", "APPLE_API_ISSUER_ID", "SPARKLE_PUBLIC_KEY")


def metadata(path=ROOT / "Release.json"):
    value = json.loads(Path(path).read_text())
    if not re.fullmatch(r"\d+\.\d+\.\d+", value.get("version", "")):
        raise ValueError("Release version must be a stable X.Y.Z version")
    if type(value.get("build")) is not int or value["build"] <= 0:
        raise ValueError("Release build must be a positive integer")
    if value.get("repository") != "ar4ft/congress-track" or value.get("minimumSystemVersion") != "14.0":
        raise ValueError("Release repository and minimum macOS version must match the app configuration")
    return value


def validate_tag(value, tag):
    if tag != "v" + value["version"]:
        raise ValueError("Release tag must match Release.json: v" + value["version"])


def validate_progression(current, previous):
    if current["build"] <= previous["build"]:
        raise ValueError("Release build must exceed the latest published build")
    if tuple(map(int, current["version"].split("."))) <= tuple(map(int, previous["version"].split("."))):
        raise ValueError("Release version must exceed the latest published version")


def validate_credentials(environment=os.environ):
    missing = [name for name in SECRET_NAMES + VARIABLE_NAMES if not environment.get(name, "").strip()]
    if missing:
        raise ValueError("Configure required GitHub Actions secrets/variables: " + ", ".join(missing))
    for name in ("SPARKLE_PUBLIC_KEY", "SPARKLE_PRIVATE_KEY"):
        try:
            data = base64.b64decode(environment[name].strip(), validate=True)
        except Exception:
            raise ValueError(name + " must be valid base64") from None
        if len(data) != 32:
            raise ValueError(name + " must encode a 32-byte key; export a current Sparkle key")
    try:
        if not base64.b64decode(environment["MACOS_CERTIFICATE_BASE64"], validate=True):
            raise ValueError()
    except Exception:
        # macOS base64 may wrap lines; accept only whitespace normalization.
        try:
            if not base64.b64decode("".join(environment["MACOS_CERTIFICATE_BASE64"].split()), validate=True):
                raise ValueError()
        except Exception:
            raise ValueError("MACOS_CERTIFICATE_BASE64 must contain the base64-encoded P12 certificate") from None
    if "PRIVATE KEY" not in environment["APPLE_API_PRIVATE_KEY"]:
        raise ValueError("APPLE_API_PRIVATE_KEY must contain the App Store Connect P8 private key")


def write_plist(destination):
    import plistlib
    value = metadata()
    production = os.environ.get("CONGRESSTRACK_RELEASE") == "1"
    public_key = os.environ.get("SPARKLE_PUBLIC_KEY", "").strip()
    if production:
        validate_credentials()
        validate_tag(value, os.environ.get("RELEASE_TAG", ""))
    info = {
        "CFBundleExecutable": "CongressTrack", "CFBundleIdentifier": "app.congresstrack.mac",
        "CFBundleName": "CongressTrack", "CFBundlePackageType": "APPL",
        "CFBundleShortVersionString": value["version"], "CFBundleVersion": str(value["build"]),
        "CFBundleIconFile": "AppIcon", "LSMinimumSystemVersion": value["minimumSystemVersion"],
        "NSHighResolutionCapable": True,
    }
    if production:
        info.update({
            "SUFeedURL": "https://github.com/ar4ft/congress-track/releases/latest/download/appcast.xml",
            "SUPublicEDKey": public_key,
            "SUEnableAutomaticChecks": True, "SUAutomaticallyUpdate": True, "SUAllowsAutomaticUpdates": True,
            "SUCheckUpdateInterval": 86400, "SUSendProfileInfo": False,
            "SUVerifyUpdateBeforeExtraction": True, "SURequireSignedFeed": True,
        })
    Path(destination).write_bytes(plistlib.dumps(info))


if __name__ == "__main__":
    import sys
    try:
        if len(sys.argv) == 3 and sys.argv[1] == "--plist":
            write_plist(sys.argv[2])
        else:
            value = metadata()
            if os.environ.get("CONGRESSTRACK_RELEASE") == "1":
                validate_credentials()
                validate_tag(value, os.environ.get("RELEASE_TAG", ""))
            print("Release metadata validated: " + value["version"] + " (build " + str(value["build"]) + ")")
    except (ValueError, KeyError, json.JSONDecodeError) as error:
        sys.exit(str(error))
