# Wireshark Launcher

macOS app that launches a new instance of Wireshark. Clicking the Dock icon opens a fresh Wireshark instance via `open -n`. Dropping a pcap/pcapng file on the Dock icon launches a new Wireshark instance opening that file. The app self-terminates after launching.

## Project Structure

- `WiresharkLauncher/AppDelegate.swift` - Main app logic (NSApplicationDelegate). Handles launch and file-open events, invokes `open -n -a /Applications/Wireshark.app`.
- `WiresharkLauncher/Info.plist` - App bundle metadata. Registers pcap/pcapng/capture file document types with `LSHandlerRank: Alternate`. `LSUIElement` is false (visible in Dock).
- `generate-icon.swift` - Swift script that reads Wireshark's icon, flips it horizontally, and outputs an `.icns` file. Uses CoreGraphics transforms and `iconutil`.
- `build.sh` - Build script. Compiles Swift source with `swiftc`, runs icon generation (falls back to `resources/AppIcon.icns` if Wireshark unavailable), assembles the `.app` bundle under `build/`.
- `install.sh` - Install script. Copies the `.app` bundle to `/Applications` and removes the quarantine attribute.
- `test.sh` - Test script. Builds the app then validates bundle structure, universal binary, Info.plist, icon, and source invariants.
- `resources/AppIcon.icns` - Pre-generated app icon for CI builds where Wireshark is not installed.
- `.github/workflows/build.yml` - GitHub Actions workflow. Builds, tests, and creates a release on every push to `main`.

## Build

```sh
./build.sh
```

Produces `build/Wireshark Launcher.app`. Wireshark at `/Applications/Wireshark.app` is used to generate the icon; if unavailable, falls back to `resources/AppIcon.icns`.

## Install

```sh
./install.sh
```

## Tech Notes

- Swift 6, compiled with `swiftc` (no Xcode project)
- Universal binary (arm64 + x86_64), targeting macOS 12.0+
- Icon generation uses `NSImage`, `NSBitmapImageRep`, `CGContext`, and `iconutil`
- The app icon is the Wireshark icon flipped horizontally to distinguish it visually
