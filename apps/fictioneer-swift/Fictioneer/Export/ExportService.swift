import AppKit
import Foundation
import UniformTypeIdentifiers

nonisolated enum ExportFormat: String, CaseIterable, Identifiable, Codable, Sendable {
    case epub, rtf, txt

    var id: String { rawValue }
    var label: String {
        switch self {
        case .rtf: "Rich Text (RTF)"
        case .epub: "eBook (EPUB)"
        case .txt: "Plain Text"
        }
    }
    var shortLabel: String {
        switch self {
        case .epub: "eBook"
        case .rtf: "Manuscript"
        case .txt: "Plain Text"
        }
    }
    var detail: String {
        switch self {
        case .epub: "EPUB for Apple Books, Kobo, Kindle and stores"
        case .rtf: "RTF for Word, Pages and editors"
        case .txt: "Unformatted text, anywhere"
        }
    }
    var systemImage: String {
        switch self {
        case .epub: "book.closed"
        case .rtf: "doc.richtext"
        case .txt: "doc.plaintext"
        }
    }
    var fileExtension: String { rawValue }
    var contentType: UTType {
        switch self {
        case .rtf: .rtf
        case .epub: .epub
        case .txt: .plainText
        }
    }
}

/// Per-export choices for the manuscript formats (RTF, plain text). EPUB
/// takes everything from the project's `BookSettings`.
struct ExportOptions: Equatable {
    var format: ExportFormat = .epub
    var includeTitle = true
    var includeChapterTitles = true
    var includeSceneTitles = true
    var includeWordCount = false
}

/// Renders a book in the chosen format and remembers where each project was
/// last exported, for File ▸ Export Again.
enum ExportService {
    static func suggestedFilename(for title: String, format: ExportFormat) -> String {
        let base = title
            .map { $0.isLetter || $0.isNumber ? String($0) : "_" }
            .joined()
            .lowercased()
        return "\(base.isEmpty ? "book" : base).\(format.fileExtension)"
    }

    /// EPUB builds off the main actor; RTF needs AppKit's font manager.
    static func render(_ book: BookDocument, options: ExportOptions) async throws -> Data {
        switch options.format {
        case .epub:
            await Task.detached(priority: .userInitiated) { EpubBuilder.export(book) }.value
        case .txt:
            Data(TextExporter.export(book, options: options).utf8)
        case .rtf:
            try RTFExporter.export(book, options: options)
        }
    }

    // MARK: - Export Again

    private static func bookmarkKey(projectID: UUID, format: ExportFormat) -> String {
        "export.lastDestination.\(projectID.uuidString).\(format.rawValue)"
    }

    static func rememberDestination(_ url: URL, projectID: UUID, format: ExportFormat, defaults: UserDefaults = .standard) {
        guard let bookmark = try? url.bookmarkData(options: .withSecurityScope, includingResourceValuesForKeys: nil, relativeTo: nil)
        else { return }
        defaults.set(bookmark, forKey: bookmarkKey(projectID: projectID, format: format))
        defaults.set(format.rawValue, forKey: "export.lastFormat.\(projectID.uuidString)")
    }

    /// The format and destination of this project's last export, if the
    /// destination can still be reached.
    static func lastDestination(projectID: UUID, defaults: UserDefaults = .standard) -> (url: URL, format: ExportFormat)? {
        guard let raw = defaults.string(forKey: "export.lastFormat.\(projectID.uuidString)"),
              let format = ExportFormat(rawValue: raw),
              let bookmark = defaults.data(forKey: bookmarkKey(projectID: projectID, format: format))
        else { return nil }
        var isStale = false
        guard let url = try? URL(resolvingBookmarkData: bookmark, options: .withSecurityScope, relativeTo: nil, bookmarkDataIsStale: &isStale)
        else { return nil }
        if isStale {
            rememberDestination(url, projectID: projectID, format: format, defaults: defaults)
        }
        return (url, format)
    }

    static func write(_ data: Data, to url: URL) throws {
        let scoped = url.startAccessingSecurityScopedResource()
        defer { if scoped { url.stopAccessingSecurityScopedResource() } }
        try data.write(to: url, options: .atomic)
    }
}

// MARK: - Plain text

nonisolated enum TextExporter {
    static func export(_ book: BookDocument, options: ExportOptions) -> String {
        var output = ""
        if options.includeTitle {
            output += book.title + "\n"
            if !book.subtitle.isEmpty {
                output += book.subtitle + "\n"
            }
            if !book.author.isEmpty {
                output += "by \(book.author)\n"
            }
            output += "\n"
        }
        if !book.description.isEmpty {
            output += book.description + "\n\n"
        }
        for chapter in book.chapters {
            if options.includeChapterTitles {
                output += chapter.title.uppercased() + "\n\n"
            }
            for scene in chapter.scenes {
                if options.includeSceneTitles {
                    output += scene.title + "\n\n"
                }
                let text = scene.content.string.trimmingCharacters(in: .whitespacesAndNewlines)
                if !text.isEmpty {
                    output += text + "\n\n"
                }
                if options.includeWordCount {
                    output += "Words: \(scene.wordCount)\n\n"
                }
            }
        }
        return output
    }
}

