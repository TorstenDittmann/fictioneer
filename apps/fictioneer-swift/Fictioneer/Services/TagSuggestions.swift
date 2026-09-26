import Foundation

/// Pure computation behind the note editor's tag-autocompletion chips.
///
/// Deliberately has no dependency on `Note` or `Project` so it stays cheap to
/// call on every keystroke and testable in isolation.
nonisolated enum TagSuggestions {
    /// Returns the distinct tags to offer as chips beneath the tags field.
    ///
    /// - `allTags`: every tag across every note in the project (order is
    ///   preserved for first-occurrence dedup, so suggestions read stably).
    /// - `appliedTags`: tags already on the note being edited; excluded.
    /// - `fragment`: the in-progress text after the last comma in the tags
    ///   field. Blank fragments return all remaining distinct tags; otherwise
    ///   tags are kept if they contain the fragment, case-insensitively.
    static func suggestions(allTags: [String], appliedTags: [String], fragment: String) -> [String] {
        let applied = Set(appliedTags.map { $0.trimmingCharacters(in: .whitespaces).lowercased() })
        var seen = Set<String>()
        var distinct: [String] = []
        for tag in allTags {
            let trimmed = tag.trimmingCharacters(in: .whitespaces)
            let key = trimmed.lowercased()
            guard !key.isEmpty, !applied.contains(key), !seen.contains(key) else { continue }
            seen.insert(key)
            distinct.append(trimmed)
        }

        let trimmedFragment = fragment.trimmingCharacters(in: .whitespaces)
        guard !trimmedFragment.isEmpty else { return distinct }
        return distinct.filter { $0.localizedCaseInsensitiveContains(trimmedFragment) }
    }

    /// The fragment currently being typed: the text after the last comma in
    /// `tagsText` (the whole string if there is no comma yet).
    static func currentFragment(in tagsText: String) -> String {
        let fragment = if let lastComma = tagsText.lastIndex(of: ",") {
            String(tagsText[tagsText.index(after: lastComma)...])
        } else {
            tagsText
        }
        return fragment.trimmingCharacters(in: .whitespaces)
    }

    /// Replaces the in-progress fragment in `tagsText` with `tag`, leaving a
    /// trailing ", " so typing can continue straight into the next tag.
    static func applying(_ tag: String, to tagsText: String) -> String {
        let prefix = if let lastComma = tagsText.lastIndex(of: ",") {
            String(tagsText[...lastComma]) + " "
        } else {
            ""
        }
        return prefix + tag + ", "
    }
}
