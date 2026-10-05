#!/usr/bin/env bash
set -euo pipefail

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "==> Packaging Solitaire Glass macOS Application..."

cd "$PROJECT_ROOT"

# Ensure Xcode project is up to date
if command -v xcodegen >/dev/null 2>&1; then
    echo "==> Regenerating Xcode project with xcodegen..."
    xcodegen generate
fi

# Clean output directory
DIST_DIR="$PROJECT_ROOT/dist"
rm -rf "$DIST_DIR"
mkdir -p "$DIST_DIR"

# Build Release configuration
echo "==> Building Release target..."
BUILD_DIR="$PROJECT_ROOT/build"
rm -rf "$BUILD_DIR"

xcodebuild -project SolitaireGlass.xcodeproj \
    -scheme SolitaireGlass \
    -configuration Release \
    -derivedDataPath "$BUILD_DIR" \
    build

# Locate built app
APP_PATH=$(find "$BUILD_DIR" -name "SolitaireGlass.app" -type d | head -n 1)

if [ -z "$APP_PATH" ] || [ ! -d "$APP_PATH" ]; then
    echo "Error: Could not locate built SolitaireGlass.app" >&2
    exit 1
fi

# Copy app to dist directory
echo "==> Copying application to $DIST_DIR/Solitaire Glass.app..."
cp -R "$APP_PATH" "$DIST_DIR/Solitaire Glass.app"

# Create a DMG installer for easy distribution
DMG_PATH="$DIST_DIR/SolitaireGlass-Installer.dmg"
echo "==> Creating macOS DMG installer at $DMG_PATH..."

TMP_DMG_DIR=$(mktemp -d /tmp/solitaire-dmg.XXXXXX)
cp -R "$DIST_DIR/Solitaire Glass.app" "$TMP_DMG_DIR/"
ln -s /Applications "$TMP_DMG_DIR/Applications"

hdiutil create -volname "Solitaire Glass" \
    -srcfolder "$TMP_DMG_DIR" \
    -ov -format UDZO \
    "$DMG_PATH"

rm -rf "$TMP_DMG_DIR"

echo "==> Package build complete!"
echo "    App Bundle: $DIST_DIR/Solitaire Glass.app"
echo "    DMG Installer: $DMG_PATH"
