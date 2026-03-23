#!/bin/bash
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BUILD_DIR="$SCRIPT_DIR/build"
APP_BUNDLE="$BUILD_DIR/Wireshark Launcher.app"
CONTENTS="$APP_BUNDLE/Contents"
MACOS="$CONTENTS/MacOS"
RESOURCES="$CONTENTS/Resources"
BINARY="$MACOS/WiresharkLauncher"
PLIST="$CONTENTS/Info.plist"
SRC_PLIST="$SCRIPT_DIR/WiresharkLauncher/Info.plist"

pass=0
fail=0

assert() {
	local desc="$1"
	shift
	if "$@" >/dev/null 2>&1; then
		printf "  \033[32mPASS\033[0m  %s\n" "$desc"
		((pass++))
	else
		printf "  \033[31mFAIL\033[0m  %s\n" "$desc"
		((fail++))
	fi
}

plist_val() {
	/usr/libexec/PlistBuddy -c "Print :$1" "$PLIST" 2>/dev/null
}

assert_plist() {
	local key="$1" expected="$2"
	local actual
	actual=$(plist_val "$key")
	assert "Info.plist $key == $expected" test "$actual" = "$expected"
}

# Phase 1: Build
echo "==> Building..."
if ! "$SCRIPT_DIR/build.sh" >/dev/null 2>&1; then
	echo "  FAIL  build.sh exited with error"
	exit 1
fi
echo "  Build succeeded."
echo ""

# Phase 2: Bundle structure
echo "==> Bundle structure"
assert "App bundle exists" test -d "$APP_BUNDLE"
assert "Contents/ exists" test -d "$CONTENTS"
assert "Contents/MacOS/ exists" test -d "$MACOS"
assert "Contents/Resources/ exists" test -d "$RESOURCES"
assert "Info.plist exists" test -f "$PLIST"
assert "Binary exists" test -f "$BINARY"
assert "Binary is executable" test -x "$BINARY"
assert "No leftover arm64 binary" test ! -f "$MACOS/WiresharkLauncher-arm64"
assert "No leftover x86_64 binary" test ! -f "$MACOS/WiresharkLauncher-x86_64"
echo ""

# Phase 3: Binary
echo "==> Binary"
assert "Universal binary (arm64)" lipo "$BINARY" -verify_arch arm64
assert "Universal binary (x86_64)" lipo "$BINARY" -verify_arch x86_64
assert "Mach-O executable" bash -c 'file "$1" | grep -q "Mach-O universal binary"' -- "$BINARY"
echo ""

# Phase 4: Info.plist
echo "==> Info.plist"
assert "Plist is valid" plutil -lint "$PLIST"
assert_plist "CFBundleExecutable" "WiresharkLauncher"
assert_plist "CFBundleIdentifier" "com.local.WiresharkLauncher"
assert_plist "CFBundleName" "Wireshark Launcher"
assert_plist "CFBundlePackageType" "APPL"
assert_plist "CFBundleIconFile" "AppIcon"
assert_plist "LSMinimumSystemVersion" "15.0"

assert "LSUIElement is false" test "$(plist_val LSUIElement)" = "false"
assert "NSHighResolutionCapable is true" test "$(plist_val NSHighResolutionCapable)" = "true"

assert "Document types registered" plist_val "CFBundleDocumentTypes:0"

# Verify all document types have LSHandlerRank = Alternate
doc_type_count=$(/usr/libexec/PlistBuddy -c "Print :CFBundleDocumentTypes" "$PLIST" 2>/dev/null | grep -c "Dict")
all_alternate=true
for ((i = 0; i < doc_type_count; i++)); do
	rank=$(/usr/libexec/PlistBuddy -c "Print :CFBundleDocumentTypes:$i:LSHandlerRank" "$PLIST" 2>/dev/null)
	if [ "$rank" != "Alternate" ]; then
		all_alternate=false
		break
	fi
done
assert "All document types have LSHandlerRank=Alternate" $all_alternate

# Verify pcap and pcapng extensions are registered
plist_text=$(/usr/libexec/PlistBuddy -c "Print :CFBundleDocumentTypes" "$PLIST" 2>/dev/null)
assert "pcap extension registered" bash -c 'echo "$1" | grep -q "pcap"' -- "$plist_text"
assert "pcapng extension registered" bash -c 'echo "$1" | grep -q "pcapng"' -- "$plist_text"

# Cross-check: CFBundleExecutable matches actual binary
exe_name=$(plist_val "CFBundleExecutable")
assert "CFBundleExecutable matches binary" test -f "$MACOS/$exe_name"
echo ""

# Phase 5: Icon
echo "==> Icon"
assert "AppIcon.icns exists" test -f "$RESOURCES/AppIcon.icns"
icns_size=$(stat -f%z "$RESOURCES/AppIcon.icns" 2>/dev/null || echo 0)
assert "AppIcon.icns is non-trivial (>1KB)" test "$icns_size" -gt 1000
assert "No leftover iconset directory" test ! -d "$BUILD_DIR/AppIcon.iconset"
echo ""

# Phase 6: Source checks
echo "==> Source checks"
assert "AppDelegate references /Applications/Wireshark.app" \
	grep -q '/Applications/Wireshark.app' "$SCRIPT_DIR/WiresharkLauncher/AppDelegate.swift"
assert "AppDelegate uses open -n (new instance)" \
	grep -q '"-n"' "$SCRIPT_DIR/WiresharkLauncher/AppDelegate.swift"
assert "AppDelegate calls NSApp.terminate" \
	grep -q 'NSApp.terminate' "$SCRIPT_DIR/WiresharkLauncher/AppDelegate.swift"

# Cross-check: build target matches LSMinimumSystemVersion
min_ver=$(/usr/libexec/PlistBuddy -c "Print :LSMinimumSystemVersion" "$SRC_PLIST" 2>/dev/null)
assert "Build target matches LSMinimumSystemVersion ($min_ver)" \
	grep -q "macos${min_ver}" "$SCRIPT_DIR/build.sh"
echo ""

# Summary
echo "==> Results: $pass passed, $fail failed"
exit $((fail > 0 ? 1 : 0))
