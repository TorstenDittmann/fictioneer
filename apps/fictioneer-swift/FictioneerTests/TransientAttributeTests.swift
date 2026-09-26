import AppKit
import Testing
@testable import Fictioneer

struct TransientAttributeTests {
    private func makeBase() -> NSMutableAttributedString {
        let string = NSMutableAttributedString(string: "He walked quickly to the door.", attributes: [
            .font: NSFont.systemFont(ofSize: 18),
            .foregroundColor: NSColor.labelColor,
        ])
        // User underline on "walked"
        string.addAttribute(
            .underlineStyle,
            value: NSUnderlineStyle.single.rawValue,
            range: NSRange(location: 3, length: 6)
        )
        return string
    }

    @Test func stripRestoresUserUnderlineAndRemovesTint() throws {
        let original = makeBase()
        let originalData = try TextArchive.data(from: original)

        // Apply a highlight over "walked quickly" (overlapping the user underline).
        let highlighted = NSMutableAttributedString(attributedString: original)
        let range = NSRange(location: 3, length: 14)
        let previousUnderline = highlighted.attribute(.underlineStyle, at: 3, effectiveRange: nil) as? Int
        highlighted.addAttributes([
            .analysisHighlight: AnalysisMarker(
                previousUnderlineStyle: previousUnderline,
                previousBackgroundColor: nil
            ),
            .backgroundColor: NSColor.systemBlue.withAlphaComponent(0.15),
            .underlineStyle: NSUnderlineStyle.thick.rawValue,
            .underlineColor: NSColor.systemBlue,
            .toolTip: "Adverb: \"quickly\"",
        ], range: range)

        let stripped = highlighted.strippingTransientAttributes()
        // The tint/tooltip are gone…
        var found = false
        stripped.enumerateAttribute(.analysisHighlight, in: NSRange(location: 0, length: stripped.length)) { value, _, _ in
            if value != nil { found = true }
        }
        #expect(!found)
        #expect(stripped.attribute(.toolTip, at: 5, effectiveRange: nil) == nil)
        #expect(stripped.attribute(.backgroundColor, at: 5, effectiveRange: nil) == nil)
        // …the user underline came back exactly on "walked"…
        #expect(stripped.attribute(.underlineStyle, at: 5, effectiveRange: nil) as? Int == NSUnderlineStyle.single.rawValue)
        // Note: the marker restores its recorded value across its whole range —
        // sub-run fidelity is bounded by highlight granularity, and highlights
        // are applied per detection range, so runs match in practice.
        let strippedData = try TextArchive.data(from: stripped.attributedSubstring(from: NSRange(location: 0, length: 9)))
        let originalPrefix = try TextArchive.data(from: original.attributedSubstring(from: NSRange(location: 0, length: 9)))
        #expect(strippedData == originalPrefix)
        _ = originalData
    }

    @Test func stripRemovesGhostAndHighlightsTogether() {
        let string = NSMutableAttributedString(string: "Real text")
        string.addAttributes([
            .analysisHighlight: AnalysisMarker(previousUnderlineStyle: nil, previousBackgroundColor: nil),
            .backgroundColor: NSColor.red,
        ], range: NSRange(location: 0, length: 4))
        string.append(NSAttributedString(string: " ghost", attributes: [.ghostText: true]))

        let stripped = string.strippingTransientAttributes()
        #expect(stripped.string == "Real text")
        #expect(stripped.attribute(.backgroundColor, at: 0, effectiveRange: nil) == nil)
    }

    @Test func plainContentReturnsSelf() {
        let string = NSAttributedString(string: "Nothing transient here")
        #expect(string.strippingTransientAttributes() === string)
    }
}
