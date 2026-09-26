import AppKit

/// Bridges SwiftUI toolbar actions to the NSTextView: formatting commands,
/// theme application, and (in M7) the ghost-text presenter's mutation flag.
@Observable
final class EditorController {
    weak var textView: FictioneerTextView?
    private(set) var theme: EditorTheme?

    /// Set around programmatic storage mutations (ghost text, analysis
    /// highlights) so the coordinator's textDidChange ignores them.
    @ObservationIgnored var isPerformingProgrammaticMutation = false

    /// Observers of real document edits (ghost presenter dismissal, analysis
    /// re-runs, …). Multicast — append, never assign.
    @ObservationIgnored var documentEditObservers: [() -> Void] = []

    /// Observers of selection changes outside programmatic mutations.
    @ObservationIgnored var selectionChangeObservers: [() -> Void] = []

    func notifyDocumentEdit() {
        for observer in documentEditObservers {
            observer()
        }
    }

    func notifySelectionChange() {
        for observer in selectionChangeObservers {
            observer()
        }
    }

    /// Whether the text view currently has a non-empty selection (updated by
    /// the coordinator; drives the Rephrase button).
    var hasSelection = false

    /// Keeps the presenter alive for the editor's lifetime.
    @ObservationIgnored var ghostPresenter: GhostTextPresenter?

    var isGhostActive: Bool {
        ghostPresenter?.isGhostActive ?? false
    }

    // MARK: - Theme

    func applyTheme(_ theme: EditorTheme) {
        self.theme = theme
        guard let textView, let storage = textView.textStorage else { return }
        textView.placeholderFont = FontLoader.placeholderFont(size: theme.fontSize)
        retheme(storage)
        textView.typingAttributes = theme.attributes(for: blockStyleForTyping())
    }

    /// Re-derives fonts/paragraph styles for the whole document from block-style
    /// markers, preserving per-run bold/italic traits. Not undoable by design —
    /// it runs on load and on settings changes, not on user edits.
    private func retheme(_ storage: NSTextStorage) {
        guard let theme else { return }
        let string = storage.string as NSString
        storage.beginEditing()
        var location = 0
        while location < string.length {
            let paragraph = string.paragraphRange(for: NSRange(location: location, length: 0))
            let style = blockStyle(in: storage, at: paragraph.location)
            let base = theme.attributes(for: style)
            let baseFont = base[.font] as! NSFont
            storage.addAttribute(.paragraphStyle, value: base[.paragraphStyle]!, range: paragraph)
            storage.addAttribute(.foregroundColor, value: base[.foregroundColor]!, range: paragraph)
            storage.enumerateAttribute(.font, in: paragraph) { value, range, _ in
                let traits = (value as? NSFont).map { NSFontManager.shared.traits(of: $0) } ?? []
                var font = baseFont
                if traits.contains(.boldFontMask) {
                    font = NSFontManager.shared.convert(font, toHaveTrait: .boldFontMask)
                }
                if traits.contains(.italicFontMask) {
                    font = NSFontManager.shared.convert(font, toHaveTrait: .italicFontMask)
                }
                storage.addAttribute(.font, value: font, range: range)
            }
            location = paragraph.location + paragraph.length
            if paragraph.length == 0 { break }
        }
        storage.endEditing()
    }

    // MARK: - Selection / insertion (rephrase + AI prompt)

    /// The selected text plus ±200 characters of context.
    func selectionContext() -> (selected: String, before: String, after: String)? {
        guard let textView else { return nil }
        let range = textView.selectedRange()
        guard range.length > 0 else { return nil }
        let text = textView.string as NSString
        let selected = text.substring(with: range)
        let beforeStart = max(0, range.location - 200)
        let before = text.substring(with: NSRange(location: beforeStart, length: range.location - beforeStart))
        let afterEnd = min(text.length, range.location + range.length + 200)
        let after = text.substring(with: NSRange(location: range.location + range.length, length: afterEnd - (range.location + range.length)))
        return (selected, before, after)
    }

    /// Replaces the current selection as one undoable edit.
    func replaceSelection(with text: String) {
        guard let textView else { return }
        let range = textView.selectedRange()
        guard range.length > 0 else { return }
        textView.insertText(text, replacementRange: range)
    }

    /// Inserts at the caret as one undoable edit.
    func insertAtCaret(_ text: String) {
        guard let textView else { return }
        textView.insertText(text, replacementRange: textView.selectedRange())
    }

    // MARK: - Undo

    func undo() {
        textView?.undoManager?.undo()
    }

    func redo() {
        textView?.undoManager?.redo()
    }

    // MARK: - Inline formatting

    func toggleBold() {
        toggleFontTrait(.boldFontMask)
    }

    func toggleItalic() {
        toggleFontTrait(.italicFontMask)
    }

    func toggleUnderline() {
        toggleRawValueAttribute(.underlineStyle, value: NSUnderlineStyle.single.rawValue)
    }

    func toggleStrikethrough() {
        toggleRawValueAttribute(.strikethroughStyle, value: NSUnderlineStyle.single.rawValue)
    }

