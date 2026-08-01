import AppKit

/// The bundled TTFs (iA Writer Duo S, Quattrocento) are auto-activated via
/// `ATSApplicationFontsPath`; this type resolves them with graceful fallbacks
/// to system fonts when a family is missing.
enum FontLoader {
    static let bundledEditorFamily = "iA Writer Duo S"
    static let bundledHeadingFamily = "Quattrocento"

    /// Families offered in the Settings font picker.
    static let editorFamilies: [String] = [
        bundledEditorFamily,
        bundledHeadingFamily,
        "Georgia",
        "Times New Roman",
        "System Serif",
        "System Mono",
        "System Sans",
    ]

    static var defaultEditorFamily: String {
        bundledEditorFamily
    }

    static func editorFont(family: String, size: CGFloat) -> NSFont {
        switch family {
        case "System Serif":
            return .systemFont(ofSize: size).withDesign(.serif)
        case "System Mono":
            return .monospacedSystemFont(ofSize: size, weight: .regular)
        case "System Sans":
            return .systemFont(ofSize: size)
        default:
            if let font = NSFont(name: family, size: size) {
                return font
            }
            // Bundled font missing (e.g. resources stripped) — mirror the original app's mono feel.
            return .monospacedSystemFont(ofSize: size, weight: .regular)
        }
    }

    static func headingFont(size: CGFloat) -> NSFont {
        if let font = NSFont(name: "\(bundledHeadingFamily)-Bold", size: size) {
            return font
        }
        if let font = NSFont(name: bundledHeadingFamily, size: size) {
            return NSFontManager.shared.convert(font, toHaveTrait: .boldFontMask)
        }
        return .systemFont(ofSize: size, weight: .bold).withDesign(.serif)
    }
}

extension NSFont {
    func withDesign(_ design: NSFontDescriptor.SystemDesign) -> NSFont {
        guard let descriptor = fontDescriptor.withDesign(design) else { return self }
        return NSFont(descriptor: descriptor, size: pointSize) ?? self
    }
}
