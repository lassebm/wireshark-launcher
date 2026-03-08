#!/bin/bash
set -euo pipefail

APP_NAME="Wireshark Launcher.app"
DEST="/Applications/$APP_NAME"

# Determine source: built app or same directory as this script
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
if [ -d "$SCRIPT_DIR/build/$APP_NAME" ]; then
	SRC="$SCRIPT_DIR/build/$APP_NAME"
elif [ -d "$SCRIPT_DIR/$APP_NAME" ]; then
	SRC="$SCRIPT_DIR/$APP_NAME"
else
	echo "Error: Could not find $APP_NAME"
	echo "  Looked in: $SCRIPT_DIR/build/ and $SCRIPT_DIR/"
	exit 1
fi

echo "==> Installing $APP_NAME..."

if [ -d "$DEST" ]; then
	echo "    Removing existing installation..."
	rm -rf "$DEST"
fi

cp -r "$SRC" "$DEST"

echo "    Removing quarantine attribute..."
xattr -d com.apple.quarantine "$DEST" 2>/dev/null || true

echo "==> Installed to $DEST"
