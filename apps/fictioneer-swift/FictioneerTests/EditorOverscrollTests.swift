import AppKit
import SwiftUI
import Testing
@testable import Fictioneer

/// The last line must always be scrollable up to the middle of the viewport,
/// however the content got there (load, width change, programmatic edit).
@MainActor
struct EditorOverscrollTests {
    private struct Harness {
        let textView: FictioneerTextView
        let scrollView: FictioneerScrollView
        let window: NSWindow
    }

    private func makeHarness(text: String, width: CGFloat = 800, height: CGFloat = 600) -> Harness {
        // Mirror RichTextEditor.makeNSView.
        let textView = FictioneerTextView(usingTextLayoutManager: false)
        textView.isRichText = true
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.autoresizingMask = [.width]
        textView.minSize = .zero
        textView.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        textView.textContainer?.widthTracksTextView = true
        textView.textStorage?.setAttributedString(NSAttributedString(string: text, attributes: [
            .font: NSFont.systemFont(ofSize: 18),
        ]))

        let scrollView = FictioneerScrollView()
        scrollView.documentView = textView
        scrollView.automaticallyAdjustsContentInsets = false
        scrollView.contentInsets = NSEdgeInsets()

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: width, height: height),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        window.contentView = scrollView
        scrollView.frame = window.contentView!.bounds
        return Harness(textView: textView, scrollView: scrollView, window: window)
    }

    /// Where the last line's bottom sits, measured from the viewport top,
    /// when scrolled all the way down.
    private func lastLineOffsetAtMaxScroll(_ harness: Harness) -> CGFloat {
        let textView = harness.textView
        let layoutManager = textView.layoutManager!
        layoutManager.ensureLayout(for: textView.textContainer!)
        let lastLineBottom = layoutManager.usedRect(for: textView.textContainer!).maxY
            + textView.textContainerOrigin.y
        let clipHeight = harness.scrollView.contentView.bounds.height
        let maxScroll = max(0, textView.frame.height - clipHeight)
        return lastLineBottom - maxScroll
    }

    private func settle() async {
        for _ in 0..<5 {
            await Task.yield()
            try? await Task.sleep(for: .milliseconds(5))
        }
    }

    private static let longText = Array(repeating: "A paragraph of prose that wraps across a line or two.", count: 60)
        .joined(separator: "\n\n")

    @Test func lastLineReachesMiddleAfterLoad() async {
        let harness = makeHarness(text: Self.longText)
        await settle()
        #expect(lastLineOffsetAtMaxScroll(harness) <= harness.scrollView.contentView.bounds.height / 2)
    }

    @Test func lastLineReachesMiddleAfterNarrowing() async {
        let harness = makeHarness(text: Self.longText, width: 1400)
        await settle()
        harness.window.setContentSize(NSSize(width: 500, height: 600))
        harness.scrollView.frame = harness.window.contentView!.bounds
        await settle()
        #expect(lastLineOffsetAtMaxScroll(harness) <= harness.scrollView.contentView.bounds.height / 2)
    }

    @Test func pageHeaderSitsAboveTextAndKeepsOverscroll() async {
        let harness = makeHarness(text: Self.longText)
        await settle()
        let originBefore = harness.textView.textContainerOrigin.y

        let header = NSTextField(labelWithString: "An Evening Reunion")
        header.font = .boldSystemFont(ofSize: 28)
        harness.textView.pageHeaderView = header
        await settle()

        let headerHeight = ceil(header.fittingSize.height)
        #expect(header.superview === harness.textView)
        #expect(header.frame.minY == harness.textView.textContainerInset.height)
        #expect(harness.textView.textContainerOrigin.y == originBefore + headerHeight + 28)
        #expect(lastLineOffsetAtMaxScroll(harness) <= harness.scrollView.contentView.bounds.height / 2)

        harness.textView.pageHeaderView = nil
        await settle()
        #expect(header.superview == nil)
        #expect(harness.textView.textContainerOrigin.y == originBefore)
    }

    @Test func lastLineReachesMiddleAfterProgrammaticAppend() async {
        let harness = makeHarness(text: Self.longText)
        await settle()
        let more = NSAttributedString(string: "\n\n" + Self.longText, attributes: [.font: NSFont.systemFont(ofSize: 18)])
        harness.textView.textStorage?.append(more)
        await settle()
        #expect(lastLineOffsetAtMaxScroll(harness) <= harness.scrollView.contentView.bounds.height / 2)
    }
}

/// Same guarantee through the real SwiftUI wrapper, as the app hosts it.
@MainActor
struct HostedEditorOverscrollTests {
    @Test func lastLineReachesMiddleInHostedEditor() async throws {
        let text = Array(repeating: "A paragraph of prose that wraps across a line or two.", count: 60)
            .joined(separator: "\n\n")
        let settings = AppSettings(defaults: UserDefaults(suiteName: "overscroll-\(UUID().uuidString)")!)
        let controller = EditorController()
        let editor = RichTextEditor(
            initialContent: NSAttributedString(string: text),
            settings: settings,
            controller: controller,
            onContentChange: { _ in }
        )
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 900, height: 700),
            styleMask: [.titled, .resizable],
            backing: .buffered,
            defer: false
        )
        window.contentView = NSHostingView(rootView: editor.frame(maxWidth: .infinity, maxHeight: .infinity))
        window.orderFront(nil)
        defer { window.close() }

        for _ in 0..<20 {
            await Task.yield()
            try? await Task.sleep(for: .milliseconds(10))
        }

        let textView = try #require(controller.textView as? FictioneerTextView)
        try expectLastLineReachesMiddle(textView)

        // A layout pass with no text change (window resize) must not drop it.
        window.setContentSize(NSSize(width: 1100, height: 800))
        window.contentView?.layoutSubtreeIfNeeded()
        try expectLastLineReachesMiddle(textView)
    }

    private func expectLastLineReachesMiddle(_ textView: FictioneerTextView) throws {
        let scrollView = try #require(textView.enclosingScrollView)
        let layoutManager = try #require(textView.layoutManager)
        let container = try #require(textView.textContainer)
        layoutManager.ensureLayout(for: container)
        let lastLineBottom = layoutManager.usedRect(for: container).maxY + textView.textContainerOrigin.y
        let clipHeight = scrollView.contentView.bounds.height
        let maxScroll = max(0, textView.frame.height - clipHeight)
        #expect(clipHeight > 100)
        #expect(lastLineBottom - maxScroll <= clipHeight / 2)
    }
}
