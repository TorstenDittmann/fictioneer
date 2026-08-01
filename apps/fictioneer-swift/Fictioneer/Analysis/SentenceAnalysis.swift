import Foundation

nonisolated struct SentenceInfo: Sendable {
    var text: String
    var start: Int
    var end: Int
    var wordCount: Int
    var firstWord: String
}

/// Port of text_analysis/sentence_analysis.ts.
nonisolated enum SentenceAnalysis {
    static func parseSentences(_ text: String) -> [SentenceInfo] {
        let ns = text as NSString
        var result: [SentenceInfo] = []
        var searchPosition = 0
        for sentence in Readability.splitIntoSentences(text) {
            let searchRange = NSRange(location: searchPosition, length: ns.length - searchPosition)
            let found = ns.range(of: sentence, options: [.literal], range: searchRange)
            guard found.location != NSNotFound else { continue }
            let words = SyllableCounter.extractWords(sentence)
            result.append(SentenceInfo(
                text: sentence,
                start: found.location,
                end: found.location + found.length,
                wordCount: words.count,
                firstWord: words.first?.lowercased() ?? ""
            ))
            searchPosition = found.location + found.length
        }
        return result
    }

    static func stats(for sentences: [SentenceInfo]) -> SentenceStats {
        guard !sentences.isEmpty else {
            return SentenceStats(count: 0, averageLength: 0, varietyScore: 0, tooLongCount: 0, tooShortCount: 0)
        }
        let lengths = sentences.map(\.wordCount)
        let total = lengths.reduce(0, +)
        let average = (Double(total) / Double(lengths.count) * 10).rounded() / 10
        return SentenceStats(
            count: sentences.count,
            averageLength: average,
            varietyScore: varietyScore(lengths: lengths),
            tooLongCount: lengths.count { $0 > 30 },
            tooShortCount: lengths.count { $0 < 5 && $0 > 0 }
        )
    }

    static func varietyScore(lengths: [Int]) -> Int {
        guard lengths.count >= 3 else { return 50 }
        let mean = Double(lengths.reduce(0, +)) / Double(lengths.count)
        let variance = lengths.reduce(0.0) { $0 + pow(Double($1) - mean, 2) } / Double(lengths.count)
        let standardDeviation = variance.squareRoot()
        return Int(max(0, 100 - abs(standardDeviation - 7) * 10).rounded())
    }

    static func starterStats(for sentences: [SentenceInfo]) -> SentenceStarterStats {
        guard !sentences.isEmpty else {
            return SentenceStarterStats(varietyScore: 0, mostCommon: "")
        }
        var counts: [String: Int] = [:]
        var order: [String] = []
        for sentence in sentences where !sentence.firstWord.isEmpty {
            if counts[sentence.firstWord] == nil { order.append(sentence.firstWord) }
            counts[sentence.firstWord, default: 0] += 1
        }
        let mostCommon = order.max { (counts[$0] ?? 0) < (counts[$1] ?? 0) } ?? ""
        let variety = Int(min(100, Double(counts.count) / Double(sentences.count) * 100).rounded())
        return SentenceStarterStats(varietyScore: variety, mostCommon: mostCommon)
    }

    static func highlights(for sentences: [SentenceInfo], config: AnalysisConfig) -> [AnalysisHighlight] {
        var result: [AnalysisHighlight] = []
        for sentence in sentences where sentence.wordCount > config.maxSentenceLength {
            result.append(AnalysisHighlight(
                type: .longSentence,
                severity: .warning,
                start: sentence.start,
                end: sentence.end,
                message: "Long sentence (\(sentence.wordCount) words) - Consider breaking into smaller sentences",
                suggestion: "Look for natural break points like conjunctions (and, but, or)"
            ))
        }
        // Runs of >= 3 consecutive sentences sharing a first word.
        var index = 0
        while index < sentences.count {
            let word = sentences[index].firstWord
            var runEnd = index
            while runEnd + 1 < sentences.count, !word.isEmpty, sentences[runEnd + 1].firstWord == word {
                runEnd += 1
            }
            let runLength = runEnd - index + 1
            if runLength >= 3, !word.isEmpty {
                for sentence in sentences[index...runEnd] {
                    result.append(AnalysisHighlight(
                        type: .sentenceStarter,
                        severity: .info,
                        start: sentence.start,
                        end: sentence.start + (word as NSString).length,
                        message: "\(runLength) consecutive sentences start with \"\(word)\"",
                        suggestion: "Vary your sentence openings for better flow"
                    ))
                }
            }
            index = runEnd + 1
        }
        return result
    }

    /// Dialogue percentage. Deliberate fix over Tauri: its "smart quote"
    /// patterns were ASCII duplicates, double-counting every quoted span.
    /// Here each span counts once, and real smart quotes are supported.
    static func dialoguePercentage(_ text: String) -> Int {
        let patterns = [
            "\"[^\"]*\"",
            "\u{201C}[^\u{201D}]*\u{201D}",
        ]
        let ns = text as NSString
        var dialogueCharacters = 0
        for pattern in patterns {
            guard let regex = try? NSRegularExpression(pattern: pattern) else { continue }
            for match in regex.matches(in: text, range: NSRange(location: 0, length: ns.length)) {
                dialogueCharacters += max(0, match.range.length - 2)
            }
        }
        let totalCharacters = text.unicodeScalars.filter { !CharacterSet.whitespacesAndNewlines.contains($0) }.count
        guard totalCharacters > 0 else { return 0 }
        return Int((Double(dialogueCharacters) / Double(totalCharacters) * 100).rounded())
    }
}
