import Foundation
import AppKit
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

// Design: rounded square. Top 1/3 = #044735 with "9.41 W" in white,
// flush right, vertically centered. Bottom 2/3 = very light gray.
// Mimics a Mac window with the menu bar showing the wattage readout.

func renderIcon(size: CGFloat) -> CGImage {
    let cs = CGColorSpaceCreateDeviceRGB()
    let ctx = CGContext(
        data: nil, width: Int(size), height: Int(size),
        bitsPerComponent: 8, bytesPerRow: 0,
        space: cs,
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    )!
    ctx.interpolationQuality = .high
    let rect = CGRect(x: 0, y: 0, width: size, height: size)

    // macOS Big Sur–ish corner radius (~22.5% of the side)
    let cornerRadius = size * 0.2237
    ctx.clear(rect)
    let path = CGPath(roundedRect: rect, cornerWidth: cornerRadius, cornerHeight: cornerRadius, transform: nil)
    ctx.addPath(path)
    ctx.clip()

    // Bottom 2/3 — very light gray (paint full canvas first)
    ctx.setFillColor(NSColor(red: 0.965, green: 0.965, blue: 0.97, alpha: 1.0).cgColor)
    ctx.fill(rect)

    // Top band — #044735. Slightly less than half the height.
    let topHeight = size * 0.42
    let topRect = CGRect(x: 0, y: size - topHeight, width: size, height: topHeight)
    ctx.setFillColor(NSColor(red: 0x04/255.0, green: 0x47/255.0, blue: 0x35/255.0, alpha: 1.0).cgColor)
    ctx.fill(topRect)

    // "9.41 W" — only readable at >= 64px. Below that, keep the icon clean.
    if size >= 64 {
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(cgContext: ctx, flipped: false)
        let fontSize = size * 0.20
        let font = NSFont.monospacedDigitSystemFont(ofSize: fontSize, weight: .semibold)
        let attrs: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: NSColor.white
        ]
        let attr = NSAttributedString(string: "9.41 W", attributes: attrs)
        let tSize = attr.size()
        // Centered in the dark band, both axes
        let x = (size - tSize.width) / 2.0
        let y = (size - topHeight) + (topHeight - tSize.height) / 2.0 - size * 0.008
        attr.draw(at: NSPoint(x: x, y: y))
        NSGraphicsContext.restoreGraphicsState()
    }

    return ctx.makeImage()!
}

func writePNG(_ image: CGImage, to url: URL) throws {
    guard let dest = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil) else {
        throw NSError(domain: "icon", code: 1)
    }
    CGImageDestinationAddImage(dest, image, nil)
    if !CGImageDestinationFinalize(dest) {
        throw NSError(domain: "icon", code: 2)
    }
}

let outArg = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "AppIcon.iconset"
let outDir = URL(fileURLWithPath: outArg)
try FileManager.default.createDirectory(at: outDir, withIntermediateDirectories: true)

let variants: [(String, CGFloat)] = [
    ("icon_16x16.png", 16),
    ("icon_16x16@2x.png", 32),
    ("icon_32x32.png", 32),
    ("icon_32x32@2x.png", 64),
    ("icon_128x128.png", 128),
    ("icon_128x128@2x.png", 256),
    ("icon_256x256.png", 256),
    ("icon_256x256@2x.png", 512),
    ("icon_512x512.png", 512),
    ("icon_512x512@2x.png", 1024),
]

for (name, px) in variants {
    let img = renderIcon(size: px)
    try writePNG(img, to: outDir.appendingPathComponent(name))
}

let preview = outDir.deletingLastPathComponent().appendingPathComponent("AppIcon-preview.png")
try writePNG(renderIcon(size: 1024), to: preview)
print("iconset: \(outDir.path)")
print("preview: \(preview.path)")
