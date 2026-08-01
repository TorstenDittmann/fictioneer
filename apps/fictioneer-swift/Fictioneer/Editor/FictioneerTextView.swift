import AppKit

/// NSTextView subclass with key hooks for the ghost-text feature and the
/// centered writing column / typewriter scrolling behavior.
final class FictioneerTextView: NSTextView {
    /// Ghost-text hooks, wired by GhostTextPresenter. Return true to consume the key.
    var onGhostTab: (() -> Bool)?
    var onGhostEscape: (() -> Bool)?
    var onOptionKeyChange: ((Bool) -> Void)?

    /// Serif-italic font for the empty-document placeholder, kept in sync
    /// with the theme by EditorController.applyTheme.
    var placeholderFont: NSFont = .systemFont(ofSize: 18) {
        didSet { needsDisplay = true }
    }

    private static let maxColumnWidth: CGFloat = 680
    private static let placeholderText = "Start writing…"

    /// Injected by tests: a standalone (windowless) NSTextView resolves no
    /// undo manager from the responder chain.
    var testUndoManager: UndoManager?

    override var undoManager: UndoManager? {
        testUndoManager ?? super.undoManager
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        guard string.isEmpty else { return }
        let origin = NSPoint(
            x: textContainerInset.width + (textContainer?.lineFragmentPadding ?? 5),
            y: textContainerInset.height
        )
        Self.placeholderText.draw(at: origin, withAttributes: [
            .font: placeholderFont,
            .foregroundColor: NSColor.tertiaryLabelColor,
        ])
    }

    override func didChangeText() {
        super.didChangeText()
        needsDisplay = true
    }

    override func keyDown(with event: NSEvent) {
        switch event.keyCode {
        case 48: // Tab
            if onGhostTab?() == true { return }
        case 53: // Escape
            if onGhostEscape?() == true { return }
        default:
            break
        }
        super.keyDown(with: event)
    }

    override func flagsChanged(with event: NSEvent) {
        // Plain ⌥ only — ⌥ combined with ⌘/⌃ is a shortcut chord, not the AI trigger.
        let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        onOptionKeyChange?(flags == .option)
        super.flagsChanged(with: event)
    }

    override func setFrameSize(_ newSize: NSSize) {
        super.setFrameSize(newSize)
        updateColumnInset()
    }

    private func updateColumnInset() {
        let horizontal = max(32, (frame.width - Self.maxColumnWidth) / 2)
        let inset = NSSize(width: horizontal.rounded(), height: 64)
        if textContainerInset != inset {
            textContainerInset = inset
        }
    }

    /// NSTextView calls this internally to keep the caret visible on every
    /// keystroke. Redirecting caret scrolls into our centering makes typewriter
    /// mode the single scroll authority — no competing scroll animations.
    override func scrollRangeToVisible(_ range: NSRange) {
        if range.length == 0 {
            centerCaret()
        } else {
            super.scrollRangeToVisible(range)
        }
    }

    /// Typewriter mode: keep the caret vertically centered while typing.
    /// Synchronous and unanimated on purpose — per-keystroke movement is at
    /// most one line height, and starting overlapping animations while reading
    /// mid-flight scroll positions is what caused visible flicker.
    /// Bottom overscroll (half a viewport of contentInset) lets the last line
    /// reach the middle of the screen.
    func centerCaret() {
        guard let scrollView = enclosingScrollView, let window else { return }
        let caretScreenRect = firstRect(
            forCharacterRange: NSRange(location: selectedRange().location, length: 0),
            actualRange: nil
        )
        guard caretScreenRect != .zero else { return }
        let caretRect = convert(window.convertFromScreen(caretScreenRect), from: nil)
        let visible = scrollView.contentView.bounds

        let bottomInset = (visible.height * 0.5).rounded()
        if scrollView.contentInsets.bottom != bottomInset {
            scrollView.contentInsets.bottom = bottomInset
        }

        let maxY = max(0, frame.height - visible.height + bottomInset)
        let targetY = min(max(0, caretRect.midY - visible.height * 0.5), maxY)

        // Dead-band of ~half a line: an empty line's caret rect comes from the
        // extra line fragment (default font height), and the first typed glyph
        // re-measures it with the theme's lineHeightMultiple — a few px of
        // jitter that must not trigger a scroll. Real line changes move a full
        // line height and always exceed this.
        let threshold = max(caretRect.height * 0.45, 8)
        guard abs(targetY - visible.origin.y) > threshold else { return }

        scrollView.contentView.setBoundsOrigin(NSPoint(x: visible.origin.x, y: targetY))
        scrollView.reflectScrolledClipView(scrollView.contentView)
    }
}
