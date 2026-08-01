import AppKit

extension NSAttributedString.Key {
    /// Heading level 1–3 (NSNumber). Absent means body text.
    static let headingLevel = NSAttributedString.Key("app.fictioneer.headingLevel")
    /// Blockquote paragraph marker (NSNumber bool).
    static let blockquote = NSAttributedString.Key("app.fictioneer.blockquote")
    /// Marks AI ghost text that must never be persisted or counted.
    static let ghostText = NSAttributedString.Key("app.fictioneer.ghostText")
    /// Marks a prose-analysis display highlight (value: AnalysisMarker).
    /// Display-only; stripped (with prior styling restored) before persisting.
    static let analysisHighlight = NSAttributedString.Key("app.fictioneer.analysisHighlight")
}

/// Payload for `.analysisHighlight`: remembers what the highlight replaced so
/// stripping restores the user's own formatting exactly.
final class AnalysisMarker {
    let previousUnderlineStyle: Int?
    let previousBackgroundColor: NSColor?

    init(previousUnderlineStyle: Int?, previousBackgroundColor: NSColor?) {
        self.previousUnderlineStyle = previousUnderlineStyle
        self.previousBackgroundColor = previousBackgroundColor
    }
}

extension NSAttributedString {
    /// A copy with all transient display state removed: ghost-text ranges are
    /// deleted, analysis highlights are unwound (restoring recorded underline/
    /// background). Returns self when nothing transient exists.
    func strippingTransientAttributes() -> NSAttributedString {
        let fullRange = NSRange(location: 0, length: length)
        var ghostRanges: [NSRange] = []
        enumerateAttribute(.ghostText, in: fullRange) { value, range, _ in
            if value != nil {
                ghostRanges.append(range)
            }
        }
        var highlightRanges: [(NSRange, AnalysisMarker)] = []
        enumerateAttribute(.analysisHighlight, in: fullRange) { value, range, _ in
            if let marker = value as? AnalysisMarker {
                highlightRanges.append((range, marker))
            }
        }
        guard !ghostRanges.isEmpty || !highlightRanges.isEmpty else { return self }

        let mutable = NSMutableAttributedString(attributedString: self)
        for (range, marker) in highlightRanges {
            mutable.removeAttribute(.analysisHighlight, range: range)
            mutable.removeAttribute(.toolTip, range: range)
            mutable.removeAttribute(.underlineColor, range: range)
            if let previous = marker.previousUnderlineStyle {
                mutable.addAttribute(.underlineStyle, value: previous, range: range)
            } else {
                mutable.removeAttribute(.underlineStyle, range: range)
            }
            if let previous = marker.previousBackgroundColor {
                mutable.addAttribute(.backgroundColor, value: previous, range: range)
            } else {
                mutable.removeAttribute(.backgroundColor, range: range)
            }
        }
        for range in ghostRanges.reversed() {
            mutable.deleteCharacters(in: range)
        }
        return mutable
    }

    /// Compatibility alias for the original ghost-only strip.
    func strippingGhostText() -> NSAttributedString {
        strippingTransientAttributes()
    }
}
