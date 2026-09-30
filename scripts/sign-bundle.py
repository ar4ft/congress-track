"""Sign nested Sparkle code from the inside out; no --deep signing."""
import os
from pathlib import Path
import subprocess
import sys

MACHO = {b"\xfe\xed\xfa\xce", b"\xce\xfa\xed\xfe", b"\xfe\xed\xfa\xcf", b"\xcf\xfa\xed\xfe", b"\xca\xfe\xba\xbe", b"\xbe\xba\xfe\xca"}


def is_code(path):
    if path.is_symlink():
        return False
    if path.is_dir():
        return path.suffix in (".app", ".xpc", ".framework")
    with path.open("rb") as file:
        return file.read(4) in MACHO


if __name__ == "__main__":
    app = Path(sys.argv[1]).resolve()
    identity = os.environ.get("CONGRESSTRACK_SIGNING_IDENTITY", "-")
    production = os.environ.get("CONGRESSTRACK_RELEASE") == "1"
    if not production:
        sys.exit("Code signing is permitted only for an explicitly enabled signed release")
    if os.environ.get("GITHUB_ACTIONS") == "true" and os.environ.get("GITHUB_EVENT_NAME") != "workflow_dispatch":
        sys.exit("Code signing is allowed only for a manually started action")
    if not identity.startswith("Developer ID Application:"):
        sys.exit("Production releases require a Developer ID Application identity")
    code = [path for path in app.rglob("*") if is_code(path)]
    code.sort(key=lambda path: len(path.parts), reverse=True)
    for path in code + [app]:
        command = ["codesign", "--force", "--sign", identity, "--preserve-metadata=entitlements"]
        if identity != "-":
            command += ["--options", "runtime", "--timestamp"]
        subprocess.run(command + [str(path)], check=True)
    subprocess.run(["codesign", "--verify", "--deep", "--strict", str(app)], check=True)
    if production:
        result = subprocess.run(["codesign", "-d", "--verbose=4", str(app)], capture_output=True, text=True, check=True)
        if "TeamIdentifier=" + os.environ["APPLE_TEAM_ID"] not in result.stderr:
            sys.exit("Signed application's Team ID does not match APPLE_TEAM_ID")
