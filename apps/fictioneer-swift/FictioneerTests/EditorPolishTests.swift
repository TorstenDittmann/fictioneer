import AppKit
import Testing
@testable import Fictioneer

@MainActor
struct EditorPolishTests {
    private func makeTextView(_ text: String) -> (FictioneerTextView, NSWindow) {
        let textView = FictioneerTextView(usingTextLayoutManager: false)
        textView.isRichText = true
        textView.isVerticallyResizable = true
        textView.textContainer?.widthTracksTextView = true
        textView.textStorage?.setAttributedString(NSAttributedString(string: text))
        let scrollView = FictioneerScrollView()
        scrollView.documentView = textView
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 800, height: 600),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        window.contentView = scrollView
        scrollView.frame = window.contentView!.bounds
        textView.frame.size.width = 800
        return (textView, window)
    }

    private func isDimmed(_ textView: FictioneerTextView, at location: Int) -> Bool {
        textView.layoutManager?.temporaryAttribute(.foregroundColor, atCharacterIndex: location, effectiveRange: nil) != nil
    }

    @Test func focusDimmingFollowsCaretParagraph() {
        let (textView, window) = makeTextView("First paragraph.\nSecond paragraph.\nThird paragraph.")
        _ = window
        textView.setSelectedRange(NSRange(location: 20, length: 0))
        textView.dimsInactiveParagraphs = true

        #expect(isDimmed(textView, at: 2))
        #expect(!isDimmed(textView, at: 20))
        #expect(isDimmed(textView, at: 40))

        textView.setSelectedRange(NSRange(location: 2, length: 0))
        #expect(!isDimmed(textView, at: 2))
        #expect(isDimmed(textView, at: 20))

        textView.dimsInactiveParagraphs = false
        #expect(!isDimmed(textView, at: 20))
        #expect(!isDimmed(textView, at: 40))
    }

    @Test func dimmingNeverTouchesStoredText() {
        let (textView, window) = makeTextView("One.\nTwo.")
        _ = window
        textView.dimsInactiveParagraphs = true
        #expect(textView.textStorage?.attribute(.foregroundColor, at: 0, effectiveRange: nil) == nil)
    }

    @Test func selectionBarAppearsForSelectionsWithItems() async {
        let (textView, window) = makeTextView("A sentence worth rephrasing.")
        // The bar is placed from the selection's screen rect.
        window.orderFrontRegardless()
        defer { window.close() }
        let controller = EditorController()
        controller.textView = textView
        textView.selectionBarItems = { controller.formattingBarItems() }

        textView.setSelectedRange(NSRange(location: 2, length: 8))
        textView.scheduleSelectionBarUpdate()
        try? await Task.sleep(for: .milliseconds(450))
        #expect(textView.subviews.contains { $0 is SelectionBarHostView })

        textView.dismissSelectionBar()
        textView.selectionBarItems = { [] }
        textView.scheduleSelectionBarUpdate()
        try? await Task.sleep(for: .milliseconds(450))
        #expect(!textView.subviews.contains { $0 is SelectionBarHostView })
    }

    @Test func formattingItemsCoverCharacterStylesAndQuote() {
        let ids = EditorController().formattingBarItems().map(\.id)
        #expect(ids == ["bold", "italic", "underline", "quote"])
        #expect(EditorController().formattingBarItems().allSatisfy { $0.keepsBarOpen })
    }
}
