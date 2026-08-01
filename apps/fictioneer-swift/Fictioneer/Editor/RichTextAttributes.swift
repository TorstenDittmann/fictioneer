import AppKit

extension NSAttributedString.Key {
    /// Heading level 1–3 (NSNumber). Absent means body text.
    static let headingLevel = NSAttributedString.Key("app.fictioneer.headingLevel")
    /// Blockquote paragraph marker (NSNumber bool).
    static let blockquote = NSAttributedString.Key("app.fictioneer.blockquote")
    /// Marks AI ghost text that must never be persisted or counted.
    static let ghostText = NSAttributedString.Key("app.fictioneer.ghostText")
}

extension NSAttributedString {
    /// A copy with all ghost-text ranges removed. Returns self when none exist.
    func strippingGhostText() -> NSAttributedString {
        var ghostRanges: [NSRange] = []
        enumerateAttribute(.ghostText, in: NSRange(location: 0, length: length)) { value, range, _ in
            if value != nil {
                ghostRanges.append(range)
            }
        }
        guard !ghostRanges.isEmpty else { return self }
        let mutable = NSMutableAttributedString(attributedString: self)
        for range in ghostRanges.reversed() {
            mutable.deleteCharacters(in: range)
        }
        return mutable
    }
}
