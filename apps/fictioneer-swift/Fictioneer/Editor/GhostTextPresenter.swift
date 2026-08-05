import AppKit

/// Applies GhostTextController state to the NSTextView: the ghost is *real*
/// text in the storage carrying the `.ghostText` attribute, inserted with undo
/// registration disabled and the coordinator's change handling suppressed, so
/// it wraps like real text but never touches undo, autosave, or word counts.
final class GhostTextPresenter {
    private let controller: GhostTextController
    private weak var textView: FictioneerTextView?
    private weak var editorController: EditorController?
    private let isEnabled: () -> Bool
    private let contextInfo: () -> (title: String?, sceneDescription: String?)

    private var ghostRange: NSRange?
    private var insertionLocation: Int?
    private var needsLeadingSpace = false

    init(
        textView: FictioneerTextView,
        editorController: EditorController,
        controller: GhostTextController,
        isEnabled: @escaping () -> Bool,
        contextInfo: @escaping () -> (title: String?, sceneDescription: String?)
    ) {
        self.textView = textView
        self.editorController = editorController
        self.controller = controller
        self.isEnabled = isEnabled
        self.contextInfo = contextInfo

        controller.onDisplayChange = { [weak self] display in
            self?.render(display)
        }
        textView.onOptionKeyChange = { [weak self] isDown in
            self?.optionChanged(isDown: isDown)
        }
        textView.onGhostTab = { [weak self] in
            self?.acceptIfReady() ?? false
        }
        textView.onGhostEscape = { [weak self] in
            self?.controller.escapePressed() ?? false
        }
        editorController.documentEditObservers.append { [weak self] in
            self?.controller.documentDidChange()
        }
        editorController.selectionChangeObservers.append { [weak self] in
            self?.selectionDidChange()
        }
    }

    var isGhostActive: Bool {
        controller.isActive
    }

    // MARK: - Inputs

    private func optionChanged(isDown: Bool) {
        guard isDown else {
            controller.optionKeyUp()
            return
        }
        guard
            isEnabled(),
            !controller.isActive,
            let textView,
            !textView.hasMarkedText()
        else { return }
        let selection = textView.selectedRange()
        guard selection.length == 0 else { return }

        let text = textView.string as NSString
        let before = text.substring(to: min(selection.location, text.length))
        let contextText = String(before.suffix(AppConfig.ghostTextContextWindow))
        needsLeadingSpace = before.last.map { !$0.isWhitespace && !$0.isNewline } ?? false

        let info = contextInfo()
        let context = GhostContextBuilder.build(
            contextText: contextText,
            title: info.title,
            sceneDescription: info.sceneDescription
        )
        controller.optionKeyDown(contextText: contextText, context: context, selectionEmpty: true)
    }

    private func acceptIfReady() -> Bool {
        guard let suggestion = controller.tabPressed() else { return false }
        // tabPressed emitted nil → the ghost is gone and the caret is back at
        // the insertion point. Insert as a single, normal, undoable edit.
        guard let textView, let storage = textView.textStorage else { return true }
        var insertion = suggestion
        if needsLeadingSpace, let first = insertion.first, !first.isWhitespace {
            insertion = " " + insertion
        }

        // Never insert via typingAttributes: live streaming can leave them
        // contaminated with ghost styling. Derive attributes from the real
        // text preceding the caret (theme body as fallback) and sanitize.
        let selection = textView.selectedRange()
        var attributes: [NSAttributedString.Key: Any]
        if selection.location > 0, selection.location <= storage.length {
            attributes = storage.attributes(at: selection.location - 1, effectiveRange: nil)
        } else {
            attributes = editorController?.theme?.bodyAttributes ?? textView.typingAttributes
        }
        if attributes[.ghostText] != nil {
            attributes = editorController?.theme?.bodyAttributes ?? [:]
        }
        attributes[.ghostText] = nil

        guard textView.shouldChangeText(in: selection, replacementString: insertion) else { return true }
        storage.replaceCharacters(in: selection, with: NSAttributedString(string: insertion, attributes: attributes))
        textView.didChangeText()
        textView.setSelectedRange(NSRange(location: selection.location + (insertion as NSString).length, length: 0))
        textView.typingAttributes = attributes
        return true
    }

