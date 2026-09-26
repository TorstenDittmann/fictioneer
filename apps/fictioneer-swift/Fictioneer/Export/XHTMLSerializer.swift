import AppKit

/// Serializes editor content (NSAttributedString with `.headingLevel` /
/// `.blockquote` block markers and bold/italic/underline/strike runs) into
/// clean XHTML for EPUB. Everything is XML-escaped.
nonisolated enum XHTMLSerializer {
    static func escape(_ text: String) -> String {
        var cleaned = text
        if text.unicodeScalars.contains(where: { !isXMLSafe($0) }) {
            cleaned = String(String.UnicodeScalarView(text.unicodeScalars.filter(isXMLSafe)))
        }
        return cleaned.replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&#x27;")
    }

    /// XML 1.0 forbids most control characters outright — they cannot even be
    /// escaped — and the attachment placeholder (U+FFFC) plus non-characters
    /// have no business in an EPUB. Strip them before escaping.
    private static func isXMLSafe(_ scalar: Unicode.Scalar) -> Bool {
        switch scalar.value {
        case 0x09, 0x0A, 0x0D: true
        case 0x00...0x1F: false // remaining C0 controls: illegal in XML 1.0
        case 0x7F...0x9F: false // DEL + C1 controls: XML-discouraged
        case 0xFFFC: false      // object-replacement char (attachment placeholder)
        case 0xFFFE, 0xFFFF: false
        default: true
        }
    }

    /// `headingOffset` demotes the scene's own headings, so they nest under
    /// the chapter heading (h1) in a book.
    static func serialize(_ content: NSAttributedString, headingOffset: Int = 0) -> String {
        let clean = content.strippingTransientAttributes()
        let text = clean.string as NSString
        var blocks: [String] = []
        var location = 0
        while location < text.length {
            let paragraphRange = text.paragraphRange(for: NSRange(location: location, length: 0))
            let paragraph = serializeParagraph(clean, range: paragraphRange, headingOffset: headingOffset)
            if let paragraph {
                blocks.append(paragraph)
            }
            if paragraphRange.length == 0 { break }
            location = paragraphRange.location + paragraphRange.length
        }
        return blocks.joined(separator: "\n")
    }

    private static func serializeParagraph(_ content: NSAttributedString, range: NSRange, headingOffset: Int) -> String? {
        let raw = (content.string as NSString).substring(with: range)
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        let attributes = content.attributes(at: range.location, effectiveRange: nil)
        let inner = serializeRuns(content, range: range)

        if let level = attributes[.headingLevel] as? Int, (1...3).contains(level) {
            let tag = "h\(min(level + headingOffset, 6))"
            return "<\(tag)>\(inner)</\(tag)>"
        }
        if attributes[.blockquote] != nil {
            return "<blockquote><p>\(inner)</p></blockquote>"
        }
        return "<p>\(inner)</p>"
    }

    private static func serializeRuns(_ content: NSAttributedString, range: NSRange) -> String {
        var output = ""
        content.enumerateAttributes(in: range) { attributes, runRange, _ in
            let raw = (content.string as NSString).substring(with: runRange)
                .trimmingCharacters(in: .newlines)
            guard !raw.isEmpty else { return }
            var fragment = escape(raw)

            let traits = (attributes[.font] as? NSFont)?.fontDescriptor.symbolicTraits ?? []
            let isHeading = attributes[.headingLevel] != nil
            if (attributes[.strikethroughStyle] as? Int ?? 0) != 0 {
                fragment = "<s>\(fragment)</s>"
            }
            if (attributes[.underlineStyle] as? Int ?? 0) != 0 {
                fragment = "<u>\(fragment)</u>"
            }
            if traits.contains(.italic), attributes[.blockquote] == nil {
                fragment = "<em>\(fragment)</em>"
            }
            if traits.contains(.bold), !isHeading {
                fragment = "<strong>\(fragment)</strong>"
            }
            output += fragment
        }
        return output
    }
}
