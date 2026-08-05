import Foundation

/// Pure port of the Tauri app's `find_notes_by_content`: flags which project
/// notes are "mentioned" in a scene by matching each note's tags against the
/// scene's plain text, case-insensitively and on whole-word boundaries.
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

        init(id: UUID, tags: [String]) {
            self.id = id
            self.tags = tags
        }
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
        guard !trimmed.isEmpty else { return false }
        let escaped = NSRegularExpression.escapedPattern(for: trimmed)
        guard let regex = try? NSRegularExpression(pattern: "\\b\(escaped)\\b", options: [.caseInsensitive]) else {
            return false
        }
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        return regex.firstMatch(in: text, range: range) != nil
    }
}
