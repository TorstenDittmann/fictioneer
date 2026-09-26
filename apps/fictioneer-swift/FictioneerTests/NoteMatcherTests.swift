import Foundation
import Testing
@testable import Fictioneer

struct NoteMatcherTests {
    private func candidate(_ tags: [String], id: UUID = UUID()) -> NoteMatcher.Candidate {
        NoteMatcher.Candidate(id: id, tags: tags)
    }

    // MARK: - Word boundaries

    @Test func matchesWholeWordTag() {
        let id = UUID()
        let notes = [candidate(["Elena"], id: id)]
        #expect(NoteMatcher.matchingIDs(in: "Elena walked into the room.", notes: notes) == [id])
    }

    @Test func doesNotMatchAsSubstringOfLargerWord() {
        let id = UUID()
        let notes = [candidate(["Elena"], id: id)]
        // "Elenaria" contains "Elena" as a substring but not as a whole word.
        #expect(NoteMatcher.matchingIDs(in: "Elenaria was a different city.", notes: notes).isEmpty)
    }

    @Test func doesNotMatchWhenTagIsSubstringOfSceneWord() {
        let id = UUID()
        let notes = [candidate(["Ann"], id: id)]
        #expect(NoteMatcher.matchingIDs(in: "The banner unfurled.", notes: notes).isEmpty)
    }

    // MARK: - Case-insensitivity

    @Test func matchesRegardlessOfCase() {
        let id = UUID()
        let notes = [candidate(["dragon"], id: id)]
        #expect(NoteMatcher.matchingIDs(in: "The DRAGON roared.", notes: notes) == [id])
    }

    @Test func matchesWhenTagIsUppercaseAndTextIsLowercase() {
        let id = UUID()
        let notes = [candidate(["CASTLE"], id: id)]
        #expect(NoteMatcher.matchingIDs(in: "the castle on the hill", notes: notes) == [id])
    }

    // MARK: - Regex-metacharacter escaping

    @Test func escapesRegexMetacharactersLiterally() {
        let id = UUID()
        let notes = [candidate(["Dr. Strange"], id: id)]
        #expect(NoteMatcher.matchingIDs(in: "I watched Dr. Strange yesterday.", notes: notes) == [id])
    }

    @Test func escapedPeriodDoesNotActAsWildcard() {
        let id = UUID()
        let notes = [candidate(["Dr. Strange"], id: id)]
        // If the "." were an unescaped regex wildcard, this would incorrectly match.
        #expect(NoteMatcher.matchingIDs(in: "I watched Drx Strange yesterday.", notes: notes).isEmpty)
    }

    @Test func tagWithRepeatedRegexQuantifierCharactersDoesNotCrash() {
        let id = UUID()
        let notes = [candidate(["C++"], id: id)]
        // Unescaped, "++" is an invalid nested quantifier that would make the
        // underlying regex fail to compile; escaping must prevent that crash.
        #expect(NoteMatcher.matchingIDs(in: "I love C++ programming.", notes: notes).isEmpty)
    }

    @Test func tagWithTrailingSymbolsMatchesWhenGluedToAWordCharacter() {
        // Faithful port quirk (shared with the Tauri reference's `\b`-based
        // regex): a trailing `\b` after a non-word character like "+" only
        // matches when immediately followed by a word character, not a space.
        let id = UUID()
        let notes = [candidate(["C++"], id: id)]
        #expect(NoteMatcher.matchingIDs(in: "the C++Builder tool", notes: notes) == [id])
    }

    // MARK: - Empty tag handling

    @Test func emptyTagsNeverMatch() {
        let id = UUID()
        let notes = [candidate([""], id: id)]
        #expect(NoteMatcher.matchingIDs(in: "Any text at all.", notes: notes).isEmpty)
    }

    @Test func whitespaceOnlyTagsNeverMatch() {
        let id = UUID()
        let notes = [candidate(["   ", "\n\t"], id: id)]
        #expect(NoteMatcher.matchingIDs(in: "Any text at all.", notes: notes).isEmpty)
    }

    @Test func noteWithNoTagsNeverMatches() {
        let id = UUID()
        let notes = [candidate([], id: id)]
        #expect(NoteMatcher.matchingIDs(in: "Elena and the dragon.", notes: notes).isEmpty)
    }

    // MARK: - Multiple notes / multiple tags

    @Test func noteMatchesIfAnyOfItsTagsMatch() {
        let id = UUID()
        let notes = [candidate(["griffin", "Elena"], id: id)]
        #expect(NoteMatcher.matchingIDs(in: "Elena walked in.", notes: notes) == [id])
    }

    @Test func multipleNotesEachEvaluatedIndependently() {
        let elenaID = UUID()
        let dragonID = UUID()
        let unrelatedID = UUID()
        let notes = [
            candidate(["Elena"], id: elenaID),
            candidate(["dragon", "wyrm"], id: dragonID),
            candidate(["castle"], id: unrelatedID),
        ]
        let matched = NoteMatcher.matchingIDs(
            in: "Elena faced the dragon at dawn.",
            notes: notes
        )
        #expect(matched == [elenaID, dragonID])
    }

    @Test func preservesInputOrderOfNotes() {
        let first = UUID()
        let second = UUID()
        let notes = [
            candidate(["dragon"], id: first),
            candidate(["Elena"], id: second),
        ]
        let matched = NoteMatcher.matchingIDs(
            in: "Elena faced the dragon at dawn.",
            notes: notes
        )
        #expect(matched == [first, second])
    }
}
