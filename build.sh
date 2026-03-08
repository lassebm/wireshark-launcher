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

echo "==> Compiling WiresharkLauncher (universal binary)..."
swiftc \
	-o "$MACOS/WiresharkLauncher-arm64" \
	-framework Cocoa \
	-target arm64-apple-macos12.0 \
	"$SCRIPT_DIR/WiresharkLauncher/AppDelegate.swift"

swiftc \
	-o "$MACOS/WiresharkLauncher-x86_64" \
	-framework Cocoa \
	-target x86_64-apple-macos12.0 \
	"$SCRIPT_DIR/WiresharkLauncher/AppDelegate.swift"

lipo -create \
	"$MACOS/WiresharkLauncher-arm64" \
	"$MACOS/WiresharkLauncher-x86_64" \
	-output "$MACOS/WiresharkLauncher"

rm "$MACOS/WiresharkLauncher-arm64" "$MACOS/WiresharkLauncher-x86_64"

echo "==> Copying Info.plist..."
cp "$SCRIPT_DIR/WiresharkLauncher/Info.plist" "$CONTENTS/Info.plist"

echo "==> Build complete!"
echo "    App bundle: $APP_BUNDLE"
echo ""
echo "    To install, run:"
echo "      cp -r \"$APP_BUNDLE\" /Applications/"
echo ""
echo "    Or drag \"$APP_BUNDLE\" to /Applications in Finder."
echo ""
echo "    Since the app is not signed, remove the quarantine attribute before first launch:"
echo "      xattr -d com.apple.quarantine \"/Applications/Wireshark Launcher.app\""
