#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
if [[ "$(uname -s)" != Darwin ]]; then
    echo "Build this native Mac app on macOS 14 or later with Xcode 15 or later."
    exit 1
fi
python3 scripts/release_config.py
if [[ "${CONGRESSTRACK_RELEASE:-0}" == 1 ]]; then
    : "${CONGRESSTRACK_SIGNING_IDENTITY:?Production signing identity is required}"
    : "${CONGRESSTRACK_NOTARY_PROFILE:?Production notarization profile is required}"
fi
ARCHITECTURES=("$(uname -m)")
if [[ "${CONGRESSTRACK_UNIVERSAL:-0}" == 1 || "${CONGRESSTRACK_RELEASE:-0}" == 1 ]]; then
    ARCHITECTURES=(arm64 x86_64)
fi
BIN_DIRS=()
for ARCH in "${ARCHITECTURES[@]}"; do
    swift build -c release --arch "$ARCH" -Xswiftc -g
    BIN_DIRS+=("$(swift build -c release --arch "$ARCH" --show-bin-path)")
done
APP="$PWD/dist/CongressTrack.app"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources" "$APP/Contents/Frameworks"
if [[ ${#BIN_DIRS[@]} == 2 ]]; then
    lipo -create "${BIN_DIRS[0]}/CongressTrack" "${BIN_DIRS[1]}/CongressTrack" -output "$APP/Contents/MacOS/CongressTrack"
else
    cp "${BIN_DIRS[0]}/CongressTrack" "$APP/Contents/MacOS/"
fi
for RESOURCE_BUNDLE in "${BIN_DIRS[0]}"/*.bundle; do
    [[ -d "$RESOURCE_BUNDLE" ]] || continue
    cp -R "$RESOURCE_BUNDLE"/. "$APP/Contents/Resources/"
done
SPARKLE_FRAMEWORK="$(python3 - <<'PY'
from pathlib import Path
frameworks = list(Path('.build/artifacts').glob('**/Sparkle.xcframework/macos-arm64_x86_64/Sparkle.framework'))
if len(frameworks) != 1:
    raise SystemExit('Expected one pinned Sparkle macOS framework')
print(frameworks[0])
PY
)"
ditto "$SPARKLE_FRAMEWORK" "$APP/Contents/Frameworks/Sparkle.framework"
SPARKLE_ROOT="$(dirname "$(dirname "$SPARKLE_FRAMEWORK")")"
# xcframework -> package root.
cp "$(dirname "$SPARKLE_ROOT")/LICENSE" "$APP/Contents/Resources/Sparkle-LICENSE"
python3 - "$APP/Contents/MacOS/CongressTrack" <<'PY'
import subprocess, sys, re
binary = sys.argv[1]
load_commands = subprocess.check_output(['otool', '-l', binary], text=True)
paths = re.findall(r'cmd LC_RPATH\s+cmdsize \d+\s+path (.+?) \(offset', load_commands)
for path in set(paths):
    if path.startswith('/'):
        subprocess.run(['install_name_tool', '-delete_rpath', path, binary], check=True)
PY
WORK_DIR="$(mktemp -d)"
trap 'rm -rf "$WORK_DIR"' EXIT
ICONSET="$WORK_DIR/CongressTrack.iconset"
mkdir -p "$ICONSET"
for SIZE in 16 32 128 256 512; do
    sips -z "$SIZE" "$SIZE" Sources/CongressTrack/Resources/AppIcon.png --out "$ICONSET/icon_${SIZE}x${SIZE}.png" >/dev/null
    DOUBLE=$((SIZE * 2))
    sips -z "$DOUBLE" "$DOUBLE" Sources/CongressTrack/Resources/AppIcon.png --out "$ICONSET/icon_${SIZE}x${SIZE}@2x.png" >/dev/null
done
iconutil -c icns "$ICONSET" -o "$APP/Contents/Resources/AppIcon.icns"
python3 scripts/release_config.py --plist "$APP/Contents/Info.plist"
python3 scripts/sign-bundle.py "$APP"
dsymutil "$APP/Contents/MacOS/CongressTrack" -o "$PWD/dist/CongressTrack.app.dSYM"
ditto -c -k --keepParent "$PWD/dist/CongressTrack.app.dSYM" "$PWD/dist/CongressTrack-symbols.zip"
NOTARY_OPTIONS=()
if [[ -n "${CONGRESSTRACK_NOTARY_KEYCHAIN:-}" ]]; then
    NOTARY_OPTIONS=(--keychain "$CONGRESSTRACK_NOTARY_KEYCHAIN")
fi
if [[ -n "${CONGRESSTRACK_NOTARY_PROFILE:-}" ]]; then
    ditto -c -k --keepParent "$APP" "$WORK_DIR/notarization.zip"
    xcrun notarytool submit "$WORK_DIR/notarization.zip" --keychain-profile "$CONGRESSTRACK_NOTARY_PROFILE" "${NOTARY_OPTIONS[@]}" --wait --output-format json > "$PWD/dist/notarization-app.json"
    python3 -c 'import json; assert json.load(open("dist/notarization-app.json"))["status"] == "Accepted", "Application notarization was not accepted"'
    xcrun stapler staple "$APP"
    xcrun stapler validate "$APP"
    spctl --assess --type execute --verbose "$APP"
fi
# This is the final update archive. Do not change it after generating the appcast.
ditto -c -k --keepParent "$APP" "$PWD/dist/CongressTrack-macOS.zip"
mkdir -p "$WORK_DIR/installer"
ditto "$APP" "$WORK_DIR/installer/CongressTrack.app"
ln -s /Applications "$WORK_DIR/installer/Applications"
hdiutil create -volname CongressTrack -srcfolder "$WORK_DIR/installer" -ov -format UDZO "$PWD/dist/CongressTrack.dmg"
if [[ -n "${CONGRESSTRACK_SIGNING_IDENTITY:-}" && "$CONGRESSTRACK_SIGNING_IDENTITY" != - ]]; then
    codesign --force --timestamp --sign "$CONGRESSTRACK_SIGNING_IDENTITY" "$PWD/dist/CongressTrack.dmg"
    codesign --verify --strict "$PWD/dist/CongressTrack.dmg"
fi
if [[ -n "${CONGRESSTRACK_NOTARY_PROFILE:-}" ]]; then
    xcrun notarytool submit "$PWD/dist/CongressTrack.dmg" --keychain-profile "$CONGRESSTRACK_NOTARY_PROFILE" "${NOTARY_OPTIONS[@]}" --wait --output-format json > "$PWD/dist/notarization-dmg.json"
    python3 -c 'import json; assert json.load(open("dist/notarization-dmg.json"))["status"] == "Accepted", "DMG notarization was not accepted"'
    xcrun stapler staple "$PWD/dist/CongressTrack.dmg"
    xcrun stapler validate "$PWD/dist/CongressTrack.dmg"
    spctl --assess --type open --context context:primary-signature --verbose "$PWD/dist/CongressTrack.dmg"
fi
echo "Built $APP"
