import Foundation

/// A project's quotation marks. Typing `"` or `'` in the editor inserts the
/// style's opening or closing mark from context, and "Convert Quotes"
/// normalizes existing text — so a manuscript never mixes “…”, „…“ and "…".
nonisolated enum QuoteStyle: String, Codable, CaseIterable, Identifiable, Sendable {
    case english
    case german
    case french
    case straight

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .english: "English  “…” ‘…’"
        case .german: "German  „…“ ‚…‘"
        case .french: "French  «…» ‹…›"
        case .straight: "Straight  \"…\" '…'"
        }
    }

    var doubleOpen: Character {
        switch self {
        case .english: "\u{201C}"
        case .german: "\u{201E}"
        case .french: "\u{00AB}"
        case .straight: "\""
        }
    }

    var doubleClose: Character {
        switch self {
        case .english: "\u{201D}"
        case .german: "\u{201C}"
        case .french: "\u{00BB}"
        case .straight: "\""
        }
    }

    var singleOpen: Character {
        switch self {
        case .english: "\u{2018}"
        case .german: "\u{201A}"
        case .french: "\u{2039}"
        case .straight: "'"
        }
    }

    var singleClose: Character {
        switch self {
        case .english: "\u{2019}"
        case .german: "\u{2018}"
        case .french: "\u{203A}"
        case .straight: "'"
        }
    }

    /// The apostrophe inside words (don't, Holmes’) is ’ in every curly style.
    var apostrophe: Character {
        self == .straight ? "'" : "\u{2019}"
    }

    /// The default for projects that never picked one: the writer's language.
    static func defaultStyle(for locale: Locale = .current) -> QuoteStyle {
        switch locale.language.languageCode?.identifier {
        case "de": .german
        case "fr": .french
        default: .english
        }
    }

    // MARK: - Context rules

    static let doubleQuoteCharacters: Set<Character> = ["\"", "\u{201C}", "\u{201D}", "\u{201E}", "\u{00AB}", "\u{00BB}"]
    static let singleQuoteCharacters: Set<Character> = ["'", "\u{2018}", "\u{2019}", "\u{201A}", "\u{2039}", "\u{203A}"]

    /// A quote opens at the start of text or after whitespace, an opening
    /// bracket, a dash, or another opening quote.
    private static func opens(after previous: Character?) -> Bool {
        guard let previous else { return true }
        if previous.isWhitespace || previous.isNewline { return true }
        return "([{\u{2014}\u{2013}\u{201C}\u{201E}\u{00AB}\u{2018}\u{201A}\u{2039}".contains(previous)
    }

    /// The mark to insert for a typed `"` or `'` given its neighbors, or nil
    /// when `typed` isn't a quote key.
    func mark(forTyped typed: Character, after previous: Character?, before next: Character? = nil) -> Character? {
        if typed == "\"" {
            return Self.opens(after: previous) ? doubleOpen : doubleClose
        }
        if typed == "'" {
            if let previous, previous.isLetter || previous.isNumber {
                // Between letters it's an apostrophe; after a word it closes.
                if let next, next.isLetter { return apostrophe }
                return next == nil ? apostrophe : singleClose
            }
            return Self.opens(after: previous) ? singleOpen : singleClose
        }
        return nil
    }

    /// Rewrites every quotation mark in `text` in this style, keeping the
    /// UTF-16 length unchanged (each mark is one code unit) so attributed
    /// text can be converted in place.
    func convert(_ text: String) -> String {
        let characters = Array(text)
        var result = characters
        for index in characters.indices {
            let character = characters[index]
            let previous = index > 0 ? characters[index - 1] : nil
            // The end of the text is a known boundary here (unlike while
            // typing), so a final mark after a word closes a quote rather
            // than being an apostrophe.
            let next: Character = index + 1 < characters.count ? characters[index + 1] : " "
            if Self.doubleQuoteCharacters.contains(character) {
                result[index] = mark(forTyped: "\"", after: previous, before: next) ?? character
            } else if Self.singleQuoteCharacters.contains(character) {
                result[index] = mark(forTyped: "'", after: previous, before: next) ?? character
            }
        }
        return String(result)
    }
}