    private func toggleFontTrait(_ trait: NSFontTraitMask) {
        guard let textView, let theme else { return }
        let fontManager = NSFontManager.shared
        let range = textView.selectedRange()

        func toggled(_ font: NSFont, adding: Bool) -> NSFont {
            adding
                ? fontManager.convert(font, toHaveTrait: trait)
                : fontManager.convert(font, toNotHaveTrait: trait)
        }

        if range.length == 0 {
            var attributes = textView.typingAttributes
            let font = attributes[.font] as? NSFont ?? theme.bodyFont
            attributes[.font] = toggled(font, adding: !fontManager.traits(of: font).contains(trait))
            textView.typingAttributes = attributes
            return
        }

        guard let storage = textView.textStorage,
              textView.shouldChangeText(in: range, replacementString: nil)
        else { return }
        let firstFont = storage.attribute(.font, at: range.location, effectiveRange: nil) as? NSFont ?? theme.bodyFont
        let adding = !fontManager.traits(of: firstFont).contains(trait)
        storage.beginEditing()
        storage.enumerateAttribute(.font, in: range) { value, subRange, _ in
            let font = value as? NSFont ?? theme.bodyFont
            storage.addAttribute(.font, value: toggled(font, adding: adding), range: subRange)
        }
        storage.endEditing()
        textView.didChangeText()
    }

    private func toggleRawValueAttribute(_ key: NSAttributedString.Key, value: Int) {
        guard let textView else { return }
        let range = textView.selectedRange()

        if range.length == 0 {
            var attributes = textView.typingAttributes
            let isActive = (attributes[key] as? Int ?? 0) != 0
            attributes[key] = isActive ? nil : value
            textView.typingAttributes = attributes
            return
        }

        guard let storage = textView.textStorage,
              textView.shouldChangeText(in: range, replacementString: nil)
        else { return }
        let isActive = (storage.attribute(key, at: range.location, effectiveRange: nil) as? Int ?? 0) != 0
        storage.beginEditing()
        if isActive {
            storage.removeAttribute(key, range: range)
        } else {
            storage.addAttribute(key, value: value, range: range)
        }
        storage.endEditing()
        textView.didChangeText()
    }

    // MARK: - Block styles

    /// Rewrites every quotation mark in the document in `style`, as one
    /// undoable edit. Characters are swapped one-for-one, so formatting stays.
    func convertQuotes(to style: QuoteStyle) {
        guard let textView, let storage = textView.textStorage else { return }
        let original = storage.string
        let converted = style.convert(original) as NSString
        let source = original as NSString
        guard converted.length == source.length, converted != source else { return }
        let whole = NSRange(location: 0, length: source.length)
        guard textView.shouldChangeText(in: whole, replacementString: nil) else { return }
        storage.beginEditing()
        for index in 0..<source.length where source.character(at: index) != converted.character(at: index) {
            storage.replaceCharacters(
                in: NSRange(location: index, length: 1),
                with: converted.substring(with: NSRange(location: index, length: 1))
            )
        }
        storage.endEditing()
        textView.didChangeText()
    }

    func applyBlockStyle(_ requested: BlockStyle) {
        guard let textView, let theme, let storage = textView.textStorage else { return }
        let paragraph = (storage.string as NSString).paragraphRange(for: textView.selectedRange())

        // Re-applying the current style toggles back to body.
        let current = paragraph.length > 0
            ? blockStyle(in: storage, at: paragraph.location)
            : blockStyleForTyping()
        let target = (current == requested && requested != .body) ? .body : requested
        let attributes = theme.attributes(for: target)

        if paragraph.length > 0 {
            guard textView.shouldChangeText(in: paragraph, replacementString: nil) else { return }
            storage.beginEditing()
            storage.removeAttribute(.headingLevel, range: paragraph)
            storage.removeAttribute(.blockquote, range: paragraph)
            storage.addAttributes(attributes, range: paragraph)
            storage.endEditing()
            textView.didChangeText()
        }
        textView.typingAttributes = attributes
    }

    func blockStyleForTyping() -> BlockStyle {
        guard let textView else { return .body }
        let storage = textView.textStorage
        let location = (storage?.string as NSString?)?
            .paragraphRange(for: textView.selectedRange()).location ?? 0
        if let storage, location < storage.length {
            return blockStyle(in: storage, at: location)
        }
        let attributes = textView.typingAttributes
        if let level = attributes[.headingLevel] as? Int {
            return .heading(level)
        }
        if attributes[.blockquote] != nil {
            return .blockquote
        }
        return .body
    }

    private func blockStyle(in storage: NSTextStorage, at location: Int) -> BlockStyle {
        guard location < storage.length else { return .body }
        let attributes = storage.attributes(at: location, effectiveRange: nil)
        if let level = attributes[.headingLevel] as? Int {
            return .heading(level)
        }
        if attributes[.blockquote] != nil {
            return .blockquote
        }
        return .body
    }
}
