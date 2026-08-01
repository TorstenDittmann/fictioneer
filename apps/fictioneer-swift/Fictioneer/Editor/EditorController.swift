import AppKit

/// Bridges SwiftUI toolbar actions to the NSTextView: formatting commands,
/// theme application, and (in M7) the ghost-text presenter's mutation flag.
@Observable
final class EditorController {
    weak var textView: FictioneerTextView?
    private(set) var theme: EditorTheme?

    /// Set by GhostTextPresenter around its storage mutations so the
    /// coordinator's textDidChange ignores them.
    @ObservationIgnored var isPerformingGhostMutation = false

    /// Called on real document edits; the ghost presenter hooks this to dismiss.
    @ObservationIgnored var onDocumentEdit: (() -> Void)?

    /// Called on selection changes (outside ghost mutations); the ghost
    /// presenter hooks this to dismiss when the caret moves.
    @ObservationIgnored var onSelectionChange: (() -> Void)?

    /// Keeps the presenter alive for the editor's lifetime.
    @ObservationIgnored var ghostPresenter: GhostTextPresenter?

    // MARK: - Theme

    func applyTheme(_ theme: EditorTheme) {
        self.theme = theme
        guard let textView, let storage = textView.textStorage else { return }
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
