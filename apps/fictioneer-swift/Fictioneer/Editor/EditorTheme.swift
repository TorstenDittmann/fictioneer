import AppKit

enum BlockStyle: Equatable {
    case body
    case heading(Int)
    case blockquote
}

/// Fonts, colors, and attribute dictionaries for the writing surface.
/// Text attributes only use system semantic colors (they are archived with the
/// content and must adapt to appearance changes); the custom paper colors are
/// view-level only and never enter the text storage.
struct EditorTheme: Equatable {
    let fontFamily: String
    let fontSize: CGFloat
    let lineHeight: CGFloat

    init(settings: AppSettings) {
        fontFamily = settings.editorFontFamily
        fontSize = CGFloat(settings.editorFontSize)
        lineHeight = CGFloat(settings.editorLineHeight)
    }

    // Paper tones from the Tauri app (`app.css`): #fefefe light / #0f0f14 dark.
    // Translucent so the behind-window vibrancy (VisualEffectView) glows
    // through — the glass look of the original app.
    static let paperBackground = NSColor(name: nil) { appearance in
        appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
            ? NSColor(srgbRed: 0x0F / 255, green: 0x0F / 255, blue: 0x14 / 255, alpha: 0.5)
            : NSColor(srgbRed: 0xFE / 255, green: 0xFE / 255, blue: 0xFE / 255, alpha: 0.65)
    }

    var bodyFont: NSFont {
        FontLoader.editorFont(family: fontFamily, size: fontSize)
    }

    var bodyAttributes: [NSAttributedString.Key: Any] {
        [
            .font: bodyFont,
            .paragraphStyle: paragraphStyle(),
            .foregroundColor: NSColor.labelColor,
        ]
    }

    func headingAttributes(level: Int) -> [NSAttributedString.Key: Any] {
        let scale: CGFloat = switch level {
        case 1: 1.7
        case 2: 1.4
        default: 1.15
        }
        let style = paragraphStyle()
        style.paragraphSpacingBefore = fontSize * 0.8
        style.paragraphSpacing = fontSize * 0.3
        return [
            .font: FontLoader.headingFont(size: (fontSize * scale).rounded()),
            .paragraphStyle: style,
            .foregroundColor: NSColor.labelColor,
            .headingLevel: level,
        ]
    }

    var blockquoteAttributes: [NSAttributedString.Key: Any] {
        let style = paragraphStyle()
        style.headIndent = 28
        style.firstLineHeadIndent = 28
        return [
            .font: NSFontManager.shared.convert(bodyFont, toHaveTrait: .italicFontMask),
            .paragraphStyle: style,
            .foregroundColor: NSColor.secondaryLabelColor,
            .blockquote: true,
        ]
    }

    func attributes(for style: BlockStyle) -> [NSAttributedString.Key: Any] {
        switch style {
        case .body: bodyAttributes
        case .heading(let level): headingAttributes(level: level)
        case .blockquote: blockquoteAttributes
        }
    }

    /// CSS line-height ~1.75 expressed as a multiple of AppKit's natural line height.
    private func paragraphStyle() -> NSMutableParagraphStyle {
        let style = NSMutableParagraphStyle()
        style.lineHeightMultiple = lineHeight / 1.2
        style.paragraphSpacing = fontSize * 0.4
        return style
    }
}