    private func selectionDidChange() {
        // Any caret move while a ghost is showing dismisses it.
        guard let insertionLocation, let textView else { return }
        let selection = textView.selectedRange()
        if selection.length > 0 || selection.location != insertionLocation {
            controller.escapePressed()
        }
    }

    // MARK: - Rendering

    private func render(_ display: GhostDisplay?) {
        guard let textView, let storage = textView.textStorage else { return }
        let undoManager = textView.undoManager
        editorController?.isPerformingProgrammaticMutation = true
        undoManager?.disableUndoRegistration()
        defer {
            undoManager?.enableUndoRegistration()
            editorController?.isPerformingProgrammaticMutation = false
        }

        removeExistingGhost(from: storage, textView: textView)

        guard let display else {
            insertionLocation = nil
            return
        }

        let location = insertionLocation ?? textView.selectedRange().location
        insertionLocation = location

        let isDots = display.text.allSatisfy { $0 == "." }
        var text = display.text
        if needsLeadingSpace, !isDots {
            text = " " + text
        }
        let ghost = NSMutableAttributedString(string: text, attributes: ghostAttributes(alpha: display.alpha))
        if display.showsAcceptHint {
            ghost.append(NSAttributedString(string: "  ⇥ Tab", attributes: hintAttributes()))
        }
        storage.insert(ghost, at: min(location, storage.length))
        ghostRange = NSRange(location: location, length: ghost.length)
        textView.setSelectedRange(NSRange(location: location, length: 0))
    }

    /// Deletes the rendered ghost, if any. Never trusts the cached
    /// `ghostRange`: a user edit can land between renders (typing during the
    /// fade-out window, ⌥-dead-key input, paste while streaming) and shift
    /// the ghost, and deleting the stale range would destroy real text. The
    /// ghost is located by its `.ghostText` marker instead, and the caret is
    /// re-derived from the actual deletions so a just-typed character keeps
    /// its caret position.
    private func removeExistingGhost(from storage: NSTextStorage, textView: FictioneerTextView) {
        guard ghostRange != nil else { return }
        ghostRange = nil
        var ranges: [NSRange] = []
        storage.enumerateAttribute(.ghostText, in: NSRange(location: 0, length: storage.length)) { value, range, _ in
            if value != nil { ranges.append(range) }
        }
        guard !ranges.isEmpty else { return }
        var caret = textView.selectedRange().location
        for range in ranges.reversed() {
            storage.deleteCharacters(in: range)
            if range.location < caret {
                caret -= min(range.length, caret - range.location)
            }
        }
        textView.setSelectedRange(NSRange(location: min(caret, storage.length), length: 0))
    }

    /// Muted ghost color. Built from labelColor with an explicit low alpha —
    /// NOT from tertiaryLabelColor, whose muting lives in its *intrinsic*
    /// alpha and is destroyed by `withAlphaComponent(1)`.
    static func ghostColor(alpha: Double) -> NSColor {
        NSColor.labelColor.withAlphaComponent(0.4 * alpha)
    }

    private func ghostAttributes(alpha: Double) -> [NSAttributedString.Key: Any] {
        var attributes = editorController?.theme?.bodyAttributes ?? [:]
        // Pencil, not ink: suggestions render italic + muted; accepting inserts
        // upright ink attributes, so the transition itself shows authorship.
        if let font = attributes[.font] as? NSFont {
            attributes[.font] = NSFontManager.shared.convert(font, toHaveTrait: .italicFontMask)
        }
        attributes[.foregroundColor] = Self.ghostColor(alpha: alpha)
        attributes[.ghostText] = true
        attributes[.headingLevel] = nil
        attributes[.blockquote] = nil
        return attributes
    }

    private func hintAttributes() -> [NSAttributedString.Key: Any] {
        let size = editorController?.theme?.fontSize ?? 18
        return [
            .font: NSFont.systemFont(ofSize: size * 0.65, weight: .medium),
            .foregroundColor: NSColor.controlAccentColor.withAlphaComponent(0.65),
            .ghostText: true,
        ]
    }
}
