import SwiftUI

/// The Manuscript design language: letterspaced small-caps serif labels,
/// Roman chapter numerals, and TOC leader dots.

extension Color {
    /// Static brand indigo (#6366F1) for ink moments — never the dynamic
    /// accent provider (tinting AppKit controls with the asset-catalog accent
    /// crashes on macOS 26; see ProgressBar).
    static let manuscriptIndigo = Color(red: 0x63 / 255, green: 0x66 / 255, blue: 0xF1 / 255)
}

nonisolated enum RomanNumeral {
    private static let values: [(Int, String)] = [
        (1000, "M"), (900, "CM"), (500, "D"), (400, "CD"),
        (100, "C"), (90, "XC"), (50, "L"), (40, "XL"),
        (10, "X"), (9, "IX"), (5, "V"), (4, "IV"), (1, "I"),
    ]

    static func format(_ number: Int) -> String {
        guard number > 0 else { return "" }
        var remainder = number
        var result = ""
        for (value, symbol) in values {
            while remainder >= value {
                result += symbol
                remainder -= value
            }
        }
        return result
    }
}

nonisolated enum ManuscriptTitle {
    /// Strips a leading numbering prefix ("1.", "II —", "3)") from a title so
    /// it doesn't read twice next to a rendered numeral column.
    static func strippingNumbering(_ title: String) -> String {
        guard let match = title.wholeMatch(of: #/\s*(?:\d+|[IVXLCDM]+)\s*[.:)\-–—]\s*(\S.*)/#) else {
            return title
        }
        return String(match.1)
    }
}

/// Letterspaced uppercase Quattrocento label — the manuscript's structural voice.
struct ManuscriptLabel: View {
    let text: String
    var size: CGFloat = 11
    var color: Color = .secondary

    init(_ text: String, size: CGFloat = 11, color: Color = .secondary) {
        self.text = text
        self.size = size
        self.color = color
    }

    var body: some View {
        Text(text.uppercased())
            .font(.custom("Quattrocento-Bold", size: size))
            .tracking(size * 0.14)
            .foregroundStyle(color)
            .lineLimit(1)
    }
}

/// Dotted baseline filler between a TOC entry and its word count.
struct LeaderDots: View {
    var body: some View {
        GeometryReader { geometry in
            Path { path in
                path.move(to: CGPoint(x: 0, y: geometry.size.height - 3))
                path.addLine(to: CGPoint(x: geometry.size.width, y: geometry.size.height - 3))
            }
            .stroke(style: StrokeStyle(lineWidth: 1, dash: [1, 3]))
            .foregroundStyle(.quaternary)
        }
        .frame(minWidth: 12)
    }
}
