#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
WORK_DIR="$(mktemp -d)"
trap 'rm -rf "$WORK_DIR"' EXIT
swift scripts/create-test-update-key.swift "$WORK_DIR"
export CONGRESSTRACK_SPARKLE_KEY_FILE="$WORK_DIR/private-key"
export SPARKLE_PUBLIC_KEY="$(cat "$WORK_DIR/public-key")"
swift scripts/validate-update-key.swift
ditto dist/CongressTrack.app "$WORK_DIR/CongressTrack.app"
python3 - "$WORK_DIR/CongressTrack.app/Contents/Info.plist" <<'PY'
import os, plistlib, sys
from pathlib import Path
path = Path(sys.argv[1])
info = plistlib.loads(path.read_bytes())
info.update({'SUPublicEDKey': os.environ['SPARKLE_PUBLIC_KEY'],
             'SUFeedURL': 'https://github.com/ar4ft/congress-track/releases/latest/download/appcast.xml',
             'SURequireSignedFeed': True, 'SUVerifyUpdateBeforeExtraction': True})
path.write_bytes(plistlib.dumps(info))
PY
python3 scripts/sign-bundle.py "$WORK_DIR/CongressTrack.app"
mkdir -p "$WORK_DIR/updates"
ditto -c -k --keepParent "$WORK_DIR/CongressTrack.app" "$WORK_DIR/updates/CongressTrack-macOS.zip"
TOOLS="$(python3 - <<'PY'
from pathlib import Path
tools = list(Path('.build/artifacts').glob('**/bin/generate_appcast'))
assert len(tools) == 1
print(tools[0].parent.resolve())
PY
)"
TAG="$(python3 -c 'import json; print("v" + json.load(open("Release.json"))["version"])')"
PREFIX="https://github.com/ar4ft/congress-track/releases/download/$TAG/"
"$TOOLS/generate_appcast" --ed-key-file "$CONGRESSTRACK_SPARKLE_KEY_FILE" --maximum-deltas 0 --download-url-prefix "$PREFIX" "$WORK_DIR/updates"
SIGNATURE="$(python3 scripts/validate-appcast.py "$WORK_DIR/updates/appcast.xml" "$WORK_DIR/updates/CongressTrack-macOS.zip" "$PREFIX")"
"$TOOLS/sign_update" --ed-key-file "$CONGRESSTRACK_SPARKLE_KEY_FILE" --verify "$WORK_DIR/updates/appcast.xml"
"$TOOLS/sign_update" --ed-key-file "$CONGRESSTRACK_SPARKLE_KEY_FILE" --verify "$WORK_DIR/updates/CongressTrack-macOS.zip" "$SIGNATURE"
python3 - "$WORK_DIR/updates" <<'PY'
from pathlib import Path
import sys
folder = Path(sys.argv[1])
archive = bytearray((folder / 'CongressTrack-macOS.zip').read_bytes())
archive[len(archive) // 2] ^= 1
(folder / 'tampered.zip').write_bytes(archive)
feed = (folder / 'appcast.xml').read_bytes()
assert b'CongressTrack' in feed
(folder / 'tampered.xml').write_bytes(feed.replace(b'CongressTrack', b'CongressTampered', 1))
PY
if "$TOOLS/sign_update" --ed-key-file "$CONGRESSTRACK_SPARKLE_KEY_FILE" --verify "$WORK_DIR/updates/tampered.zip" "$SIGNATURE"; then
    echo "Tampered update archive was incorrectly accepted"
    exit 1
fi
if "$TOOLS/sign_update" --ed-key-file "$CONGRESSTRACK_SPARKLE_KEY_FILE" --verify "$WORK_DIR/updates/tampered.xml"; then
    echo "Tampered feed was incorrectly accepted"
    exit 1
fi
echo "Signed update archive/feed verified; altered archive/feed rejected."
