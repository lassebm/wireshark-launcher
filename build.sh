#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BUILD_DIR="$SCRIPT_DIR/build"
APP_BUNDLE="$BUILD_DIR/Wireshark Launcher.app"
CONTENTS="$APP_BUNDLE/Contents"
MACOS="$CONTENTS/MacOS"
RESOURCES="$CONTENTS/Resources"

echo "==> Cleaning build directory..."
rm -rf "$BUILD_DIR"
mkdir -p "$MACOS" "$RESOURCES"

echo "==> Generating flipped Wireshark icon..."
swift "$SCRIPT_DIR/generate-icon.swift" "$BUILD_DIR"

if [ -f "$BUILD_DIR/AppIcon.icns" ]; then
	cp "$BUILD_DIR/AppIcon.icns" "$RESOURCES/AppIcon.icns"
	echo "    Icon generated successfully."
else
	echo "    WARNING: Icon generation failed, continuing without custom icon."
fi

echo "==> Compiling WiresharkLauncher..."
swiftc \
	-o "$MACOS/WiresharkLauncher" \
	-framework Cocoa \
	-target arm64-apple-macos12.0 \
	"$SCRIPT_DIR/WiresharkLauncher/AppDelegate.swift"

echo "==> Copying Info.plist..."
cp "$SCRIPT_DIR/WiresharkLauncher/Info.plist" "$CONTENTS/Info.plist"

echo "==> Build complete!"
echo "    App bundle: $APP_BUNDLE"
echo ""
echo "    To install, run:"
echo "      cp -r \"$APP_BUNDLE\" /Applications/"
echo ""
echo "    Or drag \"$APP_BUNDLE\" to /Applications in Finder."
