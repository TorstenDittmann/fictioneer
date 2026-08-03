import AppKit
import SwiftUI

/// Scroll view that forwards clicks landing outside the document view (the
/// typewriter overscroll region) into the text view — caret to end, focused.
final class FictioneerScrollView: NSScrollView {
    override func mouseDown(with event: NSEvent) {
        if let textView = documentView as? FictioneerTextView {
            let pointInDocument = textView.convert(event.locationInWindow, from: nil)
            if !textView.bounds.contains(pointInDocument) {
                window?.makeFirstResponder(textView)
                textView.setSelectedRange(NSRange(location: (textView.string as NSString).length, length: 0))
                textView.centerCaret()
                return
            }
        }
        super.mouseDown(with: event)
    }
}

struct RichTextEditor: NSViewRepresentable {
    let initialContent: NSAttributedString
    let settings: AppSettings
    let controller: EditorController
    var configureGhost: ((FictioneerTextView, EditorController) -> Void)?
    let onContentChange: (NSAttributedString) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(controller: controller, onContentChange: onContentChange)
    }

    func makeNSView(context: Context) -> NSScrollView {
        // TextKit 1 compatibility mode, deliberately: TK2's view layer caused
        // a long tail of display bugs (fragment repaint, clip-tile insets),
        // and TK1's temporary attributes are the purpose-built mechanism for
        // the prose highlights. No feature here needs TK2.
        let textView = FictioneerTextView(usingTextLayoutManager: false)
        textView.isRichText = true
        textView.allowsUndo = true
        textView.importsGraphics = false
        textView.usesFontPanel = false
        textView.usesFindPanel = true
        textView.isAutomaticQuoteSubstitutionEnabled = true
        textView.isAutomaticDashSubstitutionEnabled = true
        textView.isAutomaticSpellingCorrectionEnabled = false
        textView.isContinuousSpellCheckingEnabled = true
        textView.drawsBackground = false
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.autoresizingMask = [.width]
        textView.minSize = .zero
        textView.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        textView.textContainer?.widthTracksTextView = true
        textView.insertionPointColor = .controlAccentColor
        textView.delegate = context.coordinator

        textView.textStorage?.setAttributedString(initialContent)
        controller.textView = textView
        controller.applyTheme(EditorTheme(settings: settings))
        configureGhost?(textView, controller)

        let scrollView = FictioneerScrollView()
        scrollView.documentView = textView
        scrollView.hasVerticalScroller = true
        scrollView.autohidesScrollers = true
        scrollView.drawsBackground = true
        scrollView.backgroundColor = EditorTheme.paperBackground
        // Typewriter overscroll comes from stretching the text view itself —
        // never from contentInsets, which on macOS shrink the clip view tile.
        scrollView.automaticallyAdjustsContentInsets = false
        scrollView.contentInsets = NSEdgeInsets()

        DispatchQueue.main.async {
            textView.window?.makeFirstResponder(textView)
            textView.setSelectedRange(NSRange(location: textView.string.utf16.count, length: 0))
            textView.scrollRangeToVisible(textView.selectedRange())
        }
        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        // Reading the settings properties here registers Observation dependencies,
        // so font/size/line-height changes re-invoke this and re-theme in place.
        let theme = EditorTheme(settings: settings)
        if theme != controller.theme {
            controller.applyTheme(theme)
        }
    }

    @MainActor
    final class Coordinator: NSObject, NSTextViewDelegate {
        let controller: EditorController
        let onContentChange: (NSAttributedString) -> Void

        init(controller: EditorController, onContentChange: @escaping (NSAttributedString) -> Void) {
            self.controller = controller
            self.onContentChange = onContentChange
        }

        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? FictioneerTextView else { return }
            guard !controller.isPerformingProgrammaticMutation else { return }
            controller.notifyDocumentEdit()
            onContentChange(textView.attributedString().strippingTransientAttributes())
            textView.centerCaret()
        }

        func textViewDidChangeSelection(_ notification: Notification) {
            guard !controller.isPerformingProgrammaticMutation else { return }
            controller.hasSelection = (notification.object as? NSTextView)?.selectedRange().length ?? 0 > 0
            controller.notifySelectionChange()
        }

        func textView(_ textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
            // Pressing return in a heading starts a fresh body paragraph (Tiptap parity).
            if commandSelector == #selector(NSResponder.insertNewline(_:)),
               textView.typingAttributes[.headingLevel] != nil,
               let theme = controller.theme {
                textView.insertText("\n", replacementRange: textView.selectedRange())
                textView.typingAttributes = theme.bodyAttributes
                return true
            }
            return false
        }
    }
}
