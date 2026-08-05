import AppKit
import Foundation
import UniformTypeIdentifiers

enum ExportFormat: String, CaseIterable, Identifiable, Codable {
    case rtf, epub, txt

    var id: String { rawValue }
    var label: String {
        switch self {
        case .rtf: "Rich Text (RTF)"
        case .epub: "eBook (EPUB)"
        case .txt: "Plain Text"
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

struct ExportOptions {
    var format: ExportFormat = .rtf
    var includeTitle = true
    var includeChapterTitles = true
    var includeSceneTitles = true
    var includeWordCount = false
    var epubTemplate: EpubTemplate = .genericNovel
    /// Empty fields mean "use the project's saved metadata".
    var epubMetadata = ProjectEpubMetadata(author: "", publisher: "", language: "", rights: "", subjects: [])
}

/// Builds export payloads from the project and drives the save panel.
enum ExportService {
    static func suggestedFilename(for project: Project, format: ExportFormat) -> String {
        let base = project.title
            .map { $0.isLetter || $0.isNumber ? String($0) : "_" }
            .joined()
            .lowercased()
        return "\(base).\(format.fileExtension)"
    }

    static func exportData(project: Project, options: ExportOptions) throws -> Data {
        switch options.format {
        case .txt:
            Data(TextExporter.export(project: project, options: options).utf8)
        case .rtf:
            try RTFExporter.export(project: project, options: options)
        case .epub:
            EpubBuilder.export(project: project, options: options)
        }
    }

    /// Runs the save panel and writes the payload. Returns false when the
    /// user cancels.
    @discardableResult
    static func exportViaPanel(project: Project, options: ExportOptions) throws -> Bool {
        let panel = NSSavePanel()
        panel.title = "Export Project"
        panel.nameFieldStringValue = suggestedFilename(for: project, format: options.format)
        panel.allowedContentTypes = [options.format.contentType]
        panel.canCreateDirectories = true
        guard panel.runModal() == .OK, let url = panel.url else { return false }
        let data = try exportData(project: project, options: options)
        try data.write(to: url, options: .atomic)
        return true
    }
}

// MARK: - Plain text

enum TextExporter {
    static func export(project: Project, options: ExportOptions) -> String {
        var output = ""
        if options.includeTitle {
            output += project.title + "\n\n"
        }
        if !project.details.isEmpty {
            output += project.details + "\n\n"
        }
        for chapter in project.chapters {
            if options.includeChapterTitles {
                output += chapter.title.uppercased() + "\n\n"
            }
            for scene in chapter.scenes {
                if options.includeSceneTitles {
                    output += scene.title + "\n\n"
                }
                let text = scene.content.strippingTransientAttributes().string
                    .trimmingCharacters(in: .whitespacesAndNewlines)
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
    static func export(project: Project, options: ExportOptions) throws -> Data {
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
            append(project.title, size: 18, bold: true, centered: true)
        }
        if !project.details.isEmpty {
            append(project.details, size: 12, italic: true)
        }
        for chapter in project.chapters {
            if options.includeChapterTitles {
                append(chapter.title, size: 16, bold: true)
            }
            for scene in chapter.scenes {
                if options.includeSceneTitles {
                    append(scene.title, size: 14, bold: true)
                }
                let content = scene.content.strippingTransientAttributes()
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
