import Foundation

/// Builds the `/api/continue` context the way the Tauri client does:
/// detect mid-sentence vs sentence-boundary, and pass the trailing fragment
/// as `recent_text` for the server's anti-repetition guard.
nonisolated enum GhostContextBuilder {
    static func build(
        contextText: String,
        title: String?,
        sceneDescription: String?
    ) -> IntelligenceClient.ContinueContext {
        let trimmed = String(
            contextText.reversed().drop { $0.isWhitespace || $0.isNewline }.reversed()
        )
        var withoutQuotes = trimmed
        while let last = withoutQuotes.last, "\"'”’".contains(last) {
            withoutQuotes.removeLast()
        }
        let endsSentence = withoutQuotes.last.map { ".!?…".contains($0) } ?? true

        let instruction = endsSentence
            ? "Start a new sentence that continues the narrative naturally."
            : "Complete the current incomplete sentence, continuing seamlessly from the exact text."

        var recentText: String?
        if let boundary = trimmed.lastIndex(where: { ".!?…\n".contains($0) }) {
            let fragment = trimmed[trimmed.index(after: boundary)...]
                .trimmingCharacters(in: .whitespacesAndNewlines)
            recentText = fragment.isEmpty ? nil : fragment
        } else if !trimmed.isEmpty {
            recentText = trimmed
        }

        return IntelligenceClient.ContinueContext(
            title: title,
            sceneDescription: sceneDescription,
            recentText: recentText,
            instruction: instruction
        )
    }
}
