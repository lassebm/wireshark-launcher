# Wireshark Launcher

macOS app that launches a new instance of Wireshark. Clicking the Dock icon opens a fresh Wireshark instance via `open -n`. Dropping a pcap/pcapng file on the Dock icon launches a new Wireshark instance opening that file. The app self-terminates after launching.

## Project Structure

- `WiresharkLauncher/AppDelegate.swift` - Main app logic (NSApplicationDelegate). Handles launch and file-open events, invokes `open -n -a /Applications/Wireshark.app`.
- `WiresharkLauncher/Info.plist` - App bundle metadata. Registers pcap/pcapng/capture file document types with `LSHandlerRank: Alternate`. `LSUIElement` is false (visible in Dock).
- `generate-icon.swift` - Swift script that reads Wireshark's icon, flips it horizontally, and outputs an `.icns` file. Uses CoreGraphics transforms and `iconutil`.
- `build.sh` - Build script. Compiles Swift source with `swiftc`, runs icon generation, assembles the `.app` bundle under `build/`.

## Build

```sh
./build.sh
```

Produces `build/Wireshark Launcher.app`. Requires Wireshark installed at `/Applications/Wireshark.app`.

## Install

```sh
cp -r "build/Wireshark Launcher.app" /Applications/
```

## Tech Notes

- Swift 6, compiled with `swiftc` (no Xcode project)
- Universal binary (arm64 + x86_64), targeting macOS 12.0+
- Icon generation uses `NSImage`, `NSBitmapImageRep`, `CGContext`, and `iconutil`
- The app icon is the Wireshark icon flipped horizontally to distinguish it visually
