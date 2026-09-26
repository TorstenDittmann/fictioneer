import Foundation

/// Port of text_analysis/index.ts `analyze_scene`. Input is plain text
/// (already stripped of transient attributes); all ranges are UTF-16 offsets
/// into exactly that text.
nonisolated enum TextAnalysisEngine {
    /// Deterministic content hash (FNV-1a) used to reject stale results.
    static func contentHash(_ text: String) -> Int {
        var hash: UInt64 = 0xcbf29ce484222325
        for unit in text.utf16 {
            hash ^= UInt64(unit)
            hash = hash &* 0x100000001b3
        }
        return Int(bitPattern: UInt(truncatingIfNeeded: hash))
    }

    static func analyze(_ text: String, config: AnalysisConfig = .default) -> AnalysisResult {
        let words = SyllableCounter.extractWords(text)
        let wordCount = words.count
        let sentences = SentenceAnalysis.parseSentences(text)
        let sentenceStats = SentenceAnalysis.stats(for: sentences)
        let starterStats = SentenceAnalysis.starterStats(for: sentences)
        let readability = Readability.scores(for: text)

        let adverbs = ProseQuality.detectAdverbs(text, sentences: sentences)
        let passives = ProseQuality.detectPassiveVoice(text, sentences: sentences)
        let filters = ProseQuality.detectFilterWords(text)
        let clicheMatches = config.enableClicheDetection ? ProseQuality.detectCliches(text) : []
        let vagues = config.enableVagueWordDetection ? ProseQuality.detectVagueWords(text) : []
        let weakVerbCount = WordAnalysis.detectWeakVerbs(text).count

        let metrics = ProseMetrics(
            adverbPercentage: wordCount > 0 ? Double(adverbs.count) / Double(wordCount) * 100 : 0,
            passiveVoicePercentage: sentences.isEmpty ? 0 : Double(passives.count) / Double(sentences.count) * 100,
            filterWordCount: filters.count,
            weakVerbCount: weakVerbCount,
            clicheCount: clicheMatches.count,
            vagueWordCount: vagues.count,
            dialoguePercentage: SentenceAnalysis.dialoguePercentage(text),
            sentenceVariety: sentenceStats.varietyScore
        )

        let proseHighlights = ProseQuality.highlights(
            adverbs: adverbs, passives: passives, filters: filters,
            cliches: clicheMatches, vagues: vagues, config: config
        )
        let sentenceHighlights = SentenceAnalysis.highlights(for: sentences, config: config)
        let wordHighlights = WordAnalysis.highlights(text, config: config)
        let highlights = (proseHighlights + sentenceHighlights + wordHighlights)
            .sorted { $0.start < $1.start }

        let score = overallScore(
            readability: readability.fleschReadingEase,
            sentenceVariety: Double(sentenceStats.varietyScore),
            starterVariety: Double(starterStats.varietyScore),
            adverbPercentage: metrics.adverbPercentage,
            passivePercentage: metrics.passiveVoicePercentage,
            filterWordCount: metrics.filterWordCount,
            wordCount: wordCount
        )

        let topIssues = self.topIssues(metrics: metrics, highlights: highlights, config: config)
        let summary = self.summary(
            score: score,
            topIssues: topIssues,
            readabilityInterpretation: readability.interpretation
        )

        return AnalysisResult(
            wordCount: wordCount,
            characterCount: (text as NSString).length,
            readability: readability,
            sentences: sentenceStats,
            starters: starterStats,
            metrics: metrics,
            highlights: highlights,
            overallScore: score,
            summary: summary,
            topIssues: topIssues,
            contentHash: contentHash(text)
        )
    }

    /// Exact port of `calculate_overall_score` — 70-based additive formula.
    static func overallScore(
        readability: Double,
        sentenceVariety: Double,
        starterVariety: Double,
        adverbPercentage: Double,
        passivePercentage: Double,
        filterWordCount: Int,
        wordCount: Int
    ) -> Int {
        var score = 70.0
        score += (readability >= 50 && readability <= 80 ? 15 : 10) - 10
        score += (sentenceVariety / 100) * 15 - 7.5
        score += (starterVariety / 100) * 10 - 5
        if adverbPercentage > 2 {
            score -= min(10, (adverbPercentage - 2) * 3)
        }
        if passivePercentage > 15 {
            score -= min(10, (passivePercentage - 15) * 0.5)
        }
        let filterPercentage = Double(filterWordCount) / Double(max(1, wordCount)) * 100
        if filterPercentage > 1 {
            score -= min(5, (filterPercentage - 1) * 2)
        }
        return min(100, max(0, Int(score.rounded())))
    }

    static func topIssues(
        metrics: ProseMetrics,
        highlights: [AnalysisHighlight],
        config: AnalysisConfig
    ) -> [AnalysisIssue] {
        var counts: [AnalysisType: Int] = [:]
        for highlight in highlights {
            counts[highlight.type, default: 0] += 1
        }
        var issues: [AnalysisIssue] = []

        if metrics.adverbPercentage > config.maxAdverbPercentage {
            issues.append(AnalysisIssue(
                type: .adverb,
                severity: metrics.adverbPercentage > 3 ? .warning : .info,
                message: "High adverb density (\(String(format: "%.1f", metrics.adverbPercentage))%)",
                count: counts[.adverb] ?? 0
            ))
        }
        if metrics.passiveVoicePercentage > config.maxPassivePercentage {
            issues.append(AnalysisIssue(
                type: .passiveVoice,
                severity: metrics.passiveVoicePercentage > 20 ? .warning : .info,
                message: "Frequent passive voice (\(String(format: "%.1f", metrics.passiveVoicePercentage))% of sentences)",
                count: counts[.passiveVoice] ?? 0
            ))
        }
        if metrics.filterWordCount > 5 {
            issues.append(AnalysisIssue(
                type: .filterWord,
                severity: metrics.filterWordCount > 15 ? .warning : .info,
                message: "\(metrics.filterWordCount) filter words found",
                count: metrics.filterWordCount
            ))
        }
        if let repetitionCount = counts[.repetition], repetitionCount > 3 {
            issues.append(AnalysisIssue(
                type: .repetition,
                severity: repetitionCount > 10 ? .warning : .info,
                message: "\(repetitionCount) word repetitions detected",
                count: repetitionCount
            ))
        }
        if let longCount = counts[.longSentence], longCount > 2 {
            issues.append(AnalysisIssue(
                type: .longSentence,
                severity: longCount > 5 ? .warning : .info,
                message: "\(longCount) sentences exceed \(config.maxSentenceLength) words",
                count: longCount
            ))
        }
        if let starterCount = counts[.sentenceStarter], starterCount > 0 {
            issues.append(AnalysisIssue(
                type: .sentenceStarter,
                severity: .info,
                message: "Some sentence starters are repetitive",
                count: starterCount
            ))
        }
        if metrics.clicheCount > 0 {
            issues.append(AnalysisIssue(
                type: .cliche,
                severity: .warning,
                message: "\(metrics.clicheCount) cliché\(metrics.clicheCount == 1 ? "" : "s") detected",
                count: metrics.clicheCount
            ))
        }

        return issues
            .enumerated()
            .sorted { lhs, rhs in
                if lhs.element.severity != rhs.element.severity {
                    return lhs.element.severity < rhs.element.severity
                }
                if lhs.element.count != rhs.element.count {
                    return lhs.element.count > rhs.element.count
                }
                return lhs.offset < rhs.offset
            }
            .map(\.element)
            .prefix(5)
            .map { $0 }
    }

    static func summary(
        score: Int,
        topIssues: [AnalysisIssue],
        readabilityInterpretation: String
    ) -> String {
        var parts: [String] = []
        switch score {
        case 80...: parts.append("Excellent prose quality")
        case 60...: parts.append("Good prose quality")
        case 40...: parts.append("Fair prose quality")
        default: parts.append("Prose needs attention")
        }
        let readabilityLead = readabilityInterpretation.components(separatedBy: ".").first ?? ""
        parts.append("\(readabilityLead) readability")
        if let first = topIssues.first, first.severity != .info {
            parts.append(first.message.lowercased())
        }
        return parts.joined(separator: ". ") + "."
    }
}
