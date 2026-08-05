import Foundation
import Testing
@testable import Fictioneer

// Fixture expectations mirror the Tauri app's text_analysis/*.test.ts suites.

struct SyllableCounterTests {
    @Test func overrides() {
        #expect(SyllableCounter.countSyllables("eye") == 1)
        #expect(SyllableCounter.countSyllables("awe") == 1)
        #expect(SyllableCounter.countSyllables("business") == 2)
        #expect(SyllableCounter.countSyllables("every") == 2)
        #expect(SyllableCounter.countSyllables("interesting") == 3)
        #expect(SyllableCounter.countSyllables("definitely") == 4)
        #expect(SyllableCounter.countSyllables("really") == 2)
        #expect(SyllableCounter.countSyllables("being") == 2)
    }

    @Test func contractions() {
        #expect(SyllableCounter.countSyllables("don't") == 1)
        #expect(SyllableCounter.countSyllables("won't") == 1)
        #expect(SyllableCounter.countSyllables("didn't") == 2)
        #expect(SyllableCounter.countSyllables("couldn't") == 2)
        #expect(SyllableCounter.countSyllables("i'm") == 1)
        #expect(SyllableCounter.countSyllables("it's") == 1)
        #expect(SyllableCounter.countSyllables("they're") == 1)
    }

    @Test func silentE() {
        #expect(SyllableCounter.countSyllables("make") == 1)
        #expect(SyllableCounter.countSyllables("take") == 1)
        #expect(SyllableCounter.countSyllables("time") == 1)
        #expect(SyllableCounter.countSyllables("home") == 1)
    }

    @Test func edSuffix() {
        #expect(SyllableCounter.countSyllables("walked") == 1)
        #expect(SyllableCounter.countSyllables("wanted") == 2)
    }

    @Test func edgeCases() {
        #expect(SyllableCounter.countSyllables("") == 0)
        #expect(SyllableCounter.countSyllables("   ") == 0)
        #expect(SyllableCounter.countSyllables("a") == 1)
        #expect(SyllableCounter.countSyllables("redo") >= 2)
        #expect(SyllableCounter.countSyllables("preview") >= 2)
    }

    @Test func wordExtraction() {
        #expect(SyllableCounter.extractWords("Hello, world!") == ["Hello", "world"])
        #expect(SyllableCounter.extractWords("don't stop-motion film") == ["don't", "stop-motion", "film"])
        #expect(SyllableCounter.extractWords("123 456") == [])
    }
}

struct ReadabilityTests {
    @Test func sentenceSplittingBasics() {
        let sentences = Readability.splitIntoSentences("The cat sat. The dog ran! Did the bird fly?")
        #expect(sentences == ["The cat sat", "The dog ran", "Did the bird fly"])
    }

    @Test func abbreviationsDoNotSplit() {
        let sentences = Readability.splitIntoSentences("Dr. Smith arrived. Mr. Jones left.")
        #expect(sentences.count == 2)
        #expect(sentences[0].contains("Smith"))
    }

    @Test func decimalsAndEllipsisSurvive() {
        let sentences = Readability.splitIntoSentences("It cost 3.50 dollars. He paused... Then spoke.")
        #expect(sentences[0] == "It cost 3.50 dollars")
        #expect(sentences.contains { $0.contains("...") })
    }

    @Test func abbreviationMatchPreservesOriginalCasing() {
        // "no." matches the abbreviation "No" case-insensitively. The
        // canonicalized replacement used to rewrite it as "No", so the
        // restored sentence no longer existed in the original text and
        // silently dropped out of all downstream analysis.
        let sentences = Readability.splitIntoSentences("she said no. He walked slowly.")
        #expect(sentences == ["she said no. He walked slowly"])
    }

    @Test func quotedDialogueSplitsAtSentenceBoundaries() {
        // Curly quotes around the boundary must not defeat the split.
        let text = "\u{201C}Marriage agrees with you,\u{201D} he remarked from his armchair. "
            + "\u{201C}I observe you have gained half a stone.\u{201D}"
        let sentences = Readability.splitIntoSentences(text)
        #expect(sentences.count == 2)
        #expect(sentences[1].hasPrefix("\u{201C}I observe"))

        // Terminator inside the closing quote: `said." He`
        let inside = "He said \u{201C}stop.\u{201D} Then he left."
        #expect(Readability.splitIntoSentences(inside).count == 2)
    }

    @Test func newlinesAreSentenceBoundaries() {
        let sentences = Readability.splitIntoSentences("a line without punctuation\nanother line follows\nThird one. And more")
        #expect(sentences == ["a line without punctuation", "another line follows", "Third one", "And more"])
    }

    @Test func emptyTextScoresZero() {
        let scores = Readability.scores(for: "")
        #expect(scores.fleschReadingEase == 0)
        #expect(scores.fleschKincaidGrade == 0)
    }

    @Test func simpleTextIsEasy() {
        let scores = Readability.scores(for: "The cat sat. The dog ran. He is big. She is small.")
        #expect(scores.fleschReadingEase > 80)
        #expect(scores.level == "very_easy")
    }
}

