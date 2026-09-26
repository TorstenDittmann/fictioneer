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

    // MARK: - Selection action bar (formatting + AI at the point of use)

    /// The bar's buttons for the current selection, wired by the editor
    /// views. The bar appears above a stabilized selection and dismisses on
    /// any selection change or edit; formatting re-presents it afterwards.
    var selectionBarItems: (() -> [SelectionBarItem])?

    private var selectionBar: SelectionBarHostView?
    private var selectionBarTask: Task<Void, Never>?

    func scheduleSelectionBarUpdate() {
        selectionBarTask?.cancel()
        dismissSelectionBar()
        let range = selectedRange()
        guard range.length > 0, selectionBarItems?().isEmpty == false else { return }
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

        guard let items = selectionBarItems?(), !items.isEmpty else { return }
        let bar = SelectionBarHostView(items: items) { [weak self] item in
            self?.dismissSelectionBar()
            item.action()
            if item.keepsBarOpen {
                self?.scheduleSelectionBarUpdate()
            }
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
            x: textContainerOrigin.x + (textContainer?.lineFragmentPadding ?? 5),
            y: textContainerOrigin.y
        )
        Self.placeholderText.draw(at: origin, withAttributes: [
            .font: placeholderFont,
            .foregroundColor: NSColor.tertiaryLabelColor,
        ])
    }

    /// The project's quotation marks; typed `"` and `'` are replaced from
    /// context. Read at insert time so a settings change applies at once.
    var quoteStyle: (() -> QuoteStyle?)?

    override func insertText(_ string: Any, replacementRange: NSRange) {
        guard let typed = string as? String, typed.count == 1, let key = typed.first,
              key == "\"" || key == "'", let style = quoteStyle?(),
              !hasMarkedText() else {
            super.insertText(string, replacementRange: replacementRange)
            return
        }
        let text = self.string as NSString
        let target = replacementRange.location == NSNotFound ? selectedRange() : replacementRange
        let previous = target.location > 0
            ? Character(text.substring(with: text.rangeOfComposedCharacterSequence(at: target.location - 1)))
            : nil
        let nextLocation = target.location + target.length
        let next = nextLocation < text.length
            ? Character(text.substring(with: text.rangeOfComposedCharacterSequence(at: nextLocation)))
            : nil
        let mark = style.mark(forTyped: key, after: previous, before: next) ?? key
        super.insertText(String(mark), replacementRange: replacementRange)
    }

    // MARK: - Focus dimming

    /// Focus mode: every paragraph except the caret's fades back. Drawn with
    /// a temporary attribute (display-only, never saved), separate from the
    /// analysis highlights, which use background and underline.
    var dimsInactiveParagraphs = false {
        didSet {
            guard dimsInactiveParagraphs != oldValue else { return }
            updateParagraphDimming()
        }
    }

    private static let dimmedTextColor = NSColor.labelColor.withAlphaComponent(0.28)

    func updateParagraphDimming() {
        guard let layoutManager else { return }
        let text = string as NSString
        let whole = NSRange(location: 0, length: text.length)
        layoutManager.removeTemporaryAttribute(.foregroundColor, forCharacterRange: whole)
        guard dimsInactiveParagraphs, text.length > 0 else { return }
        let caret = min(selectedRange().location, text.length)
        let active = text.paragraphRange(for: NSRange(location: caret, length: 0))
        let dimmed = [NSAttributedString.Key.foregroundColor: Self.dimmedTextColor]
        if active.location > 0 {
            layoutManager.addTemporaryAttributes(dimmed, forCharacterRange: NSRange(location: 0, length: active.location))
        }
        if NSMaxRange(active) < text.length {
            layoutManager.addTemporaryAttributes(
                dimmed,
                forCharacterRange: NSRange(location: NSMaxRange(active), length: text.length - NSMaxRange(active))
            )
        }
    }

    override func setSelectedRanges(
        _ ranges: [NSValue],
        affinity: NSSelectionAffinity,
        stillSelecting stillSelectingFlag: Bool
    ) {
        super.setSelectedRanges(ranges, affinity: affinity, stillSelecting: stillSelectingFlag)
        if dimsInactiveParagraphs {
            updateParagraphDimming()
        }
    }

    override func didChangeText() {
        super.didChangeText()
        if dimsInactiveParagraphs {
            updateParagraphDimming()
        }
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
        let widthChanged = abs(newSize.width - frame.width) > 0.5
        // Every resize path (sizeToFit after layout, clip-view tiling) goes
        // through here, so the overscroll height can't be shrunk away.
        var size = newSize
        size.height = max(size.height, overscrollHeight)
        super.setFrameSize(size)
        updateColumnInset()
        layoutPageHeader()
        // A new width reflows the column, so the content height changes.
        if widthChanged {
            scheduleOverscrollUpdate()
        }
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
        if let textStorage {
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(storageDidProcessEditing),
                name: NSTextStorage.didProcessEditingNotification,
                object: textStorage
            )
        }
    }

    @objc private func clipViewFrameDidChange(_ notification: Notification) {
        updateOverscrollMinHeight()
    }

    /// Any storage change (typing, load, re-theming, ghost text) can change
    /// the content height. Deferred: layout isn't valid mid-edit.
    @objc private func storageDidProcessEditing(_ notification: Notification) {
        scheduleOverscrollUpdate()
    }

    private var isOverscrollUpdateScheduled = false

    /// Coalesces bursts (a re-theme, a streamed suggestion) into one relayout.
    private func scheduleOverscrollUpdate() {
        guard !isOverscrollUpdateScheduled else { return }
        isOverscrollUpdateScheduled = true
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            isOverscrollUpdateScheduled = false
            updateOverscrollMinHeight()
        }
    }

    /// Content height plus half a viewport, so the last line can scroll up
    /// to the middle. Enforced in setFrameSize rather than via minSize:
    /// AppKit resets a text view's minSize to the clip height whenever the
    /// scroll view tiles, which silently dropped the overscroll until the
    /// next keystroke.
    private var overscrollHeight: CGFloat = 0

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
        let contentHeight = layoutManager.usedRect(for: textContainer).height
            + textContainerInset.height * 2
            + pageHeaderHeight
        let overscroll = (clipHeight * 0.5).rounded()
        let target = max(clipHeight, (contentHeight + overscroll).rounded())
        guard abs(overscrollHeight - target) > 1 || abs(frame.height - target) > 1 else { return }
        overscrollHeight = target
        // Also shrinks the frame when content got shorter; the clamp in
        // setFrameSize keeps it at the new target.
        setFrameSize(NSSize(width: frame.width, height: target))
    }

    // MARK: - Page header

    /// A view laid out above the first line (the scene title), inside the
    /// scrolling document so it moves with the text. The text starts below
    /// it via `textContainerOrigin`, so caret, clicks and highlights follow.
    var pageHeaderView: NSView? {
        didSet {
            oldValue?.removeFromSuperview()
            if let pageHeaderView {
                addSubview(pageHeaderView)
            }
            layoutPageHeader()
        }
    }

    private var pageHeaderHeight: CGFloat = 0
    private static let pageHeaderSpacing: CGFloat = 28

    override var textContainerOrigin: NSPoint {
        let origin = super.textContainerOrigin
        return NSPoint(x: origin.x, y: origin.y + pageHeaderHeight)
    }

    private var isLayingOutPageHeader = false

    func layoutPageHeader() {
        // Setting the header's frame can report a size change back here.
        guard !isLayingOutPageHeader else { return }
        isLayingOutPageHeader = true
        defer { isLayingOutPageHeader = false }
        var height: CGFloat = 0
        if let header = pageHeaderView {
            let padding = textContainer?.lineFragmentPadding ?? 5
            let width = max(0, frame.width - textContainerInset.width * 2 - padding * 2)
            let headerHeight = ceil(header.fittingSize.height)
            header.frame = NSRect(
                x: textContainerInset.width + padding,
                y: textContainerInset.height,
                width: width,
                height: headerHeight
            )
            height = headerHeight + Self.pageHeaderSpacing
        }
        guard abs(height - pageHeaderHeight) > 0.5 else { return }
        pageHeaderHeight = height
        invalidateTextContainerOrigin()
        needsDisplay = true
        scheduleOverscrollUpdate()
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
        // Before the guards: on first load the caret rect isn't available yet,
        // but the overscroll must still be in place for manual scrolling.
        updateOverscrollMinHeight()
        guard let scrollView = enclosingScrollView, let window else { return }
        let caretScreenRect = firstRect(
            forCharacterRange: NSRange(location: selectedRange().location, length: 0),
            actualRange: nil
        )
        guard caretScreenRect != .zero else { return }
        let caretRect = convert(window.convertFromScreen(caretScreenRect), from: nil)
        let visible = scrollView.contentView.bounds

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
