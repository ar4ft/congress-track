"""Publish unsigned development packages without changing the stable update feed."""
import hashlib
import json
import os
from pathlib import Path
import re
import subprocess

from release_config import metadata


PACKAGES = ("CongressTrack-macOS.zip", "CongressTrack.dmg", "CongressTrack-symbols.zip")


def development_tag(value, environment):
    if environment.get("CONGRESSTRACK_RELEASE", "0") != "0":
        raise ValueError("Production builds cannot be published as unsigned prereleases")
    event = environment.get("GITHUB_EVENT_NAME")
    if event not in ("push", "workflow_dispatch"):
        raise ValueError("Prereleases require a main-branch push or manual action")
    if event == "push" and environment.get("GITHUB_REF") != "refs/heads/main":
        raise ValueError("Only main-branch pushes publish development prereleases")
    if environment.get("GITHUB_REPOSITORY") != value["repository"]:
        raise ValueError("Prerelease repository must match Release.json")
    identifiers = [environment.get(name, "") for name in ("GITHUB_RUN_ID", "GITHUB_RUN_ATTEMPT")]
    if not all(re.fullmatch(r"[1-9][0-9]*", identifier) for identifier in identifiers):
        raise ValueError("A GitHub run ID and attempt are required")
    return "v" + value["version"] + "-dev." + ".".join(identifiers)


def publish(directory=Path("dist"), environment=None):
    environment = os.environ if environment is None else environment
    value = metadata()
    tag = development_tag(value, environment)
    if not all((directory / name).is_file() and (directory / name).stat().st_size for name in PACKAGES):
        raise ValueError("Development packages are incomplete or empty")
    # A development release never carries the signed stable feed.
    if (directory / "appcast.xml").exists():
        raise ValueError("Development prereleases must not contain a production update feed")
    commit = subprocess.check_output(["git", "rev-parse", "HEAD"], text=True).strip()
    if not re.fullmatch(r"[0-9a-f]{40}", commit):
        raise ValueError("A complete source commit is required")
    if environment["GITHUB_EVENT_NAME"] == "push" and commit != environment.get("GITHUB_SHA"):
        raise ValueError("Development packages must match the pushed source commit")
    run_url = "https://github.com/" + value["repository"] + "/actions/runs/" + environment["GITHUB_RUN_ID"]
    manifest = directory / "development-metadata.json"
    manifest.write_text(json.dumps(value | {
        "tag": tag, "commit": commit, "workflow": run_url,
        "developerIDSigned": False, "notarized": False, "automaticUpdates": False,
    }, indent=2) + "\n")
    assets = [directory / name for name in PACKAGES] + [manifest]
    checksums = directory / "SHA256SUMS"
    lines = []
    for path in assets:
        with path.open("rb") as archive:
            digest = hashlib.sha256()
            for chunk in iter(lambda: archive.read(1024 * 1024), b""):
                digest.update(chunk)
            lines.append(digest.hexdigest() + "  " + path.name + "\n")
    checksums.write_text("".join(lines))
    assets.append(checksums)
    notes = directory / "development-notes.md"
    notes.write_text(
        "Universal development build for macOS " + value["minimumSystemVersion"] + " or later (Apple silicon and Intel).\n\n"
        "**Unsigned development prerelease:** no Developer ID certificate signing or Apple notarization. "
        "Automatic updates are disabled. This build is intended for development testing.\n\n"
        "Download CongressTrack.dmg or CongressTrack-macOS.zip. SHA256SUMS verifies the downloaded files; "
        "development-metadata.json identifies their source.\n\n"
        "Source commit: `" + commit + "`\n\nBuild: " + run_url + "\n"
    )
    existing = subprocess.run(["gh", "release", "view", tag, "--repo", value["repository"], "--json", "isDraft"], capture_output=True, text=True)
    if existing.returncode == 0:
        if not json.loads(existing.stdout)["isDraft"]:
            raise ValueError("Refusing to overwrite a published prerelease")
    else:
        subprocess.run([
            "gh", "release", "create", tag, "--repo", value["repository"], "--target", commit,
            "--draft", "--prerelease", "--latest=false", "--title", "CongressTrack " + tag[1:] + " (unsigned)",
            "--notes-file", str(notes),
        ], check=True)
    subprocess.run(["gh", "release", "upload", tag, "--repo", value["repository"], "--clobber"] + [str(path) for path in assets], check=True)
    # Publish only after every asset is uploaded. Never replace /releases/latest or its appcast.
    subprocess.run(["gh", "release", "edit", tag, "--repo", value["repository"], "--draft=false", "--prerelease", "--latest=false"], check=True)
    url = "https://github.com/" + value["repository"] + "/releases/tag/" + tag
    print("Published unsigned prerelease: " + url)
    if environment.get("GITHUB_STEP_SUMMARY"):
        with Path(environment["GITHUB_STEP_SUMMARY"]).open("a") as summary:
            summary.write("Unsigned development prerelease: [" + tag + "](" + url + ")\n")


if __name__ == "__main__":
    publish()
