import AppKit

/// Applies prose-analysis highlights to the text storage as display-only
/// attributes (tint + underline + tooltip), following the ghost-text rules:
/// undo registration disabled, coordinator suppression, and full restoration
/// of any user styling the highlight replaced.
final class AnalysisHighlighter {
    struct Style {
        var background: NSColor
        var underlineStyle: Int
        var underlineColor: NSColor
    }

    private weak var editorController: EditorController?

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
        var appliedTips: [(range: NSRange, message: String)] = []
        withProgrammaticMutation { storage in
            removeAll(from: storage)
            for highlight in highlights {
                if let visibleTypes, !visibleTypes.contains(highlight.type) { continue }
                let range = highlight.range
                guard range.location >= 0, range.location + range.length <= storage.length, range.length > 0 else { continue }
                // Skip any range overlapping an earlier highlight — first wins
                // (CSS-stacking parity), and overlap would poison the recorded
                // "previous" styling used for restoration.
                var overlapsExisting = false
                storage.enumerateAttribute(.analysisHighlight, in: range) { value, _, stop in
                    if value != nil {
                        overlapsExisting = true
                        stop.pointee = true
                    }
                }
                if overlapsExisting { continue }

                let previousUnderline = storage.attribute(.underlineStyle, at: range.location, effectiveRange: nil) as? Int
                let previousBackground = storage.attribute(.backgroundColor, at: range.location, effectiveRange: nil) as? NSColor
                let style = Self.style(for: highlight.type)
                var tooltip = highlight.message
                if let suggestion = highlight.suggestion {
                    tooltip += "\n\(suggestion)"
                }
                storage.addAttributes([
                    .analysisHighlight: AnalysisMarker(
                        previousUnderlineStyle: previousUnderline,
                        previousBackgroundColor: previousBackground
                    ),
                    .backgroundColor: style.background,
                    .underlineStyle: style.underlineStyle,
                    .underlineColor: style.underlineColor,
                ], range: range)
                appliedTips.append((range, tooltip))
            }
        }
        editorController?.textView?.setAnalysisToolTips(appliedTips)
    }

    func clear() {
        withProgrammaticMutation { storage in
            removeAll(from: storage)
        }
        editorController?.textView?.setAnalysisToolTips([])
    }

    private func removeAll(from storage: NSTextStorage) {
        var markers: [(NSRange, AnalysisMarker)] = []
        storage.enumerateAttribute(.analysisHighlight, in: NSRange(location: 0, length: storage.length)) { value, range, _ in
            if let marker = value as? AnalysisMarker {
                markers.append((range, marker))
            }
        }
        for (range, marker) in markers {
            storage.removeAttribute(.analysisHighlight, range: range)
            storage.removeAttribute(.toolTip, range: range)
            storage.removeAttribute(.underlineColor, range: range)
            if let previous = marker.previousUnderlineStyle {
                storage.addAttribute(.underlineStyle, value: previous, range: range)
            } else {
                storage.removeAttribute(.underlineStyle, range: range)
            }
            if let previous = marker.previousBackgroundColor {
                storage.addAttribute(.backgroundColor, value: previous, range: range)
            } else {
                storage.removeAttribute(.backgroundColor, range: range)
            }
        }
    }

    private func withProgrammaticMutation(_ body: (NSTextStorage) -> Void) {
        guard let controller = editorController,
              let textView = controller.textView,
              let storage = textView.textStorage
        else { return }
        controller.isPerformingProgrammaticMutation = true
        textView.undoManager?.disableUndoRegistration()
        storage.beginEditing()
        body(storage)
        storage.endEditing()
        textView.undoManager?.enableUndoRegistration()
        controller.isPerformingProgrammaticMutation = false
    }
}
