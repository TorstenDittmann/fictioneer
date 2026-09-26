import Testing
@testable import Fictioneer

struct TagSuggestionsTests {
    // MARK: - suggestions(allTags:appliedTags:fragment:)

    @Test func distinctsAcrossNotesPreservingFirstOccurrence() {
        let result = TagSuggestions.suggestions(
            allTags: ["character", "pov", "character", "setting"],
            appliedTags: [],
            fragment: ""
        )
        #expect(result == ["character", "pov", "setting"])
    }

    @Test func excludesTagsAlreadyOnTheCurrentNote() {
        let result = TagSuggestions.suggestions(
            allTags: ["character", "pov", "setting"],
            appliedTags: ["pov"],
            fragment: ""
        )
        #expect(result == ["character", "setting"])
    }

    @Test func exclusionIsCaseInsensitive() {
        let result = TagSuggestions.suggestions(
            allTags: ["Character", "pov"],
            appliedTags: ["character"],
            fragment: ""
        )
        #expect(result == ["pov"])
    }

    @Test func emptyFragmentReturnsAllRemainingDistinctTags() {
        let result = TagSuggestions.suggestions(
            allTags: ["character", "pov"],
            appliedTags: [],
            fragment: "   "
        )
        #expect(result == ["character", "pov"])
    }

    @Test func fragmentFiltersByCaseInsensitiveContainsMatch() {
        // "CTE" is a substring of "character" ("...aCTEr...") but not of "pov" or "setting".
        let result = TagSuggestions.suggestions(
            allTags: ["character", "pov", "setting"],
            appliedTags: [],
            fragment: "CTE"
        )
        #expect(result == ["character"])
    }

    @Test func fragmentWithNoMatchesReturnsEmpty() {
        let result = TagSuggestions.suggestions(
            allTags: ["character", "pov"],
            appliedTags: [],
            fragment: "zzz"
        )
        #expect(result.isEmpty)
    }

    @Test func blankAndWhitespaceOnlyTagsAreNeverSuggested() {
        let result = TagSuggestions.suggestions(
            allTags: ["", "   ", "pov"],
            appliedTags: [],
            fragment: ""
        )
        #expect(result == ["pov"])
    }

    @Test func suggestedTagsAreTrimmed() {
        let result = TagSuggestions.suggestions(
            allTags: ["  pov  "],
            appliedTags: [],
            fragment: ""
        )
        #expect(result == ["pov"])
    }

    // MARK: - currentFragment(in:)

    @Test func fragmentIsWholeTextWhenThereIsNoComma() {
        #expect(TagSuggestions.currentFragment(in: "po") == "po")
    }

    @Test func fragmentIsTextAfterLastComma() {
        #expect(TagSuggestions.currentFragment(in: "character, po") == "po")
    }

    @Test func fragmentTrimsSurroundingWhitespace() {
        #expect(TagSuggestions.currentFragment(in: "character,   po  ") == "po")
    }

    @Test func fragmentIsEmptyRightAfterATrailingComma() {
        #expect(TagSuggestions.currentFragment(in: "character, ") == "")
    }

    @Test func fragmentUsesOnlyTheLastCommaWithMultipleTags() {
        #expect(TagSuggestions.currentFragment(in: "character, pov, se") == "se")
    }

    // MARK: - applying(_:to:)

    @Test func applyingReplacesTheOnlyFragmentWhenThereIsNoComma() {
        #expect(TagSuggestions.applying("pov", to: "po") == "pov, ")
    }

    @Test func applyingReplacesTheFragmentAfterTheLastComma() {
        #expect(TagSuggestions.applying("pov", to: "character, po") == "character, pov, ")
    }

    @Test func applyingAfterATrailingCommaAppendsTheTag() {
        #expect(TagSuggestions.applying("setting", to: "character, ") == "character, setting, ")
    }

    @Test func applyingLeavesEarlierTagsUntouched() {
        #expect(TagSuggestions.applying("setting", to: "character, pov, se") == "character, pov, setting, ")
    }
}
