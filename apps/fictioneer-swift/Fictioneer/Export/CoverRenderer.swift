import AppKit
import CoreText

/// Draws typographic covers from the book's title, subtitle, author and
/// series. Pure CoreGraphics, so it runs off the main thread; the output is
/// a 1:1.6 portrait JPEG, the ratio stores recommend.
nonisolated enum CoverRenderer {
    struct Input: Hashable, Sendable {
        var title: String
        var subtitle: String
        var author: String
        var series: String
        var design: CoverDesign
        var palette: CoverPalette
    }

    static let exportSize = CGSize(width: 1600, height: 2560)

    static func input(for book: BookDocument) -> Input {
        var series = book.settings.series.trimmingCharacters(in: .whitespaces)
        let number = book.settings.seriesNumber.trimmingCharacters(in: .whitespaces)
        if !series.isEmpty, !number.isEmpty {
            series += " · Book \(number)"
        }
        return Input(
            title: book.title,
            subtitle: book.subtitle,
            author: book.author,
            series: series,
            design: book.settings.coverDesign,
            palette: book.settings.coverPalette
        )
    }

    static func jpegData(for input: Input, size: CGSize = exportSize) -> Data? {
        guard let image = render(input, size: size) else { return nil }
        let rep = NSBitmapImageRep(cgImage: image)
        return rep.representation(using: .jpeg, properties: [.compressionFactor: 0.9])
    }

    static func render(_ input: Input, size: CGSize) -> CGImage? {
        guard let context = CGContext(
            data: nil,
            width: Int(size.width),
            height: Int(size.height),
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: CGColorSpace(name: CGColorSpace.sRGB)!,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }
        let colors = Colors(input.palette, design: input.design)
        let canvas = Canvas(context: context, size: size, colors: colors)
        switch input.design {
        case .classic: drawClassic(input, on: canvas)
        case .modern: drawModern(input, on: canvas)
        case .minimal: drawMinimal(input, on: canvas)
        }
        return context.makeImage()
    }

    // MARK: - Designs

    private static func drawClassic(_ input: Input, on canvas: Canvas) {
        let (w, h) = (canvas.size.width, canvas.size.height)
        canvas.fill(canvas.colors.background)

        // Double rule frame.
        let outer = CGRect(x: w * 0.05, y: w * 0.05, width: w * 0.9, height: h - w * 0.1)
        canvas.stroke(outer, color: canvas.colors.accent, width: w * 0.004)
        canvas.stroke(outer.insetBy(dx: w * 0.018, dy: w * 0.018), color: canvas.colors.accent, width: w * 0.0015)

        let textWidth = w * 0.72
        var y = h * 0.14
        if !input.series.isEmpty {
            y = canvas.drawText(
                input.series.uppercased(), font: serif(size: w * 0.026), color: canvas.colors.accent,
                width: textWidth, top: y, tracking: 0.2
            ) + h * 0.02
        }

        let titleTop = h * 0.26
        let titleBottom = canvas.drawFitted(
            input.title, font: { serifBold(size: $0) }, maxSize: w * 0.12, minSize: w * 0.05,
            maxLines: 4, color: canvas.colors.foreground, width: textWidth, top: titleTop, lineHeight: 1.1
        )
        var below = titleBottom + h * 0.03
        if !input.subtitle.isEmpty {
            below = canvas.drawText(
                input.subtitle, font: serifItalic(size: w * 0.038), color: canvas.colors.foreground,
                width: textWidth, top: below
            ) + h * 0.02
        }
        _ = canvas.drawText(
            "❦", font: serif(size: w * 0.06), color: canvas.colors.accent, width: textWidth, top: below + h * 0.01
        )

        if !input.author.isEmpty {
            canvas.drawTextAnchoredBottom(
                input.author.uppercased(), font: serif(size: w * 0.042), color: canvas.colors.foreground,
                width: textWidth, bottom: h * 0.88, tracking: 0.15
            )
        }
    }

    private static func drawModern(_ input: Input, on canvas: Canvas) {
        let (w, h) = (canvas.size.width, canvas.size.height)
        canvas.fill(canvas.colors.background)

        let margin = w * 0.1
        let textWidth = w - margin * 2
        canvas.fillRect(CGRect(x: margin, y: h * 0.1, width: w * 0.16, height: w * 0.018), color: canvas.colors.accent)

        if !input.author.isEmpty {
            _ = canvas.drawText(
                input.author.uppercased(), font: sans(size: w * 0.036, weight: .semibold),
                color: canvas.colors.foreground, width: textWidth, top: h * 0.14, alignment: .left, tracking: 0.18
            )
        }

        // Title sits in the lower half, left-aligned and heavy.
        let titleFont: (CGFloat) -> NSFont = { sans(size: $0, weight: .heavy) }
        let titleSize = canvas.fittedSize(
            input.title, font: titleFont, maxSize: w * 0.15, minSize: w * 0.06, maxLines: 4,
            width: textWidth, lineHeight: 1.0
        )
        let titleHeight = canvas.textHeight(input.title, font: titleFont(titleSize), width: textWidth, lineHeight: 1.0)
        var subtitleHeight: CGFloat = 0
        if !input.subtitle.isEmpty {
            subtitleHeight = canvas.textHeight(
                input.subtitle, font: sans(size: w * 0.04, weight: .regular), width: textWidth
            ) + h * 0.02
        }
        let seriesHeight = input.series.isEmpty ? 0 : h * 0.05
        let top = h * 0.88 - titleHeight - subtitleHeight - seriesHeight
        var y = canvas.drawText(
            input.title, font: titleFont(titleSize), color: canvas.colors.foreground,
            width: textWidth, top: top, alignment: .left, lineHeight: 1.0
        )
        if !input.subtitle.isEmpty {
            y = canvas.drawText(
                input.subtitle, font: sans(size: w * 0.04, weight: .regular), color: canvas.colors.foreground,
                width: textWidth, top: y + h * 0.02, alignment: .left
            )
        }
        if !input.series.isEmpty {
            _ = canvas.drawText(
                input.series.uppercased(), font: sans(size: w * 0.026, weight: .semibold), color: canvas.colors.accent,
                width: textWidth, top: y + h * 0.025, alignment: .left, tracking: 0.2
            )
        }
    }

    private static func drawMinimal(_ input: Input, on canvas: Canvas) {
        let (w, h) = (canvas.size.width, canvas.size.height)
        canvas.fill(canvas.colors.background)

        let textWidth = w * 0.7
        let titleFont: (CGFloat) -> NSFont = { serif(size: $0) }
        let titleSize = canvas.fittedSize(
            input.title, font: titleFont, maxSize: w * 0.1, minSize: w * 0.045, maxLines: 4,
            width: textWidth, lineHeight: 1.15
        )
        let titleHeight = canvas.textHeight(input.title, font: titleFont(titleSize), width: textWidth, lineHeight: 1.15)
        var y = canvas.drawText(
            input.title, font: titleFont(titleSize), color: canvas.colors.foreground,
            width: textWidth, top: h * 0.42 - titleHeight / 2, lineHeight: 1.15
        )
        canvas.fillRect(
            CGRect(x: (w - w * 0.08) / 2, y: y + h * 0.03, width: w * 0.08, height: max(2, w * 0.002)),
            color: canvas.colors.accent
        )
        y += h * 0.06
        if !input.subtitle.isEmpty {
            y = canvas.drawText(
                input.subtitle, font: serifItalic(size: w * 0.034), color: canvas.colors.foreground,
                width: textWidth, top: y
            )
        }
        if !input.author.isEmpty {
            canvas.drawTextAnchoredBottom(
                input.author, font: serif(size: w * 0.04), color: canvas.colors.foreground,
                width: textWidth, bottom: h * 0.9, tracking: 0.06
            )
        }
        if !input.series.isEmpty {
            _ = canvas.drawText(
                input.series.uppercased(), font: serif(size: w * 0.024), color: canvas.colors.accent,
                width: textWidth, top: h * 0.09, tracking: 0.25
            )
        }
    }

    // MARK: - Fonts

    private static func serif(size: CGFloat) -> NSFont {
        NSFont(name: "Quattrocento", size: size) ?? NSFont(name: "Georgia", size: size) ?? .systemFont(ofSize: size)
    }

    private static func serifBold(size: CGFloat) -> NSFont {
        NSFont(name: "Quattrocento-Bold", size: size) ?? NSFont(name: "Georgia-Bold", size: size) ?? .boldSystemFont(ofSize: size)
    }

    private static func serifItalic(size: CGFloat) -> NSFont {
        NSFont(name: "Georgia-Italic", size: size) ?? serif(size: size)
    }

    private static func sans(size: CGFloat, weight: NSFont.Weight) -> NSFont {
        .systemFont(ofSize: size, weight: weight)
    }

    // MARK: - Colors

    struct Colors {
        let background: CGColor
        let foreground: CGColor
        let accent: CGColor

        init(_ palette: CoverPalette, design: CoverDesign) {
            func rgb(_ hex: UInt32) -> CGColor {
                CGColor(
                    srgbRed: CGFloat((hex >> 16) & 0xFF) / 255,
                    green: CGFloat((hex >> 8) & 0xFF) / 255,
                    blue: CGFloat(hex & 0xFF) / 255,
                    alpha: 1
                )
            }
            let (bg, fg, accent): (UInt32, UInt32, UInt32) = switch palette {
            case .ink: (0x1C2230, 0xF3EEE3, 0xC9A45C)
            case .paper: (0xF4EFE4, 0x2A2622, 0x9C3B2E)
            case .forest: (0x1F3A30, 0xEFE8D8, 0xD7B377)
            case .oxblood: (0x5A1F24, 0xF6EDE1, 0xE0B973)
            case .dusk: (0x2E2A4A, 0xF1ECF7, 0xE7A07A)
            }
            background = rgb(bg)
            foreground = rgb(fg)
            self.accent = rgb(accent)
        }
    }

    static func swatch(for palette: CoverPalette) -> (background: CGColor, accent: CGColor) {
        let colors = Colors(palette, design: .classic)
        return (colors.background, colors.accent)
    }

    // MARK: - Drawing

    /// Top-left–origin drawing helpers over a bottom-left CGContext.
    private struct Canvas {
        let context: CGContext
        let size: CGSize
        let colors: Colors

        func fill(_ color: CGColor) {
            fillRect(CGRect(origin: .zero, size: size), color: color)
        }

        func fillRect(_ rect: CGRect, color: CGColor) {
            context.setFillColor(color)
            context.fill(flipped(rect))
        }

        func stroke(_ rect: CGRect, color: CGColor, width: CGFloat) {
            context.setStrokeColor(color)
            context.setLineWidth(width)
            context.stroke(flipped(rect))
        }

        private func flipped(_ rect: CGRect) -> CGRect {
            CGRect(x: rect.minX, y: size.height - rect.maxY, width: rect.width, height: rect.height)
        }

        private func attributed(
            _ text: String,
            font: NSFont,
            color: CGColor,
            alignment: NSTextAlignment,
            tracking: CGFloat,
            lineHeight: CGFloat
        ) -> NSAttributedString {
            let style = NSMutableParagraphStyle()
            style.alignment = alignment
            style.lineHeightMultiple = lineHeight
            style.lineBreakMode = .byWordWrapping
            return NSAttributedString(string: text, attributes: [
                .font: font,
                .foregroundColor: NSColor(cgColor: color) ?? .black,
                .paragraphStyle: style,
                .kern: font.pointSize * tracking,
            ])
        }

        func textHeight(
            _ text: String, font: NSFont, width: CGFloat, tracking: CGFloat = 0, lineHeight: CGFloat = 1.2
        ) -> CGFloat {
            let string = attributed(text, font: font, color: colors.foreground, alignment: .center, tracking: tracking, lineHeight: lineHeight)
            return frameSize(string, width: width).height
        }

        private func frameSize(_ string: NSAttributedString, width: CGFloat) -> CGSize {
            let setter = CTFramesetterCreateWithAttributedString(string)
            return CTFramesetterSuggestFrameSizeWithConstraints(
                setter, CFRange(location: 0, length: 0), nil,
                CGSize(width: width, height: .greatestFiniteMagnitude), nil
            )
        }

        private func lineCount(_ string: NSAttributedString, width: CGFloat) -> Int {
            let setter = CTFramesetterCreateWithAttributedString(string)
            let path = CGPath(rect: CGRect(x: 0, y: 0, width: width, height: 100_000), transform: nil)
            let frame = CTFramesetterCreateFrame(setter, CFRange(location: 0, length: 0), path, nil)
            return (CTFrameGetLines(frame) as? [CTLine])?.count ?? 0
        }

        /// The largest size (stepping down) at which the text fits in
        /// `maxLines` without breaking inside a word.
        func fittedSize(
            _ text: String,
            font: (CGFloat) -> NSFont,
            maxSize: CGFloat,
            minSize: CGFloat,
            maxLines: Int,
            width: CGFloat,
            lineHeight: CGFloat
        ) -> CGFloat {
            var size = maxSize
            let words: [String] = text.components(separatedBy: .whitespacesAndNewlines)
            let longestWord = words.max(by: { $0.count < $1.count }) ?? text
            while size > minSize {
                let string = attributed(text, font: font(size), color: colors.foreground, alignment: .center, tracking: 0, lineHeight: lineHeight)
                let word = attributed(longestWord, font: font(size), color: colors.foreground, alignment: .center, tracking: 0, lineHeight: lineHeight)
                if lineCount(string, width: width) <= maxLines, frameSize(word, width: .greatestFiniteMagnitude).width <= width {
                    return size
                }
                size *= 0.93
            }
            return minSize
        }

        func drawFitted(
            _ text: String,
            font: (CGFloat) -> NSFont,
            maxSize: CGFloat,
            minSize: CGFloat,
            maxLines: Int,
            color: CGColor,
            width: CGFloat,
            top: CGFloat,
            lineHeight: CGFloat
        ) -> CGFloat {
            let size = fittedSize(text, font: font, maxSize: maxSize, minSize: minSize, maxLines: maxLines, width: width, lineHeight: lineHeight)
            return drawText(text, font: font(size), color: color, width: width, top: top, lineHeight: lineHeight)
        }

        /// Draws horizontally centered on the canvas; returns the bottom edge.
        @discardableResult
        func drawText(
            _ text: String,
            font: NSFont,
            color: CGColor,
            width: CGFloat,
            top: CGFloat,
            alignment: NSTextAlignment = .center,
            tracking: CGFloat = 0,
            lineHeight: CGFloat = 1.2
        ) -> CGFloat {
            let string = attributed(text, font: font, color: color, alignment: alignment, tracking: tracking, lineHeight: lineHeight)
            let height = ceil(frameSize(string, width: width).height)
            let x = (size.width - width) / 2
            let rect = CGRect(x: x, y: size.height - top - height, width: width, height: height)
            let setter = CTFramesetterCreateWithAttributedString(string)
            let frame = CTFramesetterCreateFrame(setter, CFRange(location: 0, length: 0), CGPath(rect: rect, transform: nil), nil)
            CTFrameDraw(frame, context)
            return top + height
        }

        func drawTextAnchoredBottom(
            _ text: String,
            font: NSFont,
            color: CGColor,
            width: CGFloat,
            bottom: CGFloat,
            tracking: CGFloat = 0
        ) {
            let height = ceil(textHeight(text, font: font, width: width, tracking: tracking))
            drawText(text, font: font, color: color, width: width, top: bottom - height, tracking: tracking)
        }
    }
}
