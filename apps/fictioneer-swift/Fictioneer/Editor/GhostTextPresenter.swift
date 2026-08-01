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
        editorController.onDocumentEdit = { [weak self] in
            self?.controller.documentDidChange()
        }
        editorController.onSelectionChange = { [weak self] in
            self?.selectionDidChange()
        }
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
        guard let textView else { return true }
        var insertion = suggestion
        if needsLeadingSpace, let first = insertion.first, !first.isWhitespace {
            insertion = " " + insertion
        }
        textView.insertText(insertion, replacementRange: textView.selectedRange())
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
        editorController?.isPerformingGhostMutation = true
        undoManager?.disableUndoRegistration()
        defer {
            undoManager?.enableUndoRegistration()
            editorController?.isPerformingGhostMutation = false
        }

        if let ghostRange {
            storage.deleteCharacters(in: ghostRange)
            self.ghostRange = nil
        }

        guard let display else {
            let caret = insertionLocation
            insertionLocation = nil
            if let caret {
                textView.setSelectedRange(NSRange(location: min(caret, storage.length), length: 0))
            }
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

    private func ghostAttributes(alpha: Double) -> [NSAttributedString.Key: Any] {
        var attributes = editorController?.theme?.bodyAttributes ?? [:]
        attributes[.foregroundColor] = NSColor.tertiaryLabelColor.withAlphaComponent(alpha)
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
