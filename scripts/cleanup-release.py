import json
import os
from pathlib import Path
import shutil
import subprocess

folder = Path(os.environ["RUNNER_TEMP"]) / "CongressTrack-release"
saved = folder / "prior-keychains.json"
if saved.exists():
    subprocess.run(["security", "list-keychains", "-d", "user", "-s"] + json.loads(saved.read_text()), check=True)
keychain = folder / "release.keychain-db"
if keychain.exists():
    subprocess.run(["security", "delete-keychain", str(keychain)], check=True)
shutil.rmtree(folder, ignore_errors=True)
print("Temporary release credentials removed.")