struct SentenceAnalysisTests {
    @Test func parsePositionsAreExact() {
        let text = "First sentence here. Second one follows."
        let sentences = SentenceAnalysis.parseSentences(text)
        #expect(sentences.count == 2)
        #expect(sentences[0].start == 0)
        let ns = text as NSString
        #expect(ns.substring(with: NSRange(location: sentences[1].start, length: sentences[1].end - sentences[1].start)) == "Second one follows")
    }

    @Test func varietyScoreBounds() {
        #expect(SentenceAnalysis.varietyScore(lengths: [5, 6]) == 50)
        // std dev of exactly 7 → perfect 100
        #expect(SentenceAnalysis.varietyScore(lengths: [1, 8, 15]) > 80)
    }

    @Test func longSentenceHighlighted() {
        let words = Array(repeating: "word", count: 35).joined(separator: " ")
        let sentences = SentenceAnalysis.parseSentences(words + ".")
        let highlights = SentenceAnalysis.highlights(for: sentences, config: .default)
        #expect(highlights.contains { $0.type == .longSentence })
    }

    @Test func paragraphBreaksNeverMergeIntoLongSentences() {
        // Two unpunctuated 20-word paragraphs: merged they'd be a false
        // 40-word "long sentence"; newline boundaries keep them separate.
        let line = Array(repeating: "word", count: 20).joined(separator: " ")
        let sentences = SentenceAnalysis.parseSentences(line + "\n" + line)
        #expect(sentences.count == 2)
        let highlights = SentenceAnalysis.highlights(for: sentences, config: .default)
        #expect(!highlights.contains { $0.type == .longSentence })
    }

    @Test func consecutiveStartersFlagged() {
        let text = "He walked in. He sat down. He sighed loudly. She watched."
        let sentences = SentenceAnalysis.parseSentences(text)
        let highlights = SentenceAnalysis.highlights(for: sentences, config: .default)
        let starterHighlights = highlights.filter { $0.type == .sentenceStarter }
        #expect(starterHighlights.count == 3)
        #expect(starterHighlights[0].message.contains("3 consecutive"))
    }

    @Test func dialoguePercentageCountsEachSpanOnce() {
        // "hello" quoted = 5 chars of dialogue; total non-ws chars = 12 ("said" + quotes + hello…)
        let text = "\"hello\" said"
        let percentage = SentenceAnalysis.dialoguePercentage(text)
        // 5 dialogue chars of 11 non-space chars ≈ 45% — must NOT be double-counted to 91%.
        #expect(percentage <= 60)
        #expect(percentage >= 30)
    }

    @Test func smartQuotesCountAsDialogue() {
        let percentage = SentenceAnalysis.dialoguePercentage("\u{201C}hello there\u{201D} she said")
        #expect(percentage > 0)
    }
}

struct ProseQualityTests {
    private func sentences(_ text: String) -> [SentenceInfo] {
        SentenceAnalysis.parseSentences(text)
    }

    @Test func lyAdverbsDetectedWithExceptions() {
        let text = "She ran quickly. The friendly dog barked."
        let adverbs = ProseQuality.detectAdverbs(text, sentences: sentences(text))
        #expect(adverbs.contains { $0.word == "quickly" })
        #expect(!adverbs.contains { $0.word == "friendly" })
    }

    @Test func nonLyAdverbsDetected() {
        let text = "It was very good and quite nice."
        let adverbs = ProseQuality.detectAdverbs(text, sentences: sentences(text))
        #expect(adverbs.contains { $0.word == "very" })
        #expect(adverbs.contains { $0.word == "quite" })
    }

    @Test func passiveVoiceDetected() {
        let text = "The ball was thrown by John. She writes daily."
        let passives = ProseQuality.detectPassiveVoice(text, sentences: sentences(text))
        #expect(passives.count == 1)
        #expect(passives[0].phrase == "was thrown")
    }

    @Test func passiveWithAdverbDetected() {
        let text = "The window was quickly broken."
        let passives = ProseQuality.detectPassiveVoice(text, sentences: sentences(text))
        #expect(passives.contains { $0.phrase == "was quickly broken" })
    }

    @Test func filterWordsIncludePhrases() {
        let filters = ProseQuality.detectFilterWords("He was kind of tired and just a bit slow.")
        let words = filters.map(\.word)
        #expect(words.contains("kind of"))
        #expect(words.contains("just"))
        #expect(words.contains("a bit"))
    }

    @Test func clichesDetected() {
        let matches = ProseQuality.detectCliches("It was a dark and stormy night. Time stood still.")
        #expect(matches.count == 2)
    }

    @Test func vagueWordsKeepOriginalCasing() {
        let matches = ProseQuality.detectVagueWords("Things happened. Nice view.")
        #expect(matches.contains { $0.word == "Things" })
        #expect(matches.contains { $0.word == "Nice" })
    }

