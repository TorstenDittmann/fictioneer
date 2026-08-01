// Generates the Fictioneer app icon set. One-off, headless (CoreGraphics +
// CoreText only — safe without a GUI session). Run from apps/fictioneer-swift:
//
//     swift scripts/generate_icon.swift
//
// Writes the ten icon_NxN[@2x].png files into
// Fictioneer/Resources/Assets.xcassets/AppIcon.appiconset/.

import CoreGraphics
import CoreText
import Foundation
import ImageIO
import UniformTypeIdentifiers

let scriptDirectory = URL(fileURLWithPath: CommandLine.arguments[0])
    .resolvingSymlinksInPath()
    .deletingLastPathComponent()
let appRoot = scriptDirectory.deletingLastPathComponent()
let fontURL = appRoot.appending(path: "Fictioneer/Resources/Fonts/Quattrocento-Bold.ttf")
let outputDirectory = appRoot.appending(path: "Fictioneer/Resources/Assets.xcassets/AppIcon.appiconset")

guard FileManager.default.fileExists(atPath: fontURL.path) else {
    fatalError("Font not found at \(fontURL.path)")
}
guard CTFontManagerRegisterFontsForURL(fontURL as CFURL, .process, nil) else {
    fatalError("Could not register Quattrocento-Bold")
}

let canvas = 1024
let colorSpace = CGColorSpace(name: CGColorSpace.sRGB)!

func makeContext(size: Int) -> CGContext {
    guard let context = CGContext(
        data: nil,
        width: size,
        height: size,
        bitsPerComponent: 8,
        bytesPerRow: 0,
        space: colorSpace,
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    ) else {
        fatalError("Could not create CGContext of size \(size)")
    }
    return context
}

func color(_ hex: UInt32) -> CGColor {
    CGColor(
        colorSpace: colorSpace,
        components: [
            CGFloat((hex >> 16) & 0xFF) / 255,
            CGFloat((hex >> 8) & 0xFF) / 255,
            CGFloat(hex & 0xFF) / 255,
            1,
        ]
    )!
}

// MARK: - Master tile

let master = makeContext(size: canvas)

// macOS-style icon: transparent canvas, rounded tile with ~10% margins.
let tileRect = CGRect(x: 100, y: 100, width: 824, height: 824)
let tilePath = CGPath(roundedRect: tileRect, cornerWidth: 185, cornerHeight: 185, transform: nil)
master.addPath(tilePath)
master.clip()

// Diagonal indigo → violet gradient (the Fictioneer accent family).
let gradient = CGGradient(
    colorsSpace: colorSpace,
    colors: [color(0x6366F1), color(0x8B5CF6)] as CFArray,
    locations: [0, 1]
)!
master.drawLinearGradient(
    gradient,
    start: CGPoint(x: tileRect.minX, y: tileRect.maxY),
    end: CGPoint(x: tileRect.maxX, y: tileRect.minY),
    options: []
)

// White Quattrocento-Bold "F", optically centered via tight glyph bounds.
let probeFont = CTFontCreateWithName("Quattrocento-Bold" as CFString, 100, nil)
let white = CGColor(colorSpace: colorSpace, components: [1, 1, 1, 1])!

func line(fontSize: CGFloat) -> CTLine {
    let font = CTFontCreateWithName("Quattrocento-Bold" as CFString, fontSize, nil)
    let attributed = NSAttributedString(string: "F", attributes: [
        kCTFontAttributeName as NSAttributedString.Key: font,
        kCTForegroundColorAttributeName as NSAttributedString.Key: white,
    ])
    return CTLineCreateWithAttributedString(attributed)
}

let probeBounds = CTLineGetBoundsWithOptions(line(fontSize: 100), .useGlyphPathBounds)
let targetGlyphHeight = tileRect.height * 0.55
let fontSize = 100 * targetGlyphHeight / probeBounds.height
let glyphLine = line(fontSize: fontSize)
let glyphBounds = CTLineGetBoundsWithOptions(glyphLine, .useGlyphPathBounds)

master.textPosition = CGPoint(
    x: tileRect.midX - glyphBounds.midX,
    y: tileRect.midY - glyphBounds.midY
)
CTLineDraw(glyphLine, master)

guard let masterImage = master.makeImage() else {
    fatalError("Could not render master image")
}

// MARK: - Export all sizes

func writePNG(_ image: CGImage, to url: URL) {
    guard let destination = CGImageDestinationCreateWithURL(
        url as CFURL, UTType.png.identifier as CFString, 1, nil
    ) else {
        fatalError("Could not create destination for \(url.lastPathComponent)")
    }
    CGImageDestinationAddImage(destination, image, nil)
    guard CGImageDestinationFinalize(destination) else {
        fatalError("Could not write \(url.lastPathComponent)")
    }
}

let variants: [(name: String, pixels: Int)] = [
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

for variant in variants {
    let context = makeContext(size: variant.pixels)
    context.interpolationQuality = .high
    context.draw(masterImage, in: CGRect(x: 0, y: 0, width: variant.pixels, height: variant.pixels))
    guard let image = context.makeImage() else {
        fatalError("Could not scale to \(variant.pixels)")
    }
    writePNG(image, to: outputDirectory.appending(path: variant.name))
    print("wrote \(variant.name)")
}
print("Done.")
