#!/usr/bin/swift
// Renders the app icon (a traffic light with the green light on) into an asset catalog icon set.
// No dependencies beyond AppKit, so the icon can be regenerated with:
//   swift scripts/make-icon.swift OfficeLight/Assets.xcassets/AppIcon.appiconset
import AppKit

let outputDirectory = URL(fileURLWithPath: CommandLine.arguments.count > 1
    ? CommandLine.arguments[1]
    : "OfficeLight/Assets.xcassets/AppIcon.appiconset")

// The drawing is resolution independent: the block is re-run for every output size.
let icon = NSImage(size: NSSize(width: 1024, height: 1024), flipped: false) { _ in
    // Apple's macOS icon grid: an 824 pt rounded square centered on a 1024 pt canvas.
    let plate = NSRect(x: 100, y: 100, width: 824, height: 824)
    let plateShape = NSBezierPath(roundedRect: plate, xRadius: 185, yRadius: 185)

    NSGraphicsContext.saveGraphicsState()
    let shadow = NSShadow()
    shadow.shadowColor = NSColor.black.withAlphaComponent(0.35)
    shadow.shadowBlurRadius = 24
    shadow.shadowOffset = NSSize(width: 0, height: -12)
    shadow.set()
    NSColor(calibratedRed: 0.14, green: 0.16, blue: 0.20, alpha: 1).setFill()
    plateShape.fill()
    NSGraphicsContext.restoreGraphicsState()

    NSGraphicsContext.saveGraphicsState()
    plateShape.addClip()
    NSGradient(starting: NSColor(white: 1, alpha: 0.12), ending: NSColor(white: 0, alpha: 0.18))?
        .draw(in: plate, angle: -90)
    NSGraphicsContext.restoreGraphicsState()

    // Three lights, top to bottom: gray (no office time yet), red (goal not reached), green (goal reached, lit).
    let diameter: CGFloat = 168
    let spacing: CGFloat = 224
    let lights: [(offset: CGFloat, color: NSColor, lit: Bool)] = [
        (spacing, NSColor(calibratedWhite: 0.55, alpha: 1), false),
        (0, NSColor.systemRed, false),
        (-spacing, NSColor.systemGreen, true),
    ]
    for light in lights {
        let frame = NSRect(x: plate.midX - diameter / 2, y: plate.midY + light.offset - diameter / 2,
                           width: diameter, height: diameter)
        let socket = NSBezierPath(ovalIn: frame.insetBy(dx: -14, dy: -14))
        NSColor.black.withAlphaComponent(0.35).setFill()
        socket.fill()

        NSGraphicsContext.saveGraphicsState()
        if light.lit {
            let glow = NSShadow()
            glow.shadowColor = light.color.withAlphaComponent(0.9)
            glow.shadowBlurRadius = 48
            glow.shadowOffset = .zero
            glow.set()
            light.color.setFill()
        } else {
            light.color.withAlphaComponent(0.28).setFill()
        }
        NSBezierPath(ovalIn: frame).fill()
        NSGraphicsContext.restoreGraphicsState()

        // Specular highlight so the lit light reads as glass.
        if light.lit {
            NSGraphicsContext.saveGraphicsState()
            NSBezierPath(ovalIn: frame).addClip()
            NSGradient(starting: NSColor(white: 1, alpha: 0.55), ending: NSColor(white: 1, alpha: 0))?
                .draw(in: NSRect(x: frame.minX, y: frame.midY, width: frame.width, height: frame.height / 2), angle: -90)
            NSGraphicsContext.restoreGraphicsState()
        }
    }
    return true
}

func png(size pixels: Int) -> Data {
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: pixels, pixelsHigh: pixels, bitsPerSample: 8,
                               samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB,
                               bytesPerRow: 0, bitsPerPixel: 0)!
    rep.size = NSSize(width: pixels, height: pixels)
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    NSGraphicsContext.current?.imageInterpolation = .high
    icon.draw(in: NSRect(x: 0, y: 0, width: pixels, height: pixels), from: .zero, operation: .copy, fraction: 1)
    NSGraphicsContext.restoreGraphicsState()
    return rep.representation(using: .png, properties: [:])!
}

try FileManager.default.createDirectory(at: outputDirectory, withIntermediateDirectories: true)
var images: [[String: String]] = []
for points in [16, 32, 128, 256, 512] {
    for scale in [1, 2] {
        let name = "icon_\(points)x\(points)\(scale == 2 ? "@2x" : "").png"
        try png(size: points * scale).write(to: outputDirectory.appendingPathComponent(name))
        images.append(["filename": name, "idiom": "mac", "scale": "\(scale)x", "size": "\(points)x\(points)"])
    }
}
let contents: [String: Any] = ["images": images, "info": ["author": "xcode", "version": 1]]
let json = try JSONSerialization.data(withJSONObject: contents, options: [.prettyPrinted, .sortedKeys])
try json.write(to: outputDirectory.appendingPathComponent("Contents.json"))
print("Wrote \(images.count) icons to \(outputDirectory.path)")
