import Foundation

nonisolated struct WordRepetition: Sendable {
    var word: String
    var positions: [Int]
    var distance: Int
}

nonisolated struct WeakVerbMatch: Sendable {
    var verb: String
    var position: Int
}

/// Port of text_analysis/word_analysis.ts.
nonisolated enum WordAnalysis {
    static let weakVerbs: Set<String> = [
        "was", "were", "is", "are", "am", "be", "been", "being", "had", "has",
        "have", "do", "does", "did", "got", "get", "gets", "getting", "went",
        "go", "goes", "going", "came", "come", "comes", "coming", "made", "make",
        "makes", "making", "put", "puts", "putting", "took", "take", "takes",
        "taking", "felt", "feel", "feels", "feeling", "seemed", "seem", "seems",
        "seeming", "looked", "look", "looks", "looking", "said", "say", "says",
        "saying",
    ]

    static let commonWords: Set<String> = [
        "a", "an", "the", "i", "me", "my", "mine", "myself", "you", "your",
        "yours", "yourself", "he", "him", "his", "himself", "she", "her", "hers",
        "herself", "it", "its", "itself", "we", "us", "our", "ours", "ourselves",
        "they", "them", "their", "theirs", "themselves", "who", "whom", "whose",
        "which", "what", "that", "this", "these", "those", "in", "on", "at", "to",
        "for", "of", "with", "by", "from", "up", "down", "into", "out", "over",
        "under", "through", "between", "after", "before", "about", "around",
        "against", "among", "and", "or", "but", "nor", "so", "yet", "if", "then",
        "than", "when", "while", "as", "because", "although", "though", "unless",
        "until", "since", "was", "were", "is", "are", "am", "be", "been", "being",
        "had", "has", "have", "do", "does", "did", "would", "could", "should",
        "might", "must", "will", "shall", "can", "may", "not", "no", "yes", "all",
        "some", "any", "each", "every", "both", "few", "more", "most", "other",
        "such", "only", "just", "also", "very", "too", "even", "still", "again",
        "now", "here", "there", "where", "how", "why", "said", "like",
    ]

    private static let positionedWordRegex = try! NSRegularExpression(
        pattern: "\\b([a-zA-Z]+(?:'[a-zA-Z]+)?)\\b"
    )

    struct Occurrence {
        var word: String
        var position: Int
        var wordIndex: Int
    }

    static func wordsWithPositions(_ text: String) -> [Occurrence] {
        let ns = text as NSString
        return positionedWordRegex
            .matches(in: text, range: NSRange(location: 0, length: ns.length))
            .enumerated()
            .map { index, match in
                Occurrence(
                    word: ns.substring(with: match.range).lowercased(),
                    position: match.range.location,
                    wordIndex: index
                )
            }
    }

    static func detectRepetitions(_ text: String, config: AnalysisConfig) -> [WordRepetition] {
        var repetitions: [WordRepetition] = []
        var recent: [String: [Occurrence]] = [:]

        for occurrence in wordsWithPositions(text) {
            let word = occurrence.word
            if word.count >= config.repetitionMinWordLength, !commonWords.contains(word) {
                for previous in recent[word] ?? [] {
                    let gap = occurrence.wordIndex - previous.wordIndex
                    guard gap > 0, gap <= config.repetitionDistance else { continue }
                    if let index = repetitions.firstIndex(where: {
                        $0.word == word && $0.positions.contains(previous.position)
                    }) {
                        if !repetitions[index].positions.contains(occurrence.position) {
                            repetitions[index].positions.append(occurrence.position)
                        }
                    } else {
                        repetitions.append(WordRepetition(
                            word: word,
                            positions: [previous.position, occurrence.position],
                            distance: gap
                        ))
                    }
                }
                recent[word, default: []].append(occurrence)
            }
            // Prune everything outside the window.
            for key in recent.keys {
                recent[key]?.removeAll { occurrence.wordIndex - $0.wordIndex > config.repetitionDistance }
                if recent[key]?.isEmpty == true {
                    recent.removeValue(forKey: key)
                }
            }
        }
        return repetitions
    }

    static func detectWeakVerbs(_ text: String) -> [WeakVerbMatch] {
        wordsWithPositions(text)
            .filter { weakVerbs.contains($0.word) }
            .map { WeakVerbMatch(verb: $0.word, position: $0.position) }
    }

    static func highlights(_ text: String, config: AnalysisConfig) -> [AnalysisHighlight] {
        var result: [AnalysisHighlight] = []
        for repetition in detectRepetitions(text, config: config) {
            for (index, position) in repetition.positions.enumerated() {
                let message = index == 0
                    ? "\"\(repetition.word)\" appears again within \(repetition.distance) words"
                    : "Repeated word: \"\(repetition.word)\" - \(repetition.distance) words from previous use"
                result.append(AnalysisHighlight(
                    type: .repetition, severity: .info,
                    start: position, end: position + (repetition.word as NSString).length,
                    message: message,
                    suggestion: "Consider using a synonym or restructuring the sentence"
                ))
            }
        }
        let weak = detectWeakVerbs(text)
        let totalWords = SyllableCounter.extractWords(text).count
        if totalWords > 0, Double(weak.count) / Double(totalWords) * 100 > 15 {
            var index = 0
            while index < weak.count {
                let match = weak[index]
                result.append(AnalysisHighlight(
                    type: .weakVerb, severity: .info,
                    start: match.position, end: match.position + (match.verb as NSString).length,
                    message: "Weak verb \"\(match.verb)\" - Consider using a more specific action verb",
                    suggestion: "Replace with a stronger, more descriptive verb"
                ))
                index += 3
            }
        }
        return result
    }
}
