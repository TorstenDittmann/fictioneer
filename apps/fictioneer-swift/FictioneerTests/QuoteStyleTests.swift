import AppKit
import Testing
@testable import Fictioneer

struct QuoteStyleTests {
    @Test func typedDoubleQuoteOpensAfterSpaceAndClosesAfterWord() {
        let style = QuoteStyle.english
        #expect(style.mark(forTyped: "\"", after: nil) == "\u{201C}")
        #expect(style.mark(forTyped: "\"", after: " ") == "\u{201C}")
        #expect(style.mark(forTyped: "\"", after: "(") == "\u{201C}")
        #expect(style.mark(forTyped: "\"", after: "d") == "\u{201D}")
        #expect(style.mark(forTyped: "\"", after: ".") == "\u{201D}")
    }

    @Test func germanUsesLowOpeningMarks() {
        let style = QuoteStyle.german
        #expect(style.mark(forTyped: "\"", after: " ") == "\u{201E}")
        #expect(style.mark(forTyped: "\"", after: "!") == "\u{201C}")
        #expect(style.mark(forTyped: "'", after: " ") == "\u{201A}")
    }

    @Test func apostropheInsideWordsInEveryCurlyStyle() {
        for style in [QuoteStyle.english, .german, .french] {
            #expect(style.mark(forTyped: "'", after: "n", before: "t") == "\u{2019}")
        }
        #expect(QuoteStyle.straight.mark(forTyped: "'", after: "n", before: "t") == "'")
    }

    @Test func nonQuoteKeysAreLeftAlone() {
        #expect(QuoteStyle.english.mark(forTyped: "a", after: " ") == nil)
    }

    @Test func convertNormalizesMixedQuotesKeepingLength() {
        let mixed = "\"Elementary,\" he said. \u{201E}A visitor\u{201C} don't wait."
        let converted = QuoteStyle.english.convert(mixed)
        #expect(converted == "\u{201C}Elementary,\u{201D} he said. \u{201C}A visitor\u{201D} don\u{2019}t wait.")
        #expect((converted as NSString).length == (mixed as NSString).length)
    }

    @Test func convertToStraightAndFrench() {
        let text = "\u{201C}Holmes\u{2019}s pipe,\u{201D} I said."
        #expect(QuoteStyle.straight.convert(text) == "\"Holmes's pipe,\" I said.")
        #expect(QuoteStyle.french.convert(text) == "\u{00AB}Holmes\u{2019}s pipe,\u{00BB} I said.")
    }

    @Test func quoteStyleRoundTripsThroughPackage() throws {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("quotes-\(UUID().uuidString).fictioneer")
        defer { try? FileManager.default.removeItem(at: url) }
        let project = Project.makeNew(title: "Q")
        #expect(project.quoteStyle == nil)
        project.quoteStyle = .french
        try ProjectPackage.write(project, to: url)
        #expect(try ProjectPackage.read(from: url).quoteStyle == .french)
    }

    @Test func defaultStyleFollowsLanguage() {
        #expect(QuoteStyle.defaultStyle(for: Locale(identifier: "de_DE")) == .german)
        #expect(QuoteStyle.defaultStyle(for: Locale(identifier: "fr_FR")) == .french)
        #expect(QuoteStyle.defaultStyle(for: Locale(identifier: "en_US")) == .english)
        #expect(QuoteStyle.defaultStyle(for: Locale(identifier: "ja_JP")) == .english)
    }

    @MainActor
    @Test func typingUsesProjectStyleAndConvertKeepsFormatting() {
        let textView = FictioneerTextView(usingTextLayoutManager: false)
        textView.isRichText = true
        textView.allowsUndo = true
        textView.quoteStyle = { .german }
        textView.insertText("Er sagte ", replacementRange: NSRange(location: NSNotFound, length: 0))
        textView.insertText("\"", replacementRange: NSRange(location: NSNotFound, length: 0))
        textView.insertText("Ja!", replacementRange: NSRange(location: NSNotFound, length: 0))
        textView.insertText("\"", replacementRange: NSRange(location: NSNotFound, length: 0))
        #expect(textView.string == "Er sagte \u{201E}Ja!\u{201C}")

        let bold = NSFont.boldSystemFont(ofSize: 14)
        textView.textStorage?.addAttribute(.font, value: bold, range: NSRange(location: 9, length: 5))
        let controller = EditorController()
        controller.textView = textView
        controller.convertQuotes(to: .english)
        #expect(textView.string == "Er sagte \u{201C}Ja!\u{201D}")
        #expect(textView.textStorage?.attribute(.font, at: 9, effectiveRange: nil) as? NSFont == bold)
    }
}
