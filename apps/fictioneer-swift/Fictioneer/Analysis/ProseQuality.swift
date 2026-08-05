import Foundation

nonisolated struct AdverbMatch: Sendable {
    var word: String
    var position: Int
}

nonisolated struct PassiveVoiceMatch: Sendable {
    var phrase: String
    var position: Int
}

nonisolated struct PositionedMatch: Sendable {
    var word: String
    var position: Int
}

/// Port of text_analysis/prose_quality.ts (inline word lists — the module-level
/// word_lists.ts in the Tauri app is dead code).
nonisolated enum ProseQuality {
    static let lyExceptions: Set<String> = [
        "only", "early", "daily", "weekly", "monthly", "yearly", "holy", "lonely",
        "lovely", "ugly", "likely", "unlikely", "friendly", "family", "elderly",
        "orderly", "silly", "belly", "bully", "jelly", "jolly", "folly", "rally",
        "tally", "valley", "alley", "trolley", "volley", "pulley", "gully", "fully",
        "hilly", "chilly", "frilly", "smelly", "wooly", "curly", "burly", "surly",
        "pearly", "gnarly", "snarky", "italy", "assembly", "butterfly", "dragonfly",
        "firefly", "fly", "july", "reply", "supply", "apply", "multiply", "comply",
        "imply", "rely",
    ]

    static let nonLyAdverbs = [
        "very", "really", "quite", "rather", "almost", "already", "also", "always",
        "never", "ever", "often", "seldom", "sometimes", "soon", "still", "yet",
        "just", "even", "too", "well", "fast", "hard", "late", "near", "far",
        "long", "low", "high", "straight", "right", "wrong", "much", "little",
        "enough", "anywhere", "everywhere", "nowhere", "somewhere", "somehow",
        "anyway", "perhaps", "maybe",
    ]

    static let passiveIndicators = [
        "was", "were", "is", "are", "been", "being", "be", "am", "get", "gets",
        "got", "getting",
    ]

    static let irregularPastParticiples: Set<String> = [
        "been", "done", "gone", "seen", "taken", "given", "known", "made", "found",
        "told", "left", "felt", "brought", "thought", "bought", "caught", "taught",
        "sought", "written", "driven", "eaten", "fallen", "forgotten", "chosen",
        "spoken", "stolen", "broken", "frozen", "hidden", "bitten", "beaten",
        "shaken", "woken", "worn", "torn", "sworn", "born", "borne", "drawn",
        "grown", "shown", "thrown", "blown", "flown", "slain", "lain", "paid",
        "said", "sent", "spent", "built", "burnt", "dealt", "dreamt", "dwelt",
        "kept", "knelt", "leant", "leapt", "learnt", "meant", "slept", "smelt",
        "spelt", "spilt", "swept", "wept", "lost", "shot", "hurt", "cut", "put",
        "shut", "hit", "let", "set", "rid", "spread", "read", "held", "hung",
        "dug", "stuck", "struck", "stung", "swung", "clung", "flung", "slung",
        "sprung", "sung", "rung", "begun", "drunk", "shrunk", "sunk", "swum",
        "run", "won",
    ]

    static let filterWords = [
        "just", "really", "very", "quite", "rather", "somewhat", "actually",
        "basically", "literally", "simply", "totally", "completely", "absolutely",
        "definitely", "certainly", "probably", "possibly", "maybe", "perhaps",
        "almost", "nearly", "hardly", "barely", "slightly", "kind of", "sort of",
        "a bit", "a little", "in order to", "start to", "begin to", "seem to",
        "appear to", "tend to",
    ]

    static let cliches = [
        "it was a dark and stormy night", "once upon a time", "in the nick of time",
        "all of a sudden", "at the end of the day", "the fact of the matter",
        "when all was said and done", "for all intents and purposes",
        "each and every", "first and foremost", "few and far between",
        "last but not least", "time will tell", "only time will tell",
        "easier said than done", "better late than never",
        "actions speak louder than words", "a needle in a haystack",
        "avoid like the plague", "beat around the bush", "bite the bullet",
        "break the ice", "burning the midnight oil", "crystal clear",
        "dead as a doornail", "fit as a fiddle", "heart of gold",
        "in the blink of an eye", "let the cat out of the bag",
        "once in a blue moon", "read between the lines", "scared to death",
        "sick and tired", "think outside the box", "tip of the iceberg",
        "under the weather", "white as a ghost", "white as a sheet",
        "her heart skipped a beat", "his heart pounded",
        "butterflies in her stomach", "a chill ran down his spine",
        "goosebumps rose on her skin",
        "he let out a breath he didn't know he was holding",
        "she let out a breath she didn't know she was holding",
        "time stood still", "the world fell away", "his blood ran cold",
        "her blood ran cold",
    ]

    static let vagueWords = [
        "thing", "things", "stuff", "something", "anything", "everything",
        "nothing", "someone", "anyone", "everyone", "somewhere", "anywhere",
        "everywhere", "somehow", "anyway", "whatever", "whenever", "wherever",
        "nice", "good", "bad", "big", "small", "great", "interesting", "beautiful",
        "ugly", "amazing", "awesome", "terrible", "horrible", "wonderful",
        "fantastic", "incredible",
    ]

    private static let lyRegex = try! NSRegularExpression(
        pattern: "\\b(\\w+ly)\\b", options: [.caseInsensitive]
    )

    // Word-list regexes are constant — compile each exactly once instead of
    // per sentence per pass (~55 compiles × sentences added up fast).
    private static func wordRegexes(_ words: [String]) -> [(word: String, regex: NSRegularExpression)] {
        words.compactMap { word in
            let pattern = "\\b" + NSRegularExpression.escapedPattern(for: word) + "\\b"
            guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else { return nil }
            return (word, regex)
        }
    }

    private static let nonLyAdverbRegexes = wordRegexes(nonLyAdverbs)
    private static let filterWordRegexes = wordRegexes(filterWords)
    private static let vagueWordRegexes = wordRegexes(vagueWords)
    private static let passiveIndicatorRegexes: [NSRegularExpression] = passiveIndicators.compactMap { auxiliary in
        try? NSRegularExpression(
            pattern: "\\b(\(auxiliary))\\s+(\\w+ly\\s+)?(\\w+)\\b",
            options: [.caseInsensitive]
        )
    }
    private static let clicheRegexes: [(word: String, regex: NSRegularExpression)] = cliches.compactMap { cliche in
        let pattern = NSRegularExpression.escapedPattern(for: cliche)
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else { return nil }
        return (cliche, regex)
    }

    // MARK: - Detection

    static func detectAdverbs(_ text: String, sentences: [SentenceInfo]) -> [AdverbMatch] {
        var results: [AdverbMatch] = []
        let ns = text as NSString
        for sentence in sentences {
            let sentenceRange = NSRange(location: sentence.start, length: sentence.end - sentence.start)
            for match in lyRegex.matches(in: text, range: sentenceRange) {
                let word = ns.substring(with: match.range).lowercased()
                if !lyExceptions.contains(word) {
                    results.append(AdverbMatch(word: word, position: match.range.location))
                }
            }
            for (adverb, regex) in nonLyAdverbRegexes {
                for match in regex.matches(in: text, range: sentenceRange) {
                    results.append(AdverbMatch(word: adverb, position: match.range.location))
                }
            }
        }
        return results
    }

    static func detectPassiveVoice(_ text: String, sentences: [SentenceInfo]) -> [PassiveVoiceMatch] {
        var results: [PassiveVoiceMatch] = []
        let ns = text as NSString
        for sentence in sentences {
            let sentenceRange = NSRange(location: sentence.start, length: sentence.end - sentence.start)
            for regex in passiveIndicatorRegexes {
                for match in regex.matches(in: text, range: sentenceRange) {
                    let candidate = ns.substring(with: match.range(at: 3))
                    if isPastParticiple(candidate) {
                        let phrase = ns.substring(with: match.range)
                            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
                            .trimmingCharacters(in: .whitespaces)
                        results.append(PassiveVoiceMatch(phrase: phrase, position: match.range.location))
                    }
                }
            }
        }
        return results
    }

    static func isPastParticiple(_ word: String) -> Bool {
        let lower = word.lowercased()
        if irregularPastParticiples.contains(lower) { return true }
        if lower.hasSuffix("ed"), lower.count > 3 { return true }
        if lower.hasSuffix("en"), lower.count > 3 { return true }
        return false
    }

    // Matching runs on the ORIGINAL text (the regexes are case-insensitive
    // already): lowercasing can change UTF-16 length (e.g. İ), which would
    // misalign every highlight range computed afterwards.

    static func detectFilterWords(_ text: String) -> [PositionedMatch] {
        let ns = text as NSString
        var results: [PositionedMatch] = []
        for (filter, regex) in filterWordRegexes {
            for match in regex.matches(in: text, range: NSRange(location: 0, length: ns.length)) {
                results.append(PositionedMatch(word: filter, position: match.range.location))
            }
        }
        return results.sorted { $0.position < $1.position }
    }

    static func detectCliches(_ text: String) -> [PositionedMatch] {
        let ns = text as NSString
        var results: [PositionedMatch] = []
        for (cliche, regex) in clicheRegexes {
            for match in regex.matches(in: text, range: NSRange(location: 0, length: ns.length)) {
                results.append(PositionedMatch(word: cliche, position: match.range.location))
            }
        }
        return results.sorted { $0.position < $1.position }
    }

    static func detectVagueWords(_ text: String) -> [PositionedMatch] {
        let ns = text as NSString
        var results: [PositionedMatch] = []
        for (_, regex) in vagueWordRegexes {
            for match in regex.matches(in: text, range: NSRange(location: 0, length: ns.length)) {
                results.append(PositionedMatch(word: ns.substring(with: match.range), position: match.range.location))
            }
        }
        return results.sorted { $0.position < $1.position }
    }

    // MARK: - Highlights

    static func highlights(
        adverbs: [AdverbMatch],
        passives: [PassiveVoiceMatch],
        filters: [PositionedMatch],
        cliches clicheMatches: [PositionedMatch],
        vagues: [PositionedMatch],
        config: AnalysisConfig
    ) -> [AnalysisHighlight] {
        var result: [AnalysisHighlight] = []
        for match in adverbs {
            result.append(AnalysisHighlight(
                type: .adverb, severity: .info,
                start: match.position, end: match.position + (match.word as NSString).length,
                message: "Adverb: \"\(match.word)\" - Consider using a stronger verb instead",
                suggestion: "Try replacing with a more specific verb"
            ))
        }
        for match in passives {
            result.append(AnalysisHighlight(
                type: .passiveVoice, severity: .warning,
                start: match.position, end: match.position + (match.phrase as NSString).length,
                message: "Passive voice: \"\(match.phrase)\" - Active voice is often stronger",
                suggestion: "Consider rewriting in active voice"
            ))
        }
        for match in filters {
            result.append(AnalysisHighlight(
                type: .filterWord, severity: .info,
                start: match.position, end: match.position + (match.word as NSString).length,
                message: "Filter word: \"\(match.word)\" - Often unnecessary and weakens prose",
                suggestion: "Consider removing or finding a stronger alternative"
            ))
        }
        if config.enableClicheDetection {
            for match in clicheMatches {
                result.append(AnalysisHighlight(
                    type: .cliche, severity: .warning,
                    start: match.position, end: match.position + (match.word as NSString).length,
                    message: "Cliché: \"\(match.word)\" - Consider a more original expression",
                    suggestion: "Try expressing this idea in your own unique way"
                ))
            }
        }
        if config.enableVagueWordDetection {
            for match in vagues {
                result.append(AnalysisHighlight(
                    type: .vagueWord, severity: .info,
                    start: match.position, end: match.position + (match.word as NSString).length,
                    message: "Vague word: \"\(match.word)\" - Could be more specific",
                    suggestion: "Consider using a more precise word"
                ))
            }
        }
        return result.sorted { $0.start < $1.start }
    }
}
