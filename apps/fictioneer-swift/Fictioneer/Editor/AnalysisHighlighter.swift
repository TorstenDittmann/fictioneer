import AppKit

/// Applies prose-analysis highlights as NSLayoutManager *temporary
/// attributes* (TextKit 1) — the purpose-built mechanism for display-only,
/// layout-neutral decoration with immediate repaint; spell-check squiggles
/// use the same path. Temporary attributes never enter the text storage, so
/// they are invisible to undo, autosave, word counts, and export.
final class AnalysisHighlighter {
    struct Style {
        var background: NSColor
        var underlineStyle: Int
        var underlineColor: NSColor
    }

    /// Experiment: issue details appear as hover cards on the highlighted
    /// text itself; the margin pills are disabled while this is on.
    static let useMarginChips = false

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
              let layoutManager = textView.layoutManager else { return }
        removeAllTemporaryAttributes(layoutManager, length: (textView.string as NSString).length)

        let length = (textView.string as NSString).length
        var applied: [AnalysisHighlight] = []
        for highlight in highlights {
            if let visibleTypes, !visibleTypes.contains(highlight.type) { continue }
            let range = highlight.range
            guard range.location >= 0, range.length > 0, range.location + range.length <= length else { continue }
            // First-wins on overlap (CSS-stacking parity with the Tauri app).
            guard !appliedRanges.contains(where: { NSIntersectionRange($0, range).length > 0 }) else { continue }

            let style = Self.style(for: highlight.type)
            layoutManager.addTemporaryAttributes([
                .backgroundColor: style.background,
                .underlineStyle: style.underlineStyle,
                .underlineColor: style.underlineColor,
            ], forCharacterRange: range)
            appliedRanges.append(range)
            applied.append(highlight)
        }
        textView.setHoverHighlights(applied.map { highlight in
            (highlight.range, [MarginIssue(type: highlight.type, message: highlight.message, suggestion: highlight.suggestion)])
        })
        if Self.useMarginChips {
            updateMarginAnnotations(for: applied)
        }
    }

    func clear() {
        guard let textView = editorController?.textView else { return }
        if let layoutManager = textView.layoutManager {
            removeAllTemporaryAttributes(layoutManager, length: (textView.string as NSString).length)
        }
        textView.setHoverHighlights([])
        textView.setMarginAnnotations([])
    }

    private func removeAllTemporaryAttributes(_ layoutManager: NSLayoutManager, length: Int) {
        let document = NSRange(location: 0, length: length)
        layoutManager.removeTemporaryAttribute(.backgroundColor, forCharacterRange: document)
        layoutManager.removeTemporaryAttribute(.underlineStyle, forCharacterRange: document)
        layoutManager.removeTemporaryAttribute(.underlineColor, forCharacterRange: document)
        appliedRanges = []
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
