import AppKit
import Testing
@testable import Fictioneer

struct AnalysisHighlighterTests {
    private func makeEditor(text: String) -> (FictioneerTextView, EditorController) {
        let textView = FictioneerTextView(usingTextLayoutManager: true)
        textView.textStorage?.setAttributedString(NSAttributedString(string: text, attributes: [
            .font: NSFont.systemFont(ofSize: 18),
        ]))
        let controller = EditorController()
        controller.textView = textView
        return (textView, controller)
    }

    @Test func applyThenStripRestoresOriginalArchive() throws {
        let text = "She ran very quickly. It was a dark and stormy night."
        let (textView, controller) = makeEditor(text: text)
        let original = try TextArchive.data(from: textView.attributedString())

        let result = TextAnalysisEngine.analyze(text)
        #expect(!result.highlights.isEmpty)
        let highlighter = AnalysisHighlighter(editorController: controller)
        highlighter.apply(result.highlights, visibleTypes: nil)

        // Highlights are visible in storage…
        var highlightCount = 0
        textView.textStorage?.enumerateAttribute(
            .analysisHighlight,
            in: NSRange(location: 0, length: textView.textStorage!.length)
        ) { value, _, _ in
            if value != nil { highlightCount += 1 }
        }
        #expect(highlightCount > 0)

        // …the persisted form is semantically identical to pre-highlight
        // content (run boundaries may differ; attributes must not).
        let originalString = try TextArchive.attributedString(from: original)
        let stripped = textView.attributedString().strippingTransientAttributes()
        #expect(stripped.isEqual(to: originalString))

        // …and clear() restores the live storage too.
        highlighter.clear()
        #expect(textView.attributedString().isEqual(to: originalString))
    }

    @Test func applyRegistersNoUndoActions() {
        let text = "He was followed by shadows. It was a dark and stormy night."
        let (textView, controller) = makeEditor(text: text)
        let undoManager = UndoManager()
        textView.setUndoManagerOverride(undoManager)

        let result = TextAnalysisEngine.analyze(text)
        let highlighter = AnalysisHighlighter(editorController: controller)
        highlighter.apply(result.highlights, visibleTypes: nil)
        highlighter.clear()
        #expect(!undoManager.canUndo)
    }

    @Test func visibleTypesFilterApplies() {
        let text = "It was a dark and stormy night. She ran quickly."
        let (textView, controller) = makeEditor(text: text)
        let result = TextAnalysisEngine.analyze(text)
        let highlighter = AnalysisHighlighter(editorController: controller)
        highlighter.apply(result.highlights, visibleTypes: [.cliche])

        var types: Set<String> = []
        textView.textStorage?.enumerateAttribute(
            .analysisHighlight,
            in: NSRange(location: 0, length: textView.textStorage!.length)
        ) { value, range, _ in
            if value != nil {
                types.insert((textView.textStorage!.string as NSString).substring(with: range).lowercased())
            }
        }
        #expect(types.contains { $0.contains("dark and stormy") })
        #expect(!types.contains("quickly"))
    }
}

extension FictioneerTextView {
    /// Test hook: NSTextView asks its delegate/window for an undo manager;
    /// standalone views have none, so tests inject one.
    func setUndoManagerOverride(_ manager: UndoManager) {
        testUndoManager = manager
    }
}
