#!/bin/zsh

set -euo pipefail

ROOT_DIR="${0:A:h}"
OUTPUT_DIR="$ROOT_DIR/outputs"
APP_DIR="$OUTPUT_DIR/ClipMini.app"
BUILD_DIR="$ROOT_DIR/.build"
ASSET_CATALOG_DIR="$BUILD_DIR/Assets.xcassets"
ICONSET_DIR="$ASSET_CATALOG_DIR/AppIcon.appiconset"
MODULE_CACHE_DIR="$BUILD_DIR/module-cache"
SWIFTPM_CACHE_DIR="$BUILD_DIR/swiftpm-cache"
SWIFTPM_CONFIG_DIR="$BUILD_DIR/swiftpm-config"
SWIFTPM_SECURITY_DIR="$BUILD_DIR/swiftpm-security"

cd "$ROOT_DIR"
mkdir -p "$MODULE_CACHE_DIR" "$SWIFTPM_CACHE_DIR" "$SWIFTPM_CONFIG_DIR" "$SWIFTPM_SECURITY_DIR"
CLANG_MODULE_CACHE_PATH="$MODULE_CACHE_DIR" \
SWIFTPM_MODULECACHE_OVERRIDE="$MODULE_CACHE_DIR" \
swift build \
    -c release \
    --disable-sandbox \
    --cache-path "$SWIFTPM_CACHE_DIR" \
    --config-path "$SWIFTPM_CONFIG_DIR" \
    --security-path "$SWIFTPM_SECURITY_DIR" \
    --scratch-path "$BUILD_DIR"

mkdir -p "$APP_DIR/Contents/MacOS"
mkdir -p "$APP_DIR/Contents/Resources"
for REMOVED_AVATAR_ID in hanli nangongwan ziling yinyue nidalee missfortune singed masteryi; do
    rm -f "$APP_DIR/Contents/Resources/avatar-$REMOVED_AVATAR_ID.png"
done
cp ".build/release/ClipMini" "$APP_DIR/Contents/MacOS/ClipMini"
cp "Info.plist" "$APP_DIR/Contents/Info.plist"
cp -R ".build/release/ClipMini_ClipMini.bundle" "$APP_DIR/Contents/Resources/"
for REMOVED_AVATAR_ID in hanli nangongwan ziling yinyue nidalee missfortune singed masteryi; do
    rm -f "$APP_DIR/Contents/Resources/ClipMini_ClipMini.bundle/Resources/avatar-$REMOVED_AVATAR_ID.png"
done
cp Sources/ClipMini/Resources/lunar.js "$APP_DIR/Contents/Resources/"
cp Sources/ClipMini/Resources/lunar-LICENSE.txt "$APP_DIR/Contents/Resources/"
cp Sources/ClipMini/Resources/iztro-2.6.0.min.js "$APP_DIR/Contents/Resources/"
cp Sources/ClipMini/Resources/iztro-LICENSE.txt "$APP_DIR/Contents/Resources/"
for AVATAR_ID in buu goku vegeta piccolo ahri jinx yasuo teemo; do
    cp "Sources/ClipMini/Resources/avatar-$AVATAR_ID.png" "$APP_DIR/Contents/Resources/"
done
cp Sources/ClipMini/Resources/Menu-Goku.png "$APP_DIR/Contents/Resources/"

rm -rf "$ASSET_CATALOG_DIR"
cp -R Resources/Assets.xcassets "$ASSET_CATALOG_DIR"
sips -z 16 16 Resources/AppIcon-Source.png --out "$ICONSET_DIR/icon_16x16.png" >/dev/null
sips -z 32 32 Resources/AppIcon-Source.png --out "$ICONSET_DIR/icon_16x16@2x.png" >/dev/null
sips -z 32 32 Resources/AppIcon-Source.png --out "$ICONSET_DIR/icon_32x32.png" >/dev/null
sips -z 64 64 Resources/AppIcon-Source.png --out "$ICONSET_DIR/icon_32x32@2x.png" >/dev/null
sips -z 128 128 Resources/AppIcon-Source.png --out "$ICONSET_DIR/icon_128x128.png" >/dev/null
sips -z 256 256 Resources/AppIcon-Source.png --out "$ICONSET_DIR/icon_128x128@2x.png" >/dev/null
sips -z 256 256 Resources/AppIcon-Source.png --out "$ICONSET_DIR/icon_256x256.png" >/dev/null
sips -z 512 512 Resources/AppIcon-Source.png --out "$ICONSET_DIR/icon_256x256@2x.png" >/dev/null
sips -z 512 512 Resources/AppIcon-Source.png --out "$ICONSET_DIR/icon_512x512.png" >/dev/null
sips -z 1024 1024 Resources/AppIcon-Source.png --out "$ICONSET_DIR/icon_512x512@2x.png" >/dev/null
xcrun actool "$ASSET_CATALOG_DIR" \
    --compile "$APP_DIR/Contents/Resources" \
    --platform macosx \
    --minimum-deployment-target 13.0 \
    --app-icon AppIcon \
    --output-partial-info-plist "$BUILD_DIR/asset-info.plist" \
    >/dev/null
codesign \
    --force \
    --sign - \
    --requirements '=designated => identifier "local.clipmini.app"' \
    "$APP_DIR"

echo "$APP_DIR"
