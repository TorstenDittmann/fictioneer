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

    /// Typewriter feel: keep the caret in the middle band of the viewport.
    func centerCaret() {
        guard let scrollView = enclosingScrollView, let window else { return }
        let caretScreenRect = firstRect(
            forCharacterRange: NSRange(location: selectedRange().location, length: 0),
            actualRange: nil
        )
        guard caretScreenRect != .zero else { return }
        let caretRect = convert(window.convertFromScreen(caretScreenRect), from: nil)
        let visible = scrollView.contentView.bounds
        let upperBand = visible.minY + visible.height * 0.2
        let lowerBand = visible.minY + visible.height * 0.65
        guard caretRect.midY < upperBand || caretRect.midY > lowerBand else { return }

        let targetY = max(0, caretRect.midY - visible.height * 0.5)
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.18
            context.allowsImplicitAnimation = true
            scrollView.contentView.animator().setBoundsOrigin(NSPoint(x: visible.origin.x, y: targetY))
            scrollView.reflectScrolledClipView(scrollView.contentView)
        }
    }
}
