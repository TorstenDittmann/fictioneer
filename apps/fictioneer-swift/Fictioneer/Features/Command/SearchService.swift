import Foundation

nonisolated struct SearchSnippetSegment: Sendable, Equatable {
    var text: String
    var highlighted: Bool
}

nonisolated struct SearchSnippet: Sendable, Equatable {
    var segments: [SearchSnippetSegment]
}

nonisolated struct SceneSearchEntry: Sendable {
    var id: UUID
    var title: String
    var content: String
    var chapterTitle: String
    var wordCount: Int
}

nonisolated struct SceneSearchResult: Sendable {
    var id: UUID
    var title: String
    var chapterTitle: String
    var wordCount: Int
    var score: Double
    var snippets: [SearchSnippet]
}

/// Full-text scene search: fuzzy on titles (weight 2), substring on content
/// (weight 1), snippet windows ±40/60 chars, max 2 per scene, 50 results.
nonisolated enum SearchService {
    static let minQueryLength = 2
    static let resultLimit = 50

    static func search(query: String, in scenes: [SceneSearchEntry]) -> [SceneSearchResult] {
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        guard trimmed.count >= minQueryLength else { return [] }

        var results: [SceneSearchResult] = []
        for entry in scenes {
            let titleScore = CommandScore.score(trimmed, in: entry.title)
            let contentMatches = occurrences(of: trimmed, in: entry.content)
            guard titleScore > 0.15 || !contentMatches.isEmpty else { continue }

            let score = titleScore * 2 + Double(min(contentMatches.count, 5))
            let snippets = makeSnippets(content: entry.content, matches: contentMatches, queryLength: (trimmed as NSString).length)
            results.append(SceneSearchResult(
                id: entry.id,
                title: entry.title,
                chapterTitle: entry.chapterTitle,
                wordCount: entry.wordCount,
                score: score,
                snippets: snippets
            ))
        }
        return results
            .sorted { $0.score > $1.score }
            .prefix(resultLimit)
            .map { $0 }
    }

    static func occurrences(of query: String, in text: String) -> [Int] {
        let ns = text as NSString
        var positions: [Int] = []
        var searchRange = NSRange(location: 0, length: ns.length)
        while true {
            let found = ns.range(of: query, options: [.caseInsensitive], range: searchRange)
            if found.location == NSNotFound { break }
            positions.append(found.location)
            let nextStart = found.location + max(1, found.length)
            guard nextStart < ns.length else { break }
            searchRange = NSRange(location: nextStart, length: ns.length - nextStart)
        }
        return positions
    }

    /// Snippet windows: 40 chars of context before the match, 60 after; a new
    /// snippet only starts when the next match is outside the previous window;
    /// at most two snippets per scene.
    static func makeSnippets(content: String, matches: [Int], queryLength: Int) -> [SearchSnippet] {
        let ns = content as NSString
        var snippets: [SearchSnippet] = []
        var usedRanges: [NSRange] = []

        for matchStart in matches {
            guard snippets.count < 2 else { break }
            if usedRanges.contains(where: { NSLocationInRange(matchStart, $0) }) { continue }

            let windowStart = max(0, matchStart - 40)
            let windowEnd = min(ns.length, matchStart + queryLength + 60)
            let window = NSRange(location: windowStart, length: windowEnd - windowStart)
            usedRanges.append(NSRange(location: windowStart, length: windowEnd - windowStart + 50))

            var segments: [SearchSnippetSegment] = []
            if windowStart > 0 {
                segments.append(SearchSnippetSegment(text: "…", highlighted: false))
            }
            // All matches fully inside the window get highlighted.
            let inWindow = matches.filter { $0 >= windowStart && $0 + queryLength <= windowEnd }
            var cursor = windowStart
            for position in inWindow {
                if position > cursor {
                    segments.append(SearchSnippetSegment(
                        text: ns.substring(with: NSRange(location: cursor, length: position - cursor)),
                        highlighted: false
                    ))
                }
                segments.append(SearchSnippetSegment(
                    text: ns.substring(with: NSRange(location: position, length: queryLength)),
                    highlighted: true
                ))
                cursor = position + queryLength
            }
            if cursor < windowEnd {
                segments.append(SearchSnippetSegment(
                    text: ns.substring(with: NSRange(location: cursor, length: windowEnd - cursor)),
                    highlighted: false
                ))
            }
            if windowEnd < ns.length {
                segments.append(SearchSnippetSegment(text: "…", highlighted: false))
            }
            _ = window
            snippets.append(SearchSnippet(segments: segments))
        }
        return snippets
    }
}