    @Test func sentenceAfterLowercasedAbbreviationStaysAnalyzed() {
        let text = "she said no. He walked slowly."
        let parsed = sentences(text)
        #expect(!parsed.isEmpty)
        let adverbs = ProseQuality.detectAdverbs(text, sentences: parsed)
        #expect(adverbs.contains { $0.word == "slowly" })
    }

    @Test func positionsIndexIntoUnicodeTextCorrectly() {
        let text = "\u{201C}Caf\u{E9}!\u{201D} she said very softly."
        let adverbs = ProseQuality.detectAdverbs(text, sentences: sentences(text))
        let ns = text as NSString
        for match in adverbs {
            let extracted = ns.substring(with: NSRange(location: match.position, length: (match.word as NSString).length))
            #expect(extracted.lowercased() == match.word)
        }
        #expect(adverbs.contains { $0.word == "softly" })
    }
}

struct WordAnalysisTests {
    @Test func repetitionsWithinDistance() {
        let text = "The castle stood tall. Inside the castle, torches burned."
        let repetitions = WordAnalysis.detectRepetitions(text, config: .default)
        #expect(repetitions.count == 1)
        #expect(repetitions[0].word == "castle")
        #expect(repetitions[0].positions.count == 2)
    }

    @Test func commonAndShortWordsIgnored() {
        let text = "He said that that was the the same same idea."
        let repetitions = WordAnalysis.detectRepetitions(text, config: .default)
        // "that"/"the" common; "same" only 4 letters (< 5 min length)
        #expect(repetitions.isEmpty)
    }

    @Test func weakVerbHighlightsGatedByPercentage() {
        // Nearly all weak verbs → gate passes, every 3rd emitted.
        let text = "He was is are was were said felt got made came went."
        let highlights = WordAnalysis.highlights(text, config: .default)
        let weak = highlights.filter { $0.type == .weakVerb }
        #expect(!weak.isEmpty)

        let strong = "The detective sprinted across the courtyard chasing shadows relentlessly forward."
        let none = WordAnalysis.highlights(strong, config: .default).filter { $0.type == .weakVerb }
        #expect(none.isEmpty)
    }
}

struct TextAnalysisEngineTests {
    @Test func cleanProseScoresWell() {
        let text = """
        The detective crossed the courtyard. Rain hammered the cobblestones while \
        shadows gathered near the gate. A lantern flickered against the fog. \
        Somewhere beyond the wall, a carriage rattled past.
        """
        let result = TextAnalysisEngine.analyze(text)
        #expect(result.overallScore >= 60)
        #expect(result.wordCount == 29)
        #expect(result.summary.hasSuffix("."))
    }

    @Test func adverbHeavyProseScoresLowerAndIssuesSurface() {
        let text = """
        She quickly ran. He slowly walked. They quietly talked. It suddenly moved. \
        She really loudly shouted. He very carefully stepped. Basically it was just \
        really quite very extremely bad.
        """
        let result = TextAnalysisEngine.analyze(text)
        let clean = TextAnalysisEngine.analyze(
            "The storm broke against the cliffs. Waves shattered into spray. Gulls wheeled overhead in the fading light."
        )
        #expect(result.overallScore < clean.overallScore)
        #expect(result.topIssues.contains { $0.type == .adverb })
        #expect(result.topIssues.count <= 5)
    }

    @Test func highlightRangesMatchText() {
        let text = "It was a dark and stormy night. The castle door was opened slowly. The castle gate creaked."
        let result = TextAnalysisEngine.analyze(text)
        let ns = text as NSString
        for highlight in result.highlights {
            #expect(highlight.start >= 0)
            #expect(highlight.end <= ns.length)
            #expect(highlight.start < highlight.end)
        }
        #expect(result.highlights.contains { $0.type == .cliche })
        #expect(result.highlights.contains { $0.type == .passiveVoice })
        #expect(result.highlights.contains { $0.type == .repetition })
    }

    @Test func hashIsDeterministicAndSensitive() {
        #expect(TextAnalysisEngine.contentHash("abc") == TextAnalysisEngine.contentHash("abc"))
        #expect(TextAnalysisEngine.contentHash("abc") != TextAnalysisEngine.contentHash("abd"))
    }

    @Test func largeDocumentAnalyzesWithinBudget() {
        let paragraph = "The detective walked slowly through the very dark corridor. He was followed by shadows that seemed to whisper. "
        let text = String(repeating: paragraph, count: 180) // ~3k words
        let start = ContinuousClock.now
        _ = TextAnalysisEngine.analyze(text)
        let elapsed = ContinuousClock.now - start
        #expect(elapsed < .seconds(10))
    }

    @Test func largeManuscriptAnalyzesWithinBudget() {
        let paragraph = "The detective walked slowly through the very dark corridor. He was followed by shadows that seemed to whisper. "
        let text = String(repeating: paragraph, count: 5600) // ~100k words
        let start = ContinuousClock.now
        _ = TextAnalysisEngine.analyze(text)
        let elapsed = ContinuousClock.now - start
        #expect(elapsed < .seconds(60))
    }
}
