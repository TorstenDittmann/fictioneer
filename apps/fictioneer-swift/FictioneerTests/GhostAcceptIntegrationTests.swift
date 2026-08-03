import AppKit
import Testing
@testable import Fictioneer

/// End-to-end ghost pipeline against a real (windowless) TextKit 1 view:
/// ⌥ down → stream → ready → Tab must materialize the suggestion as normal
/// text and leave no ghost styling behind.
@MainActor
struct GhostAcceptIntegrationTests {
    @MainActor
    final class StreamBox {
        var continuation: AsyncThrowingStream<String, Error>.Continuation?
    }

    @Test func tabAcceptMaterializesSuggestion() async throws {
        let text = "It was a dark and stormy night and"
        let textView = FictioneerTextView(usingTextLayoutManager: false)
        textView.textStorage?.setAttributedString(NSAttributedString(string: text, attributes: [
            .font: NSFont.systemFont(ofSize: 18),
            .foregroundColor: NSColor.labelColor,
        ]))
        textView.setSelectedRange(NSRange(location: (text as NSString).length, length: 0))

        let editorController = EditorController()
        editorController.textView = textView
        let undoManager = UndoManager()
        textView.setUndoManagerOverride(undoManager)

        let box = StreamBox()
        let ghostController = GhostTextController(dotsInterval: 0.01, fadeDuration: 0.01) { _, _ in
            AsyncThrowingStream { continuation in
                Task { @MainActor in
                    box.continuation = continuation
                }
            }
        }
        let presenter = GhostTextPresenter(
            textView: textView,
            editorController: editorController,
            controller: ghostController,
            isEnabled: { true },
            contextInfo: { (nil, nil) }
        )
        _ = presenter // wiring happens in init

        textView.onOptionKeyChange?(true)
        for _ in 0..<400 where box.continuation == nil {
            try? await Task.sleep(for: .milliseconds(5))
        }
        let continuation = try #require(box.continuation)

        continuation.yield(" the wind howled.")
        continuation.finish()
        for _ in 0..<400 {
            if case .ready = ghostController.state { break }
            try? await Task.sleep(for: .milliseconds(5))
        }
        guard case .ready = ghostController.state else {
            Issue.record("controller never reached .ready: \(ghostController.state)")
            return
        }

        // Ghost is present in storage while ready…
        #expect(textView.string.contains("the wind howled."))

        // …Tab accepts.
        let consumed = textView.onGhostTab?() ?? false
        #expect(consumed)

        let final = textView.attributedString()
        #expect(final.string == text + " the wind howled.")

        // No ghost styling anywhere: no marker, and the accepted span uses
        // normal (non-transient) attributes.
        var ghostAttributeFound = false
        final.enumerateAttribute(.ghostText, in: NSRange(location: 0, length: final.length)) { value, _, _ in
            if value != nil { ghostAttributeFound = true }
        }
        #expect(!ghostAttributeFound)

        // labelColor is inherently ~0.85 alpha; ghost grey is 0.4 — assert we
        // ended up with the former, not the latter.
        let acceptedAttributes = final.attributes(at: final.length - 1, effectiveRange: nil)
        let color = acceptedAttributes[.foregroundColor] as? NSColor
        #expect(color?.alphaComponent ?? 1 > 0.6)

        // Single undoable action restores the original text.
        #expect(undoManager.canUndo)
        undoManager.undo()
        #expect(textView.string == text)
    }
}
