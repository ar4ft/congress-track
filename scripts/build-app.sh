#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
if [[ "$(uname -s)" != Darwin ]]; then
    echo "Build this native Mac app on macOS 14 or later with Xcode 15 or later."
    exit 1
fi
swift build -c release
BIN_DIR="$(swift build -c release --show-bin-path)"
APP="$PWD/dist/CongressTrack.app"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN_DIR/CongressTrack" "$APP/Contents/MacOS/"
# AppResources reads from the app's Resources directory in packaged builds.
for RESOURCE_BUNDLE in "$BIN_DIR"/*.bundle; do
    [[ -d "$RESOURCE_BUNDLE" ]] || continue
    cp -R "$RESOURCE_BUNDLE"/. "$APP/Contents/Resources/"
done
ICONSET="$(mktemp -d)/CongressTrack.iconset"
mkdir -p "$ICONSET"
for SIZE in 16 32 128 256 512; do
    sips -z "$SIZE" "$SIZE" Sources/CongressTrack/Resources/AppIcon.png --out "$ICONSET/icon_${SIZE}x${SIZE}.png" >/dev/null
    DOUBLE=$((SIZE * 2))
    sips -z "$DOUBLE" "$DOUBLE" Sources/CongressTrack/Resources/AppIcon.png --out "$ICONSET/icon_${SIZE}x${SIZE}@2x.png" >/dev/null
done
iconutil -c icns "$ICONSET" -o "$APP/Contents/Resources/AppIcon.icns"
rm -rf "$(dirname "$ICONSET")"
cat > "$APP/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleExecutable</key><string>CongressTrack</string>
<key>CFBundleIdentifier</key><string>app.congresstrack.mac</string>
<key>CFBundleName</key><string>CongressTrack</string>
<key>CFBundlePackageType</key><string>APPL</string>
<key>CFBundleShortVersionString</key><string>0.2.0</string>
<key>CFBundleVersion</key><string>2</string>
<key>CFBundleIconFile</key><string>AppIcon</string>
<key>LSMinimumSystemVersion</key><string>14.0</string>
<key>NSHighResolutionCapable</key><true/>
</dict></plist>
PLIST
if [[ -n "${CONGRESSTRACK_SIGNING_IDENTITY:-}" ]]; then
    codesign --force --options runtime --timestamp --sign "$CONGRESSTRACK_SIGNING_IDENTITY" "$APP"
else
    codesign --force --sign - "$APP"
fi
codesign --verify --deep --strict "$APP"
ditto -c -k --keepParent "$APP" "$PWD/dist/CongressTrack-macOS.zip"
if [[ -n "${CONGRESSTRACK_NOTARY_PROFILE:-}" ]]; then
    xcrun notarytool submit "$PWD/dist/CongressTrack-macOS.zip" --keychain-profile "$CONGRESSTRACK_NOTARY_PROFILE" --wait
    xcrun stapler staple "$APP"
    ditto -c -k --keepParent "$APP" "$PWD/dist/CongressTrack-macOS.zip"
fi
hdiutil create -volname CongressTrack -srcfolder "$APP" -ov -format UDZO "$PWD/dist/CongressTrack.dmg"
echo "Built $APP"
