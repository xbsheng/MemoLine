#!/bin/bash
# Builds MemoLine.app into ./build without needing Xcode.
# Usage: scripts/build-app.sh [debug|release]
set -euo pipefail
cd "$(dirname "$0")/.."

CONFIG="${1:-release}"
APP="build/MemoLine.app"
# The release workflow passes the tag, so the bundle carries the version it
# was published as: v1.2.3 tags become a 1.2.3 bundle version.
VERSION="${MEMOLINE_VERSION:-1.0.0}"
VERSION="${VERSION#v}"

# A universal binary, so it runs on Apple silicon and on Intel Macs, from
# macOS 13 Ventura onwards.
OUT="$(mktemp -d)"
for arch in arm64 x86_64; do
  swift build -c "$CONFIG" --triple "$arch-apple-macosx13.0" >&2
  cp "$(swift build -c "$CONFIG" --triple "$arch-apple-macosx13.0" --show-bin-path)/MemoLine" "$OUT/MemoLine-$arch"
done
lipo -create "$OUT/MemoLine-arm64" "$OUT/MemoLine-x86_64" -output "$OUT/MemoLine"

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$OUT/MemoLine" "$APP/Contents/MacOS/MemoLine"

# Icon
WORK="$(mktemp -d)"
swift scripts/make-icon.swift "$WORK/icon.png" >&2
ICONSET="$WORK/MemoLine.iconset"
mkdir -p "$ICONSET"
for s in 16 32 128 256 512; do
  sips -z $s $s "$WORK/icon.png" --out "$ICONSET/icon_${s}x${s}.png" >/dev/null
  sips -z $((s*2)) $((s*2)) "$WORK/icon.png" --out "$ICONSET/icon_${s}x${s}@2x.png" >/dev/null
done
iconutil -c icns "$ICONSET" -o "$APP/Contents/Resources/MemoLine.icns"
rm -rf "$WORK"

# Translations: one folder per language, listed in Info.plist so macOS knows
# which languages the app speaks.
LANGUAGES=""
for dir in Sources/MemoLine/Resources/*.lproj; do
  cp -R "$dir" "$APP/Contents/Resources/"
  LANGUAGES="$LANGUAGES<string>$(basename "$dir" .lproj)</string>"
done

cat > "$APP/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleName</key><string>MemoLine</string>
  <key>CFBundleDisplayName</key><string>MemoLine</string>
  <key>CFBundleIdentifier</key><string>app.memoline.MemoLine</string>
  <key>CFBundleExecutable</key><string>MemoLine</string>
  <key>CFBundleIconFile</key><string>MemoLine</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleShortVersionString</key><string>${VERSION}</string>
  <key>CFBundleVersion</key><string>1</string>
  <key>CFBundleDevelopmentRegion</key><string>en</string>
  <key>NSHumanReadableCopyright</key><string>MIT licensed. The rope and the reveal gesture come from Tendedero by Alejandro Buján.</string>
  <key>CFBundleLocalizations</key><array>${LANGUAGES}</array>
  <key>LSMinimumSystemVersion</key><string>13.0</string>
  <key>LSApplicationCategoryType</key><string>public.app-category.productivity</string>
  <key>LSUIElement</key><true/>
  <key>NSHighResolutionCapable</key><true/>
</dict>
</plist>
PLIST

# Sign with a Developer ID when one is in the keychain (or SIGN_IDENTITY is
# set). Without one, sign ad hoc so the app still runs locally.
IDENTITY="${SIGN_IDENTITY:-$(security find-identity -v -p codesigning 2>/dev/null | awk -F'"' '/Developer ID Application/{print $2; exit}')}"
if [ -n "$IDENTITY" ]; then
  codesign --force --options runtime --timestamp --sign "$IDENTITY" "$APP"
  echo "Signed with $IDENTITY"
else
  codesign --force --deep --sign - "$APP" >/dev/null
  echo "Signed ad hoc (no Developer ID found)"
fi
echo "Built $APP ($VERSION)"
