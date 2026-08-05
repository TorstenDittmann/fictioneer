import AppKit
import Testing
@testable import Fictioneer

struct AnalysisHighlighterTests {
    private func makeEditor(text: String) -> (FictioneerTextView, EditorController) {
        let textView = FictioneerTextView(usingTextLayoutManager: false)
        textView.textStorage?.setAttributedString(NSAttributedString(string: text, attributes: [
            .font: NSFont.systemFont(ofSize: 18),
        ]))
        let controller = EditorController()
        controller.textView = textView
        return (textView, controller)
    }

    @Test func applyNeverTouchesTextStorage() throws {
        let text = "She ran very quickly. It was a dark and stormy night."
        let (textView, controller) = makeEditor(text: text)
        let original = try TextArchive.data(from: textView.attributedString())

        let result = TextAnalysisEngine.analyze(text)
        #expect(!result.highlights.isEmpty)
        let highlighter = AnalysisHighlighter(editorController: controller)
        highlighter.apply(result.highlights, visibleTypes: nil)

        // Highlights are rendering attributes only…
        #expect(!highlighter.appliedRanges.isEmpty)

        // …so the storage is byte-identical to the pre-highlight archive,
        // both while applied and after clearing.
        let after = try TextArchive.data(from: textView.attributedString())
        #expect(after == original)
        highlighter.clear()
        #expect(highlighter.appliedRanges.isEmpty)
        let cleared = try TextArchive.data(from: textView.attributedString())
        #expect(cleared == original)
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

        let decorated = highlighter.appliedRanges.map {
            (textView.string as NSString).substring(with: $0).lowercased()
        }
        #expect(decorated.contains { $0.contains("dark and stormy") })
        #expect(!decorated.contains("quickly"))
    }
}

extension FictioneerTextView {
    /// Test hook: NSTextView asks its delegate/window for an undo manager;
    /// standalone views have none, so tests inject one.
    func setUndoManagerOverride(_ manager: UndoManager) {
        testUndoManager = manager
    }
}
