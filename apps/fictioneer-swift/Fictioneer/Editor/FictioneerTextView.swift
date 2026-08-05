import AppKit
import SwiftUI

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

    // MARK: - Selection action bar (AI rephrase at the moment of intent)

    /// Gate + action wired by the scene editor. The bar appears above a
    /// stabilized selection and dismisses on any selection change or edit.
    var selectionBarIsEnabled: (() -> Bool)?
    var onSelectionBarAction: (() -> Void)?

    private var selectionBar: SelectionBarHostView?
    private var selectionBarTask: Task<Void, Never>?

    func scheduleSelectionBarUpdate() {
        selectionBarTask?.cancel()
        dismissSelectionBar()
        let range = selectedRange()
        guard range.length > 0, selectionBarIsEnabled?() == true else { return }
        selectionBarTask = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(280))
            guard !Task.isCancelled else { return }
            self?.presentSelectionBar()
        }
    }

    func dismissSelectionBar() {
        selectionBar?.removeFromSuperview()
        selectionBar = nil
    }

    private func presentSelectionBar() {
        dismissSelectionBar()
        guard let window else { return }
        let range = selectedRange()
        guard range.length > 0 else { return }
        let screenRect = firstRect(forCharacterRange: range, actualRange: nil)
        guard screenRect != .zero else { return }
        let selectionRect = convert(window.convertFromScreen(screenRect), from: nil)

        let bar = SelectionBarHostView()
        bar.onAction = { [weak self] in
            self?.dismissSelectionBar()
            self?.onSelectionBarAction?()
        }
        let size = bar.pillSize
        let x = min(max(8, selectionRect.minX), bounds.width - size.width - 8)
        // Above the selection's first line; below it when clipped at the top.
        var y = selectionRect.minY - size.height - 6
        if y < 4 {
            y = selectionRect.maxY + 6
        }
        bar.frame = NSRect(x: x, y: y, width: size.width, height: size.height)
        addSubview(bar)
        selectionBar = bar
    }

    // MARK: - Hover cards on highlighted text

    // Experiment: issue details appear when hovering the flagged text itself.
    private var hoverHighlights: [(range: NSRange, items: [MarginIssue])] = []
    private var hoverCard: NSHostingView<AnalysisIssueListView>?
    private var hoverCardRange: NSRange?
    private var hoverTask: Task<Void, Never>?

    func setHoverHighlights(_ highlights: [(range: NSRange, items: [MarginIssue])]) {
        hoverHighlights = highlights
        dismissHoverCard()
    }

    private var hoverTrackingArea: NSTrackingArea?

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        // NSTextView calls this often — replace our area instead of stacking
        // a new one each time.
        if let hoverTrackingArea {
            removeTrackingArea(hoverTrackingArea)
        }
        let area = NSTrackingArea(
            rect: .zero,
            options: [.mouseMoved, .mouseEnteredAndExited, .activeInKeyWindow, .inVisibleRect],
            owner: self,
            userInfo: nil
        )
        addTrackingArea(area)
        hoverTrackingArea = area
    }

    override func mouseMoved(with event: NSEvent) {
        super.mouseMoved(with: event)
        guard !hoverHighlights.isEmpty else { return }
        let point = convert(event.locationInWindow, from: nil)
        let containerPoint = NSPoint(
            x: point.x - textContainerOrigin.x,
            y: point.y - textContainerOrigin.y
        )
        var hit: (range: NSRange, items: [MarginIssue])?
        if let layoutManager, let textContainer {
            var fraction: CGFloat = 0
            let index = layoutManager.characterIndex(
                for: containerPoint,
                in: textContainer,
                fractionOfDistanceBetweenInsertionPoints: &fraction
            )
            hit = hoverHighlights.first { NSLocationInRange(index, $0.range) }
        }

        if let hit {
            guard hit.range != hoverCardRange else { return }
            hoverTask?.cancel()
            hoverTask = Task { [weak self] in
                try? await Task.sleep(for: .milliseconds(180))
                guard !Task.isCancelled else { return }
                self?.showHoverCard(for: hit.range, items: hit.items)
            }
        } else if hoverCard != nil || hoverTask != nil {
            hoverTask?.cancel()
            hoverTask = nil
            dismissHoverCard()
        }
    }

    override func mouseExited(with event: NSEvent) {
        super.mouseExited(with: event)
        hoverTask?.cancel()
        hoverTask = nil
        dismissHoverCard()
    }

    private func showHoverCard(for range: NSRange, items: [MarginIssue]) {
        dismissHoverCard()
        guard let window else { return }
        let screenRect = firstRect(forCharacterRange: range, actualRange: nil)
        guard screenRect != .zero else { return }
        let lineRect = convert(window.convertFromScreen(screenRect), from: nil)

        let card = NSHostingView(rootView: AnalysisIssueListView(items: items))
        let size = card.fittingSize
        let x = min(max(8, lineRect.minX), bounds.width - size.width - 8)
        card.frame = NSRect(x: x, y: lineRect.maxY + 4, width: size.width, height: size.height)
        addSubview(card)
        hoverCard = card
        hoverCardRange = range
    }

    func dismissHoverCard() {
        hoverCard?.removeFromSuperview()
        hoverCard = nil
        hoverCardRange = nil
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

    /// Plain ⌥ only — ⌥ combined with ⌘/⌃/⇧ is a shortcut chord, not the AI
    /// trigger. Caps Lock is subtracted first: it is latched state that would
    /// otherwise make the comparison fail and leave ghost text dead while
    /// Caps Lock is on.
    static func isPlainOption(_ flags: NSEvent.ModifierFlags) -> Bool {
        flags.intersection(.deviceIndependentFlagsMask).subtracting(.capsLock) == .option
    }

    override func flagsChanged(with event: NSEvent) {
        onOptionKeyChange?(Self.isPlainOption(event.modifierFlags))
        super.flagsChanged(with: event)
    }

    override func setFrameSize(_ newSize: NSSize) {
        super.setFrameSize(newSize)
        updateColumnInset()
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
