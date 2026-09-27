import Foundation
import os

/// Flags which project notes are "mentioned" in a scene by matching each
/// note's tags against the scene's plain text, case-insensitively and on
/// whole-word boundaries.
///
/// Deliberately has no dependency on the `Note` model or persistence — callers
/// supply plain `(id, tags)` candidates and get back the ids that matched, so
/// this stays cheap to call from the editor's analysis debounce and testable
/// in isolation.
nonisolated enum NoteMatcher {
    /// A note's taggable identity, decoupled from `Note` on purpose.
    struct Candidate: Sendable, Equatable {
        let id: UUID
        let tags: [String]
    }

    /// Returns the ids of candidates with at least one tag that appears,
    /// case-insensitively and on word boundaries, in `text`. Blank tags never
    /// match. Preserves the order of `notes`.
    static func matchingIDs(in text: String, notes: [Candidate]) -> [UUID] {
        notes.filter { candidate in
            candidate.tags.contains { tagMatches($0, in: text) }
        }.map(\.id)
    }

    private static func tagMatches(_ tag: String, in text: String) -> Bool {
        let trimmed = tag.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, let regex = regex(for: trimmed) else { return false }
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        return regex.firstMatch(in: text, range: range) != nil
    }

    /// Compiled once per tag: this runs on every analysis pass.
    private static let cache = OSAllocatedUnfairLock<[String: NSRegularExpression]>(initialState: [:])

    /// Word boundaries as "no letter, digit or underscore on either side"
    /// rather than `\b`, which can't match next to a tag that starts or ends
    /// with punctuation (`#hero`, `Dr.`).
    private static func regex(for tag: String) -> NSRegularExpression? {
        if let cached = cache.withLock({ $0[tag] }) { return cached }
        let word = "[\\p{L}\\p{N}_]"
        let pattern = "(?<!\(word))\(NSRegularExpression.escapedPattern(for: tag))(?!\(word))"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else {
            return nil
        }
        cache.withLock { $0[tag] = regex }
        return regex
    }
}
