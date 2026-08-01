import Foundation
import Testing
@testable import Fictioneer

struct CommandScoreTests {
    @Test func exactPrefixBeatsScatteredMatch() {
        let prefix = CommandScore.score("new", in: "new scene")
        let scattered = CommandScore.score("nsc", in: "new scene")
        #expect(prefix > scattered)
        #expect(prefix > 0.8)
    }

    @Test func wordBoundaryJumpScoresWell() {
        let score = CommandScore.score("ns", in: "new scene")
        #expect(score > 0.5)
    }

    @Test func nonSubsequenceScoresZero() {
        #expect(CommandScore.score("xyz", in: "new scene") == 0)
        #expect(CommandScore.score("scenes", in: "scene") == 0)
    }

    @Test func caseAndHyphenInsensitive() {
        #expect(CommandScore.score("Focus Mode", in: "focus-mode toggle") > 0.5)
    }
}

struct SearchServiceTests {
    private func entries() -> [SceneSearchEntry] {
        [
            SceneSearchEntry(
                id: UUID(), title: "The Visitor", content: "A stranger arrived at the door. The visitor spoke softly about the visitor's past.",
                chapterTitle: "One", wordCount: 15
            ),
            SceneSearchEntry(
                id: UUID(), title: "Morning Fog", content: "Nothing here matches the query at all.",
                chapterTitle: "One", wordCount: 7
            ),
        ]
    }

    @Test func shortQueriesReturnNothing() {
        #expect(SearchService.search(query: "a", in: entries()).isEmpty)
        #expect(SearchService.search(query: " ", in: entries()).isEmpty)
    }

    @Test func titleMatchesRankAboveContentMatches() {
        let scenes = [
            SceneSearchEntry(id: UUID(), title: "Visitor", content: "no match here", chapterTitle: "C", wordCount: 3),
            SceneSearchEntry(id: UUID(), title: "Other", content: "the visitor entered", chapterTitle: "C", wordCount: 3),
        ]
        let results = SearchService.search(query: "visitor", in: scenes)
        #expect(results.count == 2)
        #expect(results[0].title == "Visitor")
    }

    @Test func snippetsHighlightMatchesWithContext() {
        let results = SearchService.search(query: "visitor", in: entries())
        let first = results[0]
        #expect(!first.snippets.isEmpty)
        #expect(first.snippets.count <= 2)
        let highlighted = first.snippets[0].segments.filter(\.highlighted)
        #expect(!highlighted.isEmpty)
        #expect(highlighted.allSatisfy { $0.text.lowercased() == "visitor" })
    }

    @Test func resultLimitIsFifty() {
        let many = (0..<80).map { index in
            SceneSearchEntry(id: UUID(), title: "Scene \(index)", content: "the castle stood", chapterTitle: "C", wordCount: 3)
        }
        let results = SearchService.search(query: "castle", in: many)
        #expect(results.count == 50)
    }
}
