#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
: "${RELEASE_TAG:?Release tag is required}"
: "${CONGRESSTRACK_SPARKLE_KEY_FILE:?Sparkle private key file is required}"
swift scripts/validate-update-key.swift
TOOLS="$(python3 - <<'PY'
from pathlib import Path
tools = list(Path('.build/artifacts').glob('**/bin/generate_appcast'))
if len(tools) != 1:
    raise SystemExit('Expected one pinned Sparkle appcast generator')
print(tools[0].parent.resolve())
PY
)"
UPDATES_DIR="$PWD/dist/updates"
mkdir -p "$UPDATES_DIR"
cp "$PWD/dist/CongressTrack-macOS.zip" "$UPDATES_DIR/"
PREFIX="https://github.com/ar4ft/congress-track/releases/download/$RELEASE_TAG/"
"$TOOLS/generate_appcast" --ed-key-file "$CONGRESSTRACK_SPARKLE_KEY_FILE" --maximum-deltas 0 --download-url-prefix "$PREFIX" "$UPDATES_DIR"
SIGNATURE="$(python3 scripts/validate-appcast.py "$UPDATES_DIR/appcast.xml" "$UPDATES_DIR/CongressTrack-macOS.zip" "$PREFIX")"
"$TOOLS/sign_update" --ed-key-file "$CONGRESSTRACK_SPARKLE_KEY_FILE" --verify "$UPDATES_DIR/CongressTrack-macOS.zip" "$SIGNATURE"
"$TOOLS/sign_update" --ed-key-file "$CONGRESSTRACK_SPARKLE_KEY_FILE" --verify "$UPDATES_DIR/appcast.xml"
cp "$UPDATES_DIR/appcast.xml" "$PWD/dist/appcast.xml"
cp Release.json "$PWD/dist/release-metadata.json"
(cd dist && shasum -a 256 CongressTrack-macOS.zip CongressTrack.dmg appcast.xml release-metadata.json > SHA256SUMS)
echo "Signed archive and signed feed verified."
