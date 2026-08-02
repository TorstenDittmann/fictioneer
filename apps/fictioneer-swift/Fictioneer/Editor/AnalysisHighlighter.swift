import AppKit

/// Applies prose-analysis highlights as TextKit 2 *rendering attributes* —
/// display-only decoration that never enters the text storage.
///
/// This is deliberate: storage attributes (even plain underlines) participate
/// in TextKit 2 layout measurement, so applying them grew the scrollable area
/// and shifted the view when toggling highlights — and they dragged along a
/// train of mitigations (undo isolation, save-path stripping, scroll pinning).
/// Rendering attributes are layout-neutral by contract (spell-check squiggles
/// use the same mechanism) and are invisible to undo, autosave, and export.
final class AnalysisHighlighter {
    struct Style {
        var background: NSColor
        var underlineStyle: Int
        var underlineColor: NSColor
    }

    private weak var editorController: EditorController?

    /// Ranges decorated in the last pass (UTF-16 storage offsets).
    private(set) var appliedRanges: [NSRange] = []

    init(editorController: EditorController) {
        self.editorController = editorController
    }

    static func style(for type: AnalysisType) -> Style {
        func rgb(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat, _ alpha: CGFloat) -> NSColor {
            NSColor(srgbRed: r / 255, green: g / 255, blue: b / 255, alpha: alpha)
        }
        let single = NSUnderlineStyle.single.rawValue
        let dashed = NSUnderlineStyle.single.rawValue | NSUnderlineStyle.patternDash.rawValue
        let dotted = NSUnderlineStyle.single.rawValue | NSUnderlineStyle.patternDot.rawValue
        switch type {
        case .adverb:
            return Style(background: rgb(59, 130, 246, 0.15), underlineStyle: single, underlineColor: rgb(59, 130, 246, 0.5))
        case .passiveVoice:
            return Style(background: rgb(245, 158, 11, 0.15), underlineStyle: single, underlineColor: rgb(245, 158, 11, 0.5))
        case .filterWord:
            return Style(background: rgb(168, 85, 247, 0.15), underlineStyle: single, underlineColor: rgb(168, 85, 247, 0.5))
        case .repetition:
            return Style(background: rgb(249, 115, 22, 0.15), underlineStyle: single, underlineColor: rgb(249, 115, 22, 0.5))
        case .weakVerb:
            return Style(background: rgb(236, 72, 153, 0.15), underlineStyle: single, underlineColor: rgb(236, 72, 153, 0.5))
        case .longSentence:
            return Style(background: rgb(239, 68, 68, 0.10), underlineStyle: single, underlineColor: rgb(239, 68, 68, 0.4))
        case .sentenceStarter:
            return Style(background: rgb(20, 184, 166, 0.15), underlineStyle: single, underlineColor: rgb(20, 184, 166, 0.5))
        case .cliche:
            return Style(background: rgb(217, 119, 6, 0.15), underlineStyle: dashed, underlineColor: rgb(217, 119, 6, 0.6))
        case .vagueWord:
            return Style(background: rgb(107, 114, 128, 0.15), underlineStyle: dotted, underlineColor: rgb(107, 114, 128, 0.5))
        }
    }

    func apply(_ highlights: [AnalysisHighlight], visibleTypes: Set<AnalysisType>?) {
        guard let textView = editorController?.textView,
              let layoutManager = textView.textLayoutManager else { return }
        clearRenderingAttributes(layoutManager)

        let length = (textView.string as NSString).length
        var applied: [AnalysisHighlight] = []
        for highlight in highlights {
            if let visibleTypes, !visibleTypes.contains(highlight.type) { continue }
            let range = highlight.range
            guard range.location >= 0, range.length > 0, range.location + range.length <= length else { continue }
            // First-wins on overlap (CSS-stacking parity with the Tauri app).
            guard !appliedRanges.contains(where: { NSIntersectionRange($0, range).length > 0 }) else { continue }
            guard let textRange = Self.textRange(range, in: layoutManager) else { continue }

            let style = Self.style(for: highlight.type)
            layoutManager.setRenderingAttributes([
                .backgroundColor: style.background,
                .underlineStyle: style.underlineStyle,
                .underlineColor: style.underlineColor,
            ], for: textRange)
            appliedRanges.append(range)
            applied.append(highlight)
        }
        textView.needsDisplay = true
        updateMarginAnnotations(for: applied)
    }

    func clear() {
        guard let textView = editorController?.textView else { return }
        if let layoutManager = textView.textLayoutManager {
            clearRenderingAttributes(layoutManager)
        }
        textView.needsDisplay = true
        textView.setMarginAnnotations([])
    }

    private func clearRenderingAttributes(_ layoutManager: NSTextLayoutManager) {
        let document = layoutManager.documentRange
        layoutManager.removeRenderingAttribute(.backgroundColor, for: document)
        layoutManager.removeRenderingAttribute(.underlineStyle, for: document)
        layoutManager.removeRenderingAttribute(.underlineColor, for: document)
        // Removal alone doesn't repaint fragments that already rendered the
        // decoration — invalidation drops the cached rendering attributes and
        // marks the affected fragments for redisplay.
        layoutManager.invalidateRenderingAttributes(for: document)
        appliedRanges = []
    }

    private static func textRange(_ range: NSRange, in layoutManager: NSTextLayoutManager) -> NSTextRange? {
        guard let contentManager = layoutManager.textContentManager else { return nil }
        let document = contentManager.documentRange
        guard let start = contentManager.location(document.location, offsetBy: range.location),
              let end = contentManager.location(start, offsetBy: range.length)
        else { return nil }
        return NSTextRange(location: start, end: end)
    }

    private func updateMarginAnnotations(for applied: [AnalysisHighlight]) {
        guard let textView = editorController?.textView else { return }
        guard let window = textView.window else {
            textView.setMarginAnnotations([])
            return
        }
        let annotations = AnalysisMarginGrouping.groupIntoLines(applied) { range in
            let screenRect = textView.firstRect(forCharacterRange: range, actualRange: nil)
            let rect = textView.convert(window.convertFromScreen(screenRect), from: nil)
            return Int(rect.minY.rounded())
        }
        textView.setMarginAnnotations(annotations)
    }
}
