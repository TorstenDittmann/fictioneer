import Testing
@testable import Fictioneer

struct WordCounterTests {
    @Test func emptyString() {
        let counts = WordCounter.counts(for: "")
        #expect(counts.words == 0)
        #expect(counts.characters == 0)
    }

    @Test func simpleSentence() {
        let counts = WordCounter.counts(for: "It was a dark and stormy night.")
        #expect(counts.words == 7)
        #expect(counts.characters == 31)
    }

    @Test func punctuationAndNewlines() {
        let counts = WordCounter.counts(for: "Hello, world!\n\nGoodbye — for now…")
        #expect(counts.words == 5)
    }

    @Test func apostrophesCountAsOneWord() {
        let counts = WordCounter.counts(for: "don't can't won't")
        #expect(counts.words == 3)
    }

    @Test func unicodeText() {
        let counts = WordCounter.counts(for: "café naïve résumé")
        #expect(counts.words == 3)
        #expect(counts.characters == 17)
    }
}
