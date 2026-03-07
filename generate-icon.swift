#!/usr/bin/env swift

import Cocoa

// Configuration
let wiresharkIconPath = "/Applications/Wireshark.app/Contents/Resources/Wireshark.icns"
let outputDir: String

if CommandLine.arguments.count > 1 {
    outputDir = CommandLine.arguments[1]
} else {
    outputDir = "build"
}

let outputIconsetPath = "\(outputDir)/AppIcon.iconset"
let outputIcnsPath = "\(outputDir)/AppIcon.icns"

// Icon sizes needed for a macOS .icns file
let iconSizes: [(name: String, size: Int)] = [
    ("icon_16x16", 16),
    ("icon_16x16@2x", 32),
    ("icon_32x32", 32),
    ("icon_32x32@2x", 64),
    ("icon_128x128", 128),
    ("icon_128x128@2x", 256),
    ("icon_256x256", 256),
    ("icon_256x256@2x", 512),
    ("icon_512x512", 512),
    ("icon_512x512@2x", 1024),
]

func generateIcon() {
    // Load the Wireshark icon
    guard let wiresharkIcon = NSImage(contentsOfFile: wiresharkIconPath) else {
        print("Error: Could not load Wireshark icon from \(wiresharkIconPath)")
        exit(1)
    }

    // Create iconset directory
    let fileManager = FileManager.default
    try? fileManager.removeItem(atPath: outputIconsetPath)
    try! fileManager.createDirectory(atPath: outputIconsetPath, withIntermediateDirectories: true)

    for (name, size) in iconSizes {
        let cgSize = CGFloat(size)

        // Create bitmap context
        let bitmapRep = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: size,
            pixelsHigh: size,
            bitsPerSample: 8,
            samplesPerPixel: 4,
            hasAlpha: true,
            isPlanar: false,
            colorSpaceName: .deviceRGB,
            bytesPerRow: 0,
            bitsPerPixel: 0
        )!

        let context = NSGraphicsContext(bitmapImageRep: bitmapRep)!
        NSGraphicsContext.current = context

        let cgContext = context.cgContext

        // Flip horizontally: translate to right edge, then scale X by -1
        cgContext.translateBy(x: cgSize, y: 0)
        cgContext.scaleBy(x: -1.0, y: 1.0)

        // Draw the Wireshark icon (it will be mirrored by the transform)
        let iconRect = NSRect(x: 0, y: 0, width: cgSize, height: cgSize)
        wiresharkIcon.draw(in: iconRect,
                           from: NSRect(origin: .zero, size: wiresharkIcon.size),
                           operation: .copy,
                           fraction: 1.0)

        NSGraphicsContext.current = nil

        // Save as PNG
        let pngData = bitmapRep.representation(using: .png, properties: [:])!
        let outputPath = "\(outputIconsetPath)/\(name).png"
        try! pngData.write(to: URL(fileURLWithPath: outputPath))
    }

    // Convert iconset to icns using iconutil
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
    process.arguments = ["-c", "icns", outputIconsetPath, "-o", outputIcnsPath]

    try! process.run()
    process.waitUntilExit()

    if process.terminationStatus == 0 {
        print("Successfully generated \(outputIcnsPath)")
        // Clean up iconset
        try? fileManager.removeItem(atPath: outputIconsetPath)
    } else {
        print("Error: iconutil failed with exit code \(process.terminationStatus)")
        exit(1)
    }
}

generateIcon()
