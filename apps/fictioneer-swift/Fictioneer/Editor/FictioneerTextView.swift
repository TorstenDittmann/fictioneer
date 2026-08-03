import AppKit

/// NSTextView subclass with key hooks for the ghost-text feature and the
/// centered writing column / typewriter scrolling behavior.
final class FictioneerTextView: NSTextView {
    /// Ghost-text hooks, wired by GhostTextPresenter. Return true to consume the key.
    var onGhostTab: (() -> Bool)?
    var onGhostEscape: (() -> Bool)?
    var onOptionKeyChange: ((Bool) -> Void)?
    /// Fallback Escape handler (focus-mode exit); runs only when no ghost consumed it.
    var onEscape: (() -> Bool)?

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

    // MARK: - Margin annotations

    // Prose-issue details render as chips in the right gutter (tooltips are a
    // dead end: TextKit 2 ignores the `.toolTip` key and NSTextView's tracking
    // management swallows foreign tooltip rects). Chips are subviews of the
    // document view, so they scroll with the text.
    private var marginAnnotations: [MarginAnnotation] = []
    private var marginChips: [MarginChipHostView] = []

    func setMarginAnnotations(_ annotations: [MarginAnnotation]) {
        marginAnnotations = annotations
        rebuildMarginChips()
    }

    /// Recomputes existing chips' frames from current layout without
    /// recreating views — safe to call from `layout()`, and keeps chips
    /// correct after attribute-only changes (heading/blockquote toggles)
    /// that move lines without changing the text.
    func repositionMarginAnnotations() {
        guard !marginChips.isEmpty, let window else { return }
        let marginWidth = textContainerInset.width
        let x = bounds.width - marginWidth + 8
        for chip in marginChips {
            let screenRect = firstRect(forCharacterRange: chip.annotation.lineRange, actualRange: nil)
            guard screenRect != .zero else {
                chip.isHidden = true
                continue
            }
            let lineRect = convert(window.convertFromScreen(screenRect), from: nil)
            chip.isHidden = marginWidth < 90
            let origin = NSPoint(x: x, y: Self.chipY(forLineRect: lineRect, chipHeight: chip.frame.height))
            if chip.frame.origin != origin {
                chip.setFrameOrigin(origin)
            }
            chip.layoutDetailCard() // an open card stays glued to its pill
        }
    }

    /// Line boxes carry their extra leading on top (lineHeightMultiple), so
    /// glyphs sit at the bottom — align chips to the glyph band, not box top.
    static func chipY(forLineRect lineRect: NSRect, chipHeight: CGFloat) -> CGFloat {
        lineRect.maxY - chipHeight - 3
    }

    override func layout() {
        super.layout()
        repositionMarginAnnotations()
    }

    private func rebuildMarginChips() {
        marginChips.forEach {
            $0.dismissDetail()
            $0.removeFromSuperview()
        }
        marginChips.removeAll()
        let marginWidth = textContainerInset.width
        guard marginWidth >= 90, let window, !marginAnnotations.isEmpty else { return }
        let x = bounds.width - marginWidth + 8
        let maxWidth = min(marginWidth - 20, 220)
        for annotation in marginAnnotations {
            let screenRect = firstRect(forCharacterRange: annotation.lineRange, actualRange: nil)
            guard screenRect != .zero else { continue }
            let lineRect = convert(window.convertFromScreen(screenRect), from: nil)
            let chip = MarginChipHostView(annotation: annotation)
            // Frame must hug the visible pill: any invisible slack consumes
            // clicks meant for the editor and offsets the popover anchor.
            let size = chip.pillSize
            let height = min(max(size.height, 18), 22)
            chip.frame = NSRect(
                x: x,
                y: Self.chipY(forLineRect: lineRect, chipHeight: height),
                width: min(size.width, maxWidth),
                height: height
            )
            addSubview(chip)
            marginChips.append(chip)
        }
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
            if onEscape?() == true { return }
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
        rebuildMarginChips()
    }

    // MARK: - Overscroll hit area

    // Apple's scroll-view/text-view recipe keeps minSize at the viewport
    // height so the text view spans the visible area — otherwise clicks below
    // short content (and in the typewriter overscroll inset) land on the clip
    // view and go dead.
    override func viewDidMoveToSuperview() {
        super.viewDidMoveToSuperview()
        if let clipView = superview as? NSClipView {
            clipView.postsFrameChangedNotifications = true
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(clipViewFrameDidChange),
                name: NSView.frameDidChangeNotification,
                object: clipView
            )
            updateOverscrollMinHeight()
        }
    }

    @objc private func clipViewFrameDidChange(_ notification: Notification) {
        updateOverscrollMinHeight()
    }

    // Typewriter overscroll = a stretched text view, NOT NSScrollView
    // contentInsets: on macOS those shrink the clip view's tile (unlike iOS),
    // which chopped the visible viewport in half — text could never render in
    // the inset region and clicks there felt dead.
    func updateOverscrollMinHeight() {
        guard let scrollView = enclosingScrollView,
              let layoutManager,
              let textContainer else { return }
        let clipHeight = scrollView.contentView.bounds.height
        layoutManager.ensureLayout(for: textContainer)
        let contentHeight = layoutManager.usedRect(for: textContainer).height + textContainerInset.height * 2
        let overscroll = (clipHeight * 0.5).rounded()
        let target = max(clipHeight, (contentHeight + overscroll).rounded())
        if abs(minSize.height - target) > 1 {
            minSize = NSSize(width: 0, height: target)
            if frame.height < target {
                setFrameSize(NSSize(width: frame.width, height: target))
            }
        }
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

        updateOverscrollMinHeight()

        let maxY = max(0, frame.height - visible.height)
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
