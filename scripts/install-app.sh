#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "==> Packaging Release build of Solitaire Glass..."
"$SCRIPT_DIR/package-app.sh"

APP_SOURCE="$PROJECT_ROOT/dist/Solitaire Glass.app"

if [ ! -d "$APP_SOURCE" ]; then
    echo "Error: $APP_SOURCE was not found." >&2
    exit 1
fi

DEST_DIR="/Applications"
if [ ! -w "$DEST_DIR" ]; then
    DEST_DIR="$HOME/Applications"
    mkdir -p "$DEST_DIR"
fi

TARGET_APP="$DEST_DIR/Solitaire Glass.app"
echo "==> Installing Solitaire Glass to $TARGET_APP..."

rm -rf "$TARGET_APP"
cp -R "$APP_SOURCE" "$TARGET_APP"

# Clear macOS quarantine flag for local build
xattr -cr "$TARGET_APP" 2>/dev/null || true

# Register with macOS LaunchServices so Spotlight, Launchpad, and Dock recognize it
echo "==> Registering with LaunchServices..."
/System/Library/Frameworks/CoreServices.framework/Versions/Current/Frameworks/LaunchServices.framework/Versions/Current/Support/lsregister -f -R -trusted "$TARGET_APP" 2>/dev/null || true

echo ""
echo "🎉 Successfully installed Solitaire Glass to $TARGET_APP!"
echo "    You can launch it anytime from Launchpad, Spotlight ('Solitaire Glass'), or by running:"
echo "    open -a \"Solitaire Glass\""
echo ""

# Launch the app
echo "==> Launching installed application..."
open -a "$TARGET_APP"
