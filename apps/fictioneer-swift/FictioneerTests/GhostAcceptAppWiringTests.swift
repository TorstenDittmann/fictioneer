import AppKit
import Testing
@testable import Fictioneer

/// Reproduces the ghost-accept flow with the FULL app wiring (offscreen
/// window, scroll view, coordinator delegate, theme, analysis attach, real
/// Tab key event) — the minimal harness version passes while the live app
/// leaves a ghost-styled run behind, so the difference must live here.
@MainActor
struct GhostAcceptAppWiringTests {
    @MainActor
    final class StreamBox {
        var continuation: AsyncThrowingStream<String, Error>.Continuation?
    }

    @Test func tabAcceptLeavesNoGhostRunsUnderFullWiring() async throws {
        let text = "It was a dark and stormy night and"

        // Mirror RichTextEditor.makeNSView.
        let textView = FictioneerTextView(usingTextLayoutManager: false)
        textView.isRichText = true
        textView.allowsUndo = true
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.autoresizingMask = [.width]
        textView.minSize = .zero
        textView.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        textView.textContainer?.widthTracksTextView = true

        let editorController = EditorController()
        let coordinator = RichTextEditor.Coordinator(controller: editorController) { _ in }
        textView.delegate = coordinator

        textView.textStorage?.setAttributedString(NSAttributedString(string: text, attributes: [
            .font: NSFont.systemFont(ofSize: 18),
            .foregroundColor: NSColor.labelColor,
        ]))
        editorController.textView = textView

        let suiteName = "ghost-wiring-\(UUID().uuidString)"
        let settings = AppSettings(defaults: UserDefaults(suiteName: suiteName)!)
        editorController.applyTheme(EditorTheme(settings: settings))

        let analysis = AnalysisCoordinator()
        analysis.attach(editorController: editorController, settings: settings)

        let scrollView = FictioneerScrollView()
        scrollView.documentView = textView
        scrollView.automaticallyAdjustsContentInsets = false
        scrollView.contentInsets = NSEdgeInsets()

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 800, height: 600),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        window.contentView = scrollView
        scrollView.frame = window.contentView!.bounds
        window.makeFirstResponder(textView)
        textView.setSelectedRange(NSRange(location: (text as NSString).length, length: 0))

        let box = StreamBox()
        let ghostController = GhostTextController(dotsInterval: 0.01, fadeDuration: 0.01) { _, _ in
            AsyncThrowingStream { continuation in
                Task { @MainActor in
                    box.continuation = continuation
                }
            }
        }
        editorController.ghostPresenter = GhostTextPresenter(
            textView: textView,
            editorController: editorController,
            controller: ghostController,
            isEnabled: { true },
            contextInfo: { (nil, nil) }
        )

        textView.onOptionKeyChange?(true)
        for _ in 0..<400 where box.continuation == nil {
            try? await Task.sleep(for: .milliseconds(5))
        }
        let continuation = try #require(box.continuation)
        continuation.yield(" the wind howled through the empty street.")
        continuation.finish()
        for _ in 0..<400 {
            if case .ready = ghostController.state { break }
            try? await Task.sleep(for: .milliseconds(5))
        }
        guard case .ready = ghostController.state else {
            Issue.record("controller never reached .ready: \(ghostController.state)")
            return
        }

        // Real Tab key event through keyDown, like the live app.
        let tab = NSEvent.keyEvent(
            with: .keyDown, location: .zero, modifierFlags: [.option], timestamp: 0,
            windowNumber: window.windowNumber, context: nil,
            characters: "\t", charactersIgnoringModifiers: "\t", isARepeat: false, keyCode: 48
        )!
        textView.keyDown(with: tab)

        let final = textView.attributedString()
        var ghostRuns = 0
        final.enumerateAttribute(.ghostText, in: NSRange(location: 0, length: final.length)) { value, _, _ in
            if value != nil { ghostRuns += 1 }
        }
        #expect(ghostRuns == 0)
        #expect(final.string == text + " the wind howled through the empty street.")

        let lastAttributes = final.attributes(at: final.length - 1, effectiveRange: nil)
        let alpha = (lastAttributes[.foregroundColor] as? NSColor)?.alphaComponent ?? -1
        #expect(alpha > 0.6, "accepted text must not keep ghost dimming (alpha \(alpha))")
    }
}
