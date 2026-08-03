import SwiftUI

/// The Manuscript design language: letterspaced small-caps serif labels,
/// Roman chapter numerals, and TOC leader dots.

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
