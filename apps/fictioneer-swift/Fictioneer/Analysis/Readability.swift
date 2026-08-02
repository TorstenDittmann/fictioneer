import Foundation

/// Port of text_analysis/readability.ts.
nonisolated enum Readability {
    private static let abbreviations = [
        "Mr", "Mrs", "Ms", "Dr", "Prof", "Sr", "Jr", "vs", "etc", "i.e", "e.g",
        "St", "Lt", "Gen", "Col", "Sgt", "Rev", "Inc", "Ltd", "Corp", "Co",
        "No", "Vol", "Ch", "Pg", "Fig",
    ]
    private static let boundaryRegex = try! NSRegularExpression(
        pattern: "([.!?]+)\\s+(?=[A-Z])|([.!?]+)\\s*$"
    )

    /// Sentence splitting matching the JS pipeline. Returned sentences are
    /// trimmed and lack their terminal punctuation.
    static func splitIntoSentences(_ text: String) -> [String] {
        // Newlines are hard sentence boundaries. Deliberate improvement over
        // the Tauri engine, which merged unpunctuated paragraphs into one
        // giant "sentence" and flagged false long-sentence issues across
        // paragraph breaks.
        text.split(omittingEmptySubsequences: true, whereSeparator: \.isNewline)
            .flatMap { splitSegmentIntoSentences(String($0)) }
    }

    private static func splitSegmentIntoSentences(_ text: String) -> [String] {
        var working = text
        for abbr in abbreviations {
            let pattern = "\\b" + NSRegularExpression.escapedPattern(for: abbr) + "\\."
            if let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) {
                let range = NSRange(location: 0, length: (working as NSString).length)
                working = regex.stringByReplacingMatches(
                    in: working, range: range, withTemplate: NSRegularExpression.escapedTemplate(for: abbr) + "<<<DOT>>>"
                )
            }
        }
        if let decimals = try? NSRegularExpression(pattern: "(\\d)\\.(\\d)") {
            let range = NSRange(location: 0, length: (working as NSString).length)
            working = decimals.stringByReplacingMatches(in: working, range: range, withTemplate: "$1<<<DOT>>>$2")
        }
        working = working.replacingOccurrences(of: "...", with: "<<<ELLIPSIS>>>")

        let ns = working as NSString
        var segments: [String] = []
        var cursor = 0
        for match in boundaryRegex.matches(in: working, range: NSRange(location: 0, length: ns.length)) {
            if match.range.location > cursor {
                segments.append(ns.substring(with: NSRange(location: cursor, length: match.range.location - cursor)))
            }
            cursor = match.range.location + match.range.length
        }
        if cursor < ns.length {
            segments.append(ns.substring(from: cursor))
        }

        return segments
            .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            .map {
                $0.replacingOccurrences(of: "<<<DOT>>>", with: ".")
                    .replacingOccurrences(of: "<<<ELLIPSIS>>>", with: "...")
                    .trimmingCharacters(in: .whitespacesAndNewlines)
            }
            .filter { trimmed in
                !trimmed.allSatisfy { ".!?".contains($0) }
            }
    }

    static func scores(for text: String) -> ReadabilityScores {
        let words = SyllableCounter.extractWords(text)
        let wordCount = Double(words.count)
        let sentenceCount = Double(max(1, splitIntoSentences(text).count))
        let syllables = Double(SyllableCounter.countTotalSyllables(text))
        let letterCount = Double(words.reduce(0) { $0 + $1.count })

        func round1(_ value: Double) -> Double {
            (value * 10).rounded() / 10
        }

        var fre = 0.0
        var fkg = 0.0
        var ari = 0.0
        if wordCount > 0 {
            fre = 206.835 - 1.015 * (wordCount / sentenceCount) - 84.6 * (syllables / wordCount)
            fre = round1(min(100, max(0, fre)))
            fkg = max(0, round1(0.39 * (wordCount / sentenceCount) + 11.8 * (syllables / wordCount) - 15.59))
            ari = max(0, round1(4.71 * (letterCount / wordCount) + 0.5 * (wordCount / sentenceCount) - 21.43))
        }

        return ReadabilityScores(
            fleschReadingEase: fre,
            fleschKincaidGrade: fkg,
            automatedReadabilityIndex: ari,
            level: level(for: fre),
            interpretation: interpretation(fre: fre, grade: fkg)
        )
    }

    static func level(for fre: Double) -> String {
        switch fre {
        case 80...: "very_easy"
        case 60...: "easy"
        case 40...: "moderate"
        case 20...: "difficult"
        default: "very_difficult"
        }
    }

    static func interpretation(fre: Double, grade: Double) -> String {
        let gradeText: String
        if grade <= 5 {
            gradeText = "5th grade or below"
        } else if grade <= 8 {
            gradeText = "\(Int(grade.rounded()))th grade"
        } else if grade <= 12 {
            gradeText = "\(Int(grade.rounded()))th grade (high school)"
        } else {
            gradeText = "college level"
        }
        switch fre {
        case 80...: return "Very easy to read. \(gradeText). Suitable for a wide audience."
        case 60...: return "Easy to read. \(gradeText). Good for most adult fiction."
        case 40...: return "Moderate difficulty. \(gradeText). May challenge some readers."
        case 20...: return "Difficult to read. \(gradeText). Dense prose or complex sentences."
        default: return "Very difficult to read. \(gradeText). Consider simplifying."
        }
    }
}
