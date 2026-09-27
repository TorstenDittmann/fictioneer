import Foundation

nonisolated enum EpubTemplate: String, CaseIterable, Identifiable, Codable, Sendable {
    case genericNovel = "generic_novel"
    case modernCompact = "modern_compact"
    case classicBook = "classic_book"

    var id: String { rawValue }
    var label: String {
        switch self {
        case .genericNovel: "Novel"
        case .modernCompact: "Modern"
        case .classicBook: "Classic"
        }
    }
    var blurb: String {
        switch self {
        case .genericNovel: "A warm, familiar paperback look with centered chapter heads."
        case .modernCompact: "Clean sans-serif headings, left-aligned, with a brisk rhythm."
        case .classicBook: "Print-inspired: justified text, low chapter drops, small caps."
        }
    }

    var bodyFontStack: String {
        switch self {
        case .genericNovel: #"Georgia, "Times New Roman", serif"#
        case .modernCompact: #""Iowan Old Style", Charter, Georgia, serif"#
        case .classicBook: #"Palatino, "Palatino Linotype", "Book Antiqua", Georgia, serif"#
        }
    }

    var headingFontStack: String {
        switch self {
        case .modernCompact: #""Avenir Next", "Helvetica Neue", Helvetica, Arial, sans-serif"#
        case .genericNovel, .classicBook: bodyFontStack
        }
    }

    var stylesheet: String {
        guard let url = Bundle.main.url(forResource: rawValue, withExtension: "css"),
              let css = try? String(contentsOf: url, encoding: .utf8)
        else { return "" }
        return css
    }
}

/// Fonts that can be embedded in a book (all SIL OFL, bundled with the app).
nonisolated struct EmbeddedFont: Sendable {
    let family: String
    let filename: String
    let weight: String

    static let quattrocento = [
        EmbeddedFont(family: "Quattrocento", filename: "Quattrocento-Regular.ttf", weight: "normal"),
        EmbeddedFont(family: "Quattrocento", filename: "Quattrocento-Bold.ttf", weight: "bold"),
    ]

    var data: Data? {
        let name = (filename as NSString).deletingPathExtension
        guard let url = Bundle.main.url(forResource: name, withExtension: "ttf") else { return nil }
        return try? Data(contentsOf: url)
    }
}