// MARK: - RTF

enum RTFExporter {
    enum ExportError: Error {
        case rtfGenerationFailed
    }

    /// Assembles one attributed document with a fixed export theme (Times New
    /// Roman body, concrete heading fonts) and lets AppKit write the RTF.
    static func export(_ book: BookDocument, options: ExportOptions) throws -> Data {
        let document = NSMutableAttributedString()
        let bodyFont = NSFont(name: "Times New Roman", size: 12) ?? .systemFont(ofSize: 12)

        func append(_ text: String, size: CGFloat, bold: Bool = false, italic: Bool = false, centered: Bool = false) {
            var font = bodyFont.withSize(size)
            if bold { font = NSFontManager.shared.convert(font, toHaveTrait: .boldFontMask) }
            if italic { font = NSFontManager.shared.convert(font, toHaveTrait: .italicFontMask) }
            let style = NSMutableParagraphStyle()
            style.alignment = centered ? .center : .natural
            style.paragraphSpacing = 8
            document.append(NSAttributedString(string: text + "\n", attributes: [
                .font: font,
                .paragraphStyle: style,
            ]))
        }

        if options.includeTitle {
            append(book.title, size: 18, bold: true, centered: true)
            if !book.subtitle.isEmpty {
                append(book.subtitle, size: 14, italic: true, centered: true)
            }
            if !book.author.isEmpty {
                append("by \(book.author)", size: 12, centered: true)
            }
        }
        if !book.description.isEmpty {
            append(book.description, size: 12, italic: true)
        }
        for chapter in book.chapters {
            if options.includeChapterTitles {
                append(chapter.title, size: 16, bold: true)
            }
            for scene in chapter.scenes {
                if options.includeSceneTitles {
                    append(scene.title, size: 14, bold: true)
                }
                let content = scene.content
                if content.length > 0 {
                    document.append(rematerialized(content, bodyFont: bodyFont))
                    document.append(NSAttributedString(string: "\n"))
                }
                if options.includeWordCount {
                    append("Words: \(scene.wordCount)", size: 10, italic: true)
                }
            }
        }

        let range = NSRange(location: 0, length: document.length)
        guard let data = document.rtf(from: range, documentAttributes: [
            .documentType: NSAttributedString.DocumentType.rtf,
        ]) else {
            throw ExportError.rtfGenerationFailed
        }
        return data
    }

    /// Replaces editor fonts with export fonts while preserving bold/italic
    /// runs and translating heading/blockquote markers into concrete styling.
    private static func rematerialized(_ content: NSAttributedString, bodyFont: NSFont) -> NSAttributedString {
        let result = NSMutableAttributedString(attributedString: content)
        let fontManager = NSFontManager.shared
        result.enumerateAttributes(in: NSRange(location: 0, length: result.length)) { attributes, range, _ in
            var size: CGFloat = 12
            var forceBold = false
            var forceItalic = false
            if let level = attributes[.headingLevel] as? Int {
                size = level == 1 ? 18 : level == 2 ? 16 : 14
                forceBold = true
            }
            if attributes[.blockquote] != nil {
                forceItalic = true
            }
            let traits = (attributes[.font] as? NSFont).map { fontManager.traits(of: $0) } ?? []
            var font = bodyFont.withSize(size)
            if forceBold || traits.contains(.boldFontMask) {
                font = fontManager.convert(font, toHaveTrait: .boldFontMask)
            }
            if forceItalic || traits.contains(.italicFontMask) {
                font = fontManager.convert(font, toHaveTrait: .italicFontMask)
            }
            result.addAttribute(.font, value: font, range: range)
            result.removeAttribute(.foregroundColor, range: range)
            result.removeAttribute(.headingLevel, range: range)
            result.removeAttribute(.blockquote, range: range)
        }
        return result
    }
}

extension ExportOptions {
    init(defaults: ExportDefaults) {
        self.init(
            format: defaults.format,
            includeTitle: defaults.includeTitle,
            includeChapterTitles: defaults.includeChapterTitles,
            includeSceneTitles: defaults.includeSceneTitles,
            includeWordCount: defaults.includeWordCount
        )
    }

    var defaults: ExportDefaults {
        ExportDefaults(
            format: format,
            includeTitle: includeTitle,
            includeChapterTitles: includeChapterTitles,
            includeSceneTitles: includeSceneTitles,
            includeWordCount: includeWordCount,
            epubTemplate: nil
        )
    }
}
