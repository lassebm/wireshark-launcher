# Wireshark Launcher

**Open multiple Wireshark windows on macOS — the way it should work.**

By default, macOS treats Wireshark as a single-instance app. Clicking its Dock icon just brings the existing window to the front. If you work with multiple capture files side by side, you're stuck navigating menus or running terminal commands every time.

Wireshark Launcher fixes this with a simple idea: a tiny app that sits in your Dock and always opens a **new** Wireshark instance.

- **Click** the Dock icon — fresh Wireshark window
- **Drop a pcap** on the Dock icon — new Wireshark window with that file
- **Drop multiple files** — one new window each

The app launches Wireshark and immediately quits. No background processes, no memory overhead, no windows of its own.

## Why?

Wireshark is one of the few macOS apps where you routinely need multiple independent instances — comparing captures, monitoring different interfaces, reviewing old files while capturing new ones. macOS makes this surprisingly hard. `open -n` works in the terminal, but there's no GUI equivalent.

This app is that GUI equivalent. Put it in your Dock next to Wireshark and forget about it.

## The Icon

The app icon is the Wireshark shark fin flipped horizontally — just different enough to tell them apart at a glance.

## Build

Requires Wireshark installed at `/Applications/Wireshark.app`.

```sh
./build.sh
```

Produces `build/Wireshark Launcher.app`.

## Install

```sh
cp -r "build/Wireshark Launcher.app" /Applications/
```

Or drag the app to `/Applications` in Finder.

Since the app is not signed, macOS will quarantine it. Remove the quarantine attribute before first launch:

```sh
xattr -d com.apple.quarantine "/Applications/Wireshark Launcher.app"
```

## Test

```sh
./test.sh
```

Builds the app and validates bundle structure, universal binary, Info.plist correctness, icon generation, and source invariants.

## Technical Details

- Pure Swift, compiled with `swiftc` — no Xcode project, no dependencies
- Universal binary (arm64 + x86_64), targeting macOS 12.0+
- Icon generated at build time from Wireshark's own icon using CoreGraphics
- Registers as a viewer for pcap, pcapng, and other capture file formats (`LSHandlerRank: Alternate`)

## Built Entirely by AI

This project — every line of Swift, the build script, the icon generation, the Info.plist, and even this README — was written through agentic coding with [Claude Code](https://docs.anthropic.com/en/docs/agents-and-tools/claude-code/overview). A human described what they wanted; an AI agent wrote, compiled, tested, and iterated on the code. No manual editing involved.

## License

[MIT](LICENSE)