/// The book's single stylesheet: structural rules every template relies on,
/// the template's look, then the writer's design choices on top.
nonisolated enum BookStylesheet {
    static func css(for settings: BookSettings, fontPath: String = "../fonts/") -> String {
        [base, settings.template.stylesheet, options(for: settings, fontPath: fontPath)]
            .joined(separator: "\n\n")
    }

    static func embeddedFonts(for settings: BookSettings) -> [EmbeddedFont] {
        settings.bodyFont == .quattrocento ? EmbeddedFont.quattrocento : []
    }

    private static func options(for settings: BookSettings, fontPath: String) -> String {
        var css = "/* Design options */\n"
        switch settings.bodyFont {
        case .template:
            css += "body { font-family: \(settings.template.bodyFontStack); }\n"
            css += "h1, h2, h3, h4, .chapter-label, .chapter-numeral, .book-subtitle, .book-author { font-family: \(settings.template.headingFontStack); }\n"
        case .quattrocento:
            for font in embeddedFonts(for: settings) {
                css += """
                @font-face {
                \tfont-family: "\(font.family)";
                \tfont-weight: \(font.weight);
                \tfont-style: normal;
                \tsrc: url("\(fontPath)\(font.filename)");
                }\n
                """
            }
            css += #"body { font-family: "Quattrocento", Georgia, serif; }"# + "\n"
        case .reader:
            break
        }
        switch settings.chapterOpening {
        case .plain:
            break
        case .smallCaps:
            css += """
            .opening > p:first-child::first-line {
            \tfont-variant: small-caps;
            \tletter-spacing: 0.04em;
            }\n
            """
        case .dropCap:
            css += """
            .opening > p:first-child::first-letter {
            \tfloat: left;
            \tfont-size: 3.2em;
            \tline-height: 0.85;
            \tmargin: 0.06em 0.08em 0 0;
            }\n
            """
        }
        return css
    }

    private static let base = """
    @charset "utf-8";

    /* Structure shared by every template */
    html, body {
    \tmargin: 0;
    \tpadding: 0;
    }

    body {
    \torphans: 2;
    \twidows: 2;
    }

    p {
    \tmargin: 0;
    \ttext-indent: 1.5em;
    }

    .scene-body > p:first-child,
    .scene-body > h2 + p,
    .scene-body > h3 + p,
    .scene-body > h4 + p,
    .scene-body > blockquote + p,
    .matter p:first-of-type,
    .chapter-heading p,
    .scene-title,
    .scene-break {
    \ttext-indent: 0;
    }

    h1, h2, h3, h4 {
    \t-webkit-hyphens: none;
    \thyphens: none;
    \tpage-break-after: avoid;
    \tbreak-after: avoid;
    }

    .scene-body h2, .scene-body h3, .scene-body h4 {
    \tfont-size: 1.1em;
    \tmargin: 1.5em 0 0.6em 0;
    }

    blockquote {
    \tmargin: 1em 1.5em;
    }

    blockquote p {
    \ttext-indent: 0;
    }

    .scene-break {
    \ttext-align: center;
    \tmargin: 1.2em 0;
    \tletter-spacing: 0.2em;
    }

    hr.scene-break {
    \tborder: none;
    }

    hr.scene-break.rule {
    \twidth: 4em;
    \tmargin: 1.6em auto;
    \tborder-top: 1px solid currentColor;
    \topacity: 0.45;
    }

    hr.scene-break.blank {
    \theight: 1.2em;
    \tmargin: 0;
    }

    /* Cover */
    body.cover-page {
    \ttext-align: center;
    }

    .cover-page img {
    \tmax-width: 100%;
    \tmax-height: 100vh;
    \theight: auto;
    }

    /* Title page */
    .titlepage {
    \ttext-align: center;
    \tmargin-top: 25%;
    }

    .book-subtitle {
    \tfont-size: 1.2em;
    \tfont-style: italic;
    \tmargin: 0 0 3em 0;
    }

    .book-author {
    \tfont-size: 1.2em;
    \tletter-spacing: 0.08em;
    \tmargin: 0 0 6em 0;
    }

    .book-publisher {
    \tfont-size: 0.8em;
    \tletter-spacing: 0.15em;
    \ttext-transform: uppercase;
    }

    /* Front and back matter */
    .copyright {
    \tfont-size: 0.8em;
    \tmargin-top: 40%;
    }

    .copyright p {
    \tmargin-bottom: 0.8em;
    }

    .dedication {
    \tfont-style: italic;
    \ttext-align: center;
    \tmargin-top: 30%;
    }

    .epigraph {
    \tmargin: 30% 2em 0 2em;
    }

    .epigraph blockquote {
    \tfont-style: italic;
    \tmargin: 0;
    }

    .epigraph .attribution {
    \ttext-align: right;
    \tmargin-top: 1em;
    }

    .matter p {
    \tmargin-bottom: 0.8em;
    \ttext-indent: 0;
    }

    .also-by ul {
    \tlist-style: none;
    \tpadding: 0;
    \ttext-align: center;
    }

    .also-by li {
    \tmargin: 0.5em 0;
    \tfont-style: italic;
    }

    /* Table of contents */
    nav.toc ol {
    \tlist-style: none;
    \tpadding: 0;
    \tmargin: 0;
    }

    nav.toc li {
    \tmargin: 0.6em 0;
    }

    nav.toc ol ol {
    \tpadding-left: 1.2em;
    \tfont-size: 0.9em;
    }

    nav.toc a {
    \tcolor: inherit;
    \ttext-decoration: none;
    }
    """
}
