import AppKit

/// Serializes editor content (NSAttributedString with `.headingLevel` /
/// `.blockquote` block markers and bold/italic/underline/strike runs) into
/// clean XHTML for EPUB. Everything is XML-escaped — a deliberate fix over
/// the Tauri exporter, which left titles unescaped in places.
enum XHTMLSerializer {
    static func escape(_ text: String) -> String {
        text.replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&#x27;")
    }

    static func serialize(_ content: NSAttributedString) -> String {
        let clean = content.strippingTransientAttributes()
        let text = clean.string as NSString
        var blocks: [String] = []
        var location = 0
        while location < text.length {
            let paragraphRange = text.paragraphRange(for: NSRange(location: location, length: 0))
            let paragraph = serializeParagraph(clean, range: paragraphRange)
            if let paragraph {
                blocks.append(paragraph)
            }
            if paragraphRange.length == 0 { break }
            location = paragraphRange.location + paragraphRange.length
        }
        return blocks.joined(separator: "\n")
    }

    private static func serializeParagraph(_ content: NSAttributedString, range: NSRange) -> String? {
        let raw = (content.string as NSString).substring(with: range)
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        let attributes = content.attributes(at: range.location, effectiveRange: nil)
        let inner = serializeRuns(content, range: range)

        if let level = attributes[.headingLevel] as? Int, (1...3).contains(level) {
            return "<h\(level)>\(inner)</h\(level)>"
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

            let traits = (attributes[.font] as? NSFont).map {
                NSFontManager.shared.traits(of: $0)
            } ?? []
            let isHeading = attributes[.headingLevel] != nil
            if (attributes[.strikethroughStyle] as? Int ?? 0) != 0 {
                fragment = "<s>\(fragment)</s>"
            }
            if (attributes[.underlineStyle] as? Int ?? 0) != 0 {
                fragment = "<u>\(fragment)</u>"
            }
            if traits.contains(.italicFontMask), attributes[.blockquote] == nil {
                fragment = "<em>\(fragment)</em>"
            }
            if traits.contains(.boldFontMask), !isHeading {
                fragment = "<strong>\(fragment)</strong>"
            }
            output += fragment
        }
        return output
    }
}
