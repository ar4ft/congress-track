"""Stage complete assets in a draft; switch the latest feed only after upload succeeds."""
import json
import os
from pathlib import Path
import subprocess
import sys
from release_config import metadata, validate_tag

value = metadata()
tag = os.environ["RELEASE_TAG"]
validate_tag(value, tag)
required = ["CongressTrack-macOS.zip", "CongressTrack.dmg", "appcast.xml", "release-metadata.json", "SHA256SUMS"]
if not all((Path("dist") / name).is_file() for name in required):
    sys.exit("Release assets are incomplete")
for name in ("app", "dmg"):
    if json.loads(Path("dist/notarization-" + name + ".json").read_text())["status"] != "Accepted":
        sys.exit("Both application and disk image must be notarized before publishing")
subprocess.run(["shasum", "-a", "256", "-c", "SHA256SUMS"], cwd="dist", check=True)
existing = subprocess.run(["gh", "release", "view", tag, "--repo", value["repository"], "--json", "isDraft"], capture_output=True, text=True)
if existing.returncode == 0 and not json.loads(existing.stdout)["isDraft"]:
    sys.exit("Refusing to overwrite a published release")
notes = Path("dist/release-notes.md")
notes.write_text(
    "CongressTrack " + value["version"] + " for macOS 14 or later (Apple silicon and Intel).\n\n"
    "Download CongressTrack.dmg and drag CongressTrack into Applications. The application and installer are Developer ID signed and Apple notarized.\n\n"
    "This release includes Sparkle automatic updates with signed archives and a signed update feed. You can change automatic-update settings or choose Check for Updates from the app menu.\n\n"
    "Existing 0.2 builds do not include the updater; install this release manually once.\n"
)
if existing.returncode != 0:
    subprocess.run(["gh", "release", "create", tag, "--repo", value["repository"], "--verify-tag", "--draft",
                    "--title", "CongressTrack " + value["version"], "--notes-file", str(notes)], check=True)
subprocess.run(["gh", "release", "upload", tag, "--repo", value["repository"], "--clobber"] + [str(Path("dist") / name) for name in required], check=True)
# Upload to a draft cannot affect the stable /releases/latest/download/appcast.xml URL.
subprocess.run(["gh", "release", "edit", tag, "--repo", value["repository"], "--draft=false", "--latest"], check=True)
print("Published signed, notarized release: https://github.com/" + value["repository"] + "/releases/tag/" + tag)
