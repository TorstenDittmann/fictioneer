import Foundation

nonisolated enum AnalysisType: String, CaseIterable, Codable, Sendable {
    case adverb
    case passiveVoice = "passive_voice"
    case filterWord = "filter_word"
    case repetition
    case weakVerb = "weak_verb"
    case longSentence = "long_sentence"
    case sentenceStarter = "sentence_starter"
    case cliche
    case vagueWord = "vague_word"

    var label: String {
        switch self {
        case .adverb: "Adverbs"
        case .passiveVoice: "Passive Voice"
        case .filterWord: "Filter Words"
        case .repetition: "Repetition"
        case .weakVerb: "Weak Verbs"
        case .longSentence: "Long Sentences"
        case .sentenceStarter: "Repetitive Starters"
        case .cliche: "Clichés"
        case .vagueWord: "Vague Words"
        }
    }
}

nonisolated enum AnalysisSeverity: Int, Comparable, Sendable {
    case error = 0
    case warning = 1
    case info = 2

    static func < (lhs: AnalysisSeverity, rhs: AnalysisSeverity) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

/// One detected issue with a real UTF-16 range into the analyzed plain text.
nonisolated struct AnalysisHighlight: Sendable, Equatable {
    var type: AnalysisType
    var severity: AnalysisSeverity
    var start: Int
    var end: Int
    var message: String
    var suggestion: String?

    var range: NSRange {
        NSRange(location: start, length: end - start)
    }
}

nonisolated struct ReadabilityScores: Sendable, Equatable {
    var fleschReadingEase: Double
    var fleschKincaidGrade: Double
    var automatedReadabilityIndex: Double
    var level: String
    var interpretation: String
}

nonisolated struct SentenceStats: Sendable, Equatable {
    var count: Int
    var averageLength: Double
    var varietyScore: Int
    var tooLongCount: Int
    var tooShortCount: Int
}

nonisolated struct SentenceStarterStats: Sendable, Equatable {
    var varietyScore: Int
    var mostCommon: String
}

nonisolated struct ProseMetrics: Sendable, Equatable {
    var adverbPercentage: Double
    var passiveVoicePercentage: Double
    var filterWordCount: Int
    var weakVerbCount: Int
    var clicheCount: Int
    var vagueWordCount: Int
    var dialoguePercentage: Int
    var sentenceVariety: Int
}

nonisolated struct AnalysisIssue: Sendable, Equatable {
    var type: AnalysisType
    var severity: AnalysisSeverity
    var message: String
    var count: Int
}

nonisolated struct AnalysisResult: Sendable, Equatable {
    var wordCount: Int
    var characterCount: Int
    var readability: ReadabilityScores
    var sentences: SentenceStats
    var starters: SentenceStarterStats
    var metrics: ProseMetrics
    var highlights: [AnalysisHighlight]
    var overallScore: Int
    var summary: String
    var topIssues: [AnalysisIssue]
    /// Hash of the analyzed text; the highlighter refuses to apply stale results.
    var contentHash: Int
}

nonisolated struct AnalysisConfig: Sendable {
    var maxSentenceLength = 30
    var maxAdverbPercentage = 1.5
    var maxPassivePercentage = 10.0
    var repetitionDistance = 50
    var repetitionMinWordLength = 5
    var enableClicheDetection = true
    var enableVagueWordDetection = true

    static let `default` = AnalysisConfig()
}
