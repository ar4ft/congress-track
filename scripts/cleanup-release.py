import json
import os
from pathlib import Path
import shutil
import subprocess
import sys

folder = Path(os.environ["RUNNER_TEMP"]) / "CongressTrack-release"
saved = folder / "prior-keychains.json"
failed = False
try:
    if saved.exists():
        result = subprocess.run(["security", "list-keychains", "-d", "user", "-s"] + json.loads(saved.read_text()), capture_output=True)
        failed |= result.returncode != 0
    keychain = folder / "release.keychain-db"
    if keychain.exists():
        result = subprocess.run(["security", "delete-keychain", str(keychain)], capture_output=True)
        failed |= result.returncode != 0
finally:
    shutil.rmtree(folder, ignore_errors=True)
if failed:
    sys.exit("Temporary credential files removed, but keychain cleanup reported a failure")
print("Temporary release credentials removed.")
