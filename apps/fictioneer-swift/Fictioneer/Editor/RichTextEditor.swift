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
    /// Vetoes user edits by range and replacement (the continuous chapter
    /// protects its scene headings). nil allows everything.
    var shouldChangeText: ((NSRange, String?, NSAttributedString) -> Bool)?
    /// Where to put the caret on first appearance; nil: end of the text.
    var initialSelection: (() -> NSRange?)?
    /// A click on an attachment (scene headings): its character index and
    /// frame in the text view.
    var onAttachmentClick: ((Int, NSRect) -> Void)?
    let onContentChange: (NSAttributedString) -> Void

    func makeCoordinator() -> Coordinator {
        let coordinator = Coordinator(controller: controller, shouldChangeText: shouldChangeText, onContentChange: onContentChange)
        coordinator.onAttachmentClick = onAttachmentClick
        return coordinator
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
        // Quotes follow the project's style (FictioneerTextView.quoteStyle),
        // not the system language.
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = true
        textView.isAutomaticSpellingCorrectionEnabled = false
        textView.isContinuousSpellCheckingEnabled = settings.spellcheckEnabled
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
            let selection = initialSelection?() ?? NSRange(location: textView.string.utf16.count, length: 0)
            textView.setSelectedRange(selection)
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

        if let textView = scrollView.documentView as? FictioneerTextView,
           textView.isContinuousSpellCheckingEnabled != settings.spellcheckEnabled {
            textView.isContinuousSpellCheckingEnabled = settings.spellcheckEnabled
        }
    }

    @MainActor
    final class Coordinator: NSObject, NSTextViewDelegate {
        let controller: EditorController
        let shouldChangeText: ((NSRange, String?, NSAttributedString) -> Bool)?
        let onContentChange: (NSAttributedString) -> Void
        var onAttachmentClick: ((Int, NSRect) -> Void)?

        func textView(_ textView: NSTextView, clickedOn cell: any NSTextAttachmentCellProtocol, in cellFrame: NSRect, at charIndex: Int) {
            onAttachmentClick?(charIndex, cellFrame)
        }

        init(
            controller: EditorController,
            shouldChangeText: ((NSRange, String?, NSAttributedString) -> Bool)? = nil,
            onContentChange: @escaping (NSAttributedString) -> Void
        ) {
            self.controller = controller
            self.shouldChangeText = shouldChangeText
            self.onContentChange = onContentChange
        }

        func textView(_ textView: NSTextView, shouldChangeTextIn affectedCharRange: NSRange, replacementString: String?) -> Bool {
            guard let shouldChangeText, !controller.isPerformingProgrammaticMutation,
                  let storage = textView.textStorage else { return true }
            let allowed = shouldChangeText(affectedCharRange, replacementString, storage)
            if !allowed { NSSound.beep() }
            return allowed
        }

        /// Text typed right after a protected scene heading must not inherit
        /// its centered heading style or boundary marker.
        func textView(
            _ textView: NSTextView,
            shouldChangeTypingAttributes oldTypingAttributes: [String: Any],
            toAttributes newTypingAttributes: [NSAttributedString.Key: Any]
        ) -> [NSAttributedString.Key: Any] {
            guard newTypingAttributes[.sceneBoundary] != nil else { return newTypingAttributes }
            return controller.theme?.bodyAttributes ?? newTypingAttributes.filter { $0.key != .sceneBoundary && $0.key != .attachment }
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
