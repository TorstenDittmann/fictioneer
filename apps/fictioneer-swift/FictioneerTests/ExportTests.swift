import AppKit
import Foundation
import Testing
@testable import Fictioneer

// MARK: - Zip structural reader (test-side)

private struct ZipEntryRecord {
    var path: String
    var method: Int
    var crc: UInt32
    var size: Int
    var data: Data
    var offset: Int
}

/// Parses the archive the way a real reader does: walks the local headers,
/// then locates the end-of-central-directory record, walks the central
/// directory, and cross-checks every central record (path/CRC/sizes) against
/// the local header at its recorded offset.
private func readZip(_ archive: Data) throws -> [ZipEntryRecord] {
    var entries: [ZipEntryRecord] = []
    var cursor = 0
    func u16(_ offset: Int) -> Int {
        Int(archive[offset]) | (Int(archive[offset + 1]) << 8)
    }
    func u32(_ offset: Int) -> UInt32 {
        UInt32(archive[offset])
            | (UInt32(archive[offset + 1]) << 8)
            | (UInt32(archive[offset + 2]) << 16)
            | (UInt32(archive[offset + 3]) << 24)
    }
    while cursor + 4 <= archive.count, u32(cursor) == 0x04034B50 {
        let entryOffset = cursor
        let method = u16(cursor + 8)
        let crc = u32(cursor + 14)
        let compressedSize = Int(u32(cursor + 18))
        let nameLength = u16(cursor + 26)
        let extraLength = u16(cursor + 28)
        let nameStart = cursor + 30
        let path = String(data: archive.subdata(in: nameStart..<(nameStart + nameLength)), encoding: .utf8)!
        let dataStart = nameStart + nameLength + extraLength
        let data = archive.subdata(in: dataStart..<(dataStart + compressedSize))
        entries.append(ZipEntryRecord(path: path, method: method, crc: crc, size: compressedSize, data: data, offset: entryOffset))
        cursor = dataStart + compressedSize
    }

    // End of central directory (no archive comment → fixed 22-byte tail).
    let eocd = archive.count - 22
    #expect(eocd >= 0 && u32(eocd) == 0x06054B50, "missing end-of-central-directory record")
    guard eocd >= 0, u32(eocd) == 0x06054B50 else { return entries }
    let totalEntries = u16(eocd + 10)
    let centralSize = Int(u32(eocd + 12))
    let centralOffset = Int(u32(eocd + 16))
    #expect(totalEntries == entries.count)
    #expect(centralOffset + centralSize == eocd)

    var central = centralOffset
    var centralCount = 0
    while central + 4 <= eocd, u32(central) == 0x02014B50 {
        let crc = u32(central + 16)
        let compressedSize = Int(u32(central + 20))
        let uncompressedSize = Int(u32(central + 24))
        let nameLength = u16(central + 28)
        let extraLength = u16(central + 30)
        let commentLength = u16(central + 32)
        let localOffset = Int(u32(central + 42))
        let nameStart = central + 46
        let path = String(data: archive.subdata(in: nameStart..<(nameStart + nameLength)), encoding: .utf8)!

        // Cross-check against the local header this record points at.
        let local = entries.first { $0.offset == localOffset }
        #expect(local != nil, "central record \(path) points at offset \(localOffset) with no local header")
        if let local {
            #expect(local.path == path)
            #expect(local.crc == crc)
            #expect(local.size == compressedSize)
            #expect(local.size == uncompressedSize) // STORED
            #expect(ZipWriter.crc32(local.data) == crc)
        }

        central = nameStart + nameLength + extraLength + commentLength
        centralCount += 1
    }
    #expect(centralCount == entries.count)
    return entries
}

/// Runs Foundation's XML parser over every XML-family entry (as an EPUB
/// reader would) and reports any that fail to parse.
private func expectWellFormedXML(in entries: [ZipEntryRecord]) {
    let xmlSuffixes = [".xhtml", ".opf", ".ncx", ".xml"]
    let xmlEntries = entries.filter { entry in xmlSuffixes.contains { entry.path.hasSuffix($0) } }
    #expect(!xmlEntries.isEmpty)
    for entry in xmlEntries {
        let parser = XMLParser(data: entry.data)
        #expect(parser.parse(), "\(entry.path) is not well-formed XML: \(String(describing: parser.parserError))")
    }
}

struct ZipWriterTests {
    @Test func crc32KnownVectors() {
        #expect(ZipWriter.crc32(Data("123456789".utf8)) == 0xCBF43926)
        #expect(ZipWriter.crc32(Data()) == 0)
        #expect(ZipWriter.crc32(Data("a".utf8)) == 0xE8B7BE43)
    }

    @Test func archiveRoundTripsThroughStructuralReader() throws {
        let entries = [
            ZipWriter.Entry(path: "mimetype", text: "application/epub+zip"),
            ZipWriter.Entry(path: "OEBPS/a.xhtml", text: "<html>é and — dashes</html>"),
        ]
        let archive = ZipWriter.archive(entries)
        let read = try readZip(archive)
        #expect(read.count == 2)
        #expect(read[0].path == "mimetype")
        #expect(read[0].method == 0) // STORED
        #expect(String(data: read[0].data, encoding: .utf8) == "application/epub+zip")
        #expect(read[1].crc == ZipWriter.crc32(read[1].data))
        // End-of-central-directory signature present
        let tail = [UInt8](archive.suffix(22).prefix(4))
        #expect(tail == [0x50, 0x4B, 0x05, 0x06])
    }
}

// MARK: - Fixtures

@MainActor
private func makeRichScene() -> Scene {
    let content = NSMutableAttributedString()
    content.append(NSAttributedString(string: "The Heading\n", attributes: [
        .headingLevel: 2,
        .font: NSFont.boldSystemFont(ofSize: 24),
    ]))
    content.append(NSAttributedString(string: "Plain with ", attributes: [
        .font: NSFont.systemFont(ofSize: 18),
    ]))
    content.append(NSAttributedString(string: "bold", attributes: [
        .font: NSFontManager.shared.convert(.systemFont(ofSize: 18), toHaveTrait: .boldFontMask),
    ]))
    content.append(NSAttributedString(string: " & <escaped>.\n", attributes: [
        .font: NSFont.systemFont(ofSize: 18),
    ]))
    content.append(NSAttributedString(string: "A quote line.\n", attributes: [
        .blockquote: true,
        .font: NSFont.systemFont(ofSize: 18),
    ]))
    return Scene(title: "Scene <One>", content: content)
}

@MainActor
private func makeProject() -> Project {
    let project = Project(
        title: "Export & Test",
        details: "A story about \"quotes\".",
        chapters: [Chapter(title: "Chapter <1>", scenes: [makeRichScene()])]
    )
    project.book.author = "T. Author"
    project.book.language = "de"
    project.book.subjects = ["Mystery & Co"]
    return project
}

private func text(_ entries: [ZipEntryRecord], _ path: String) -> String {
    entries.first { $0.path == path }.map { String(decoding: $0.data, as: UTF8.self) } ?? ""
}

@MainActor
private func epubEntries(_ project: Project) throws -> [ZipEntryRecord] {
    try readZip(EpubBuilder.export(BookDocument.make(from: project)))
}

// MARK: - Serializers / exporters

@MainActor
struct XHTMLSerializerTests {
    @Test func serializesBlocksAndInlineStyles() {
        let xhtml = XHTMLSerializer.serialize(makeRichScene().content)
        #expect(xhtml.contains("<h2>The Heading</h2>"))
        #expect(xhtml.contains("<strong>bold</strong>"))
        #expect(xhtml.contains("&amp; &lt;escaped&gt;."))
        #expect(xhtml.contains("<blockquote><p>A quote line.</p></blockquote>"))
        #expect(!xhtml.contains("<p></p>"))
    }

    @Test func headingOffsetDemotesSceneHeadings() {
        let xhtml = XHTMLSerializer.serialize(makeRichScene().content, headingOffset: 1)
        #expect(xhtml.contains("<h3>The Heading</h3>"))
    }

    @Test func escapingCoversAllFive() {
        #expect(XHTMLSerializer.escape("&<>\"'") == "&amp;&lt;&gt;&quot;&#x27;")
    }
}

@MainActor
struct TextExporterTests {
    @Test func goldenLayout() {
        var options = ExportOptions()
        options.format = .txt
        options.includeWordCount = true
        let text = TextExporter.export(BookDocument.make(from: makeProject()), options: options)
        #expect(text.hasPrefix("Export & Test\nby T. Author\n\n"))
        #expect(text.contains("CHAPTER <1>\n\n"))
        #expect(text.contains("Scene <One>\n\n"))
        #expect(text.contains("The Heading"))
        #expect(text.contains("Words: "))
    }

    @Test func excludedScenesAreLeftOut() {
        let project = makeProject()
        let hidden = Scene(title: "Hidden", content: NSAttributedString(string: "Secret words."))
        project.chapters[0].scenes.append(hidden)
        project.book.excludedSceneIDs = [hidden.id]
        let text = TextExporter.export(BookDocument.make(from: project), options: ExportOptions())
        #expect(!text.contains("Secret words."))
    }
}

@MainActor
struct RTFExporterTests {
    @Test func rtfRoundTripsThroughAppKit() throws {
        var options = ExportOptions()
        options.format = .rtf
        let data = try RTFExporter.export(BookDocument.make(from: makeProject()), options: options)
        let parsed = NSAttributedString(rtf: data, documentAttributes: nil)
        let string = try #require(parsed?.string)
        #expect(string.contains("Export & Test"))
        #expect(string.contains("Chapter <1>"))
        #expect(string.contains("The Heading"))
        #expect(string.contains("bold"))
        #expect(string.contains("A quote line."))
    }
}

@MainActor
struct EpubBuilderTests {
    @Test func structureMatchesContract() throws {
        let entries = try epubEntries(makeProject())

        #expect(entries.first?.path == "mimetype")
        #expect(entries.first?.method == 0)
        let paths = Set(entries.map(\.path))
        for path in [
            "META-INF/container.xml", "OEBPS/content.opf", "OEBPS/toc.ncx", "OEBPS/nav.xhtml",
            "OEBPS/styles/book.css", "OEBPS/images/cover.jpg", "OEBPS/text/cover.xhtml",
            "OEBPS/text/title.xhtml", "OEBPS/text/copyright.xhtml", "OEBPS/text/chapter_01.xhtml",
        ] {
            #expect(paths.contains(path), "missing \(path)")
        }

        let opf = text(entries, "OEBPS/content.opf")
        #expect(opf.contains("<dc:title id=\"title\">Export &amp; Test</dc:title>"))
        #expect(opf.contains("<dc:creator id=\"author\">T. Author</dc:creator>"))
        #expect(opf.contains("<dc:language>de</dc:language>"))
        #expect(opf.contains("<dc:subject>Mystery &amp; Co</dc:subject>"))
        #expect(opf.contains("properties=\"nav\""))
        #expect(opf.contains("properties=\"cover-image\""))
        #expect(opf.contains("<meta property=\"schema:accessMode\">textual</meta>"))
        #expect(opf.range(of: #"dcterms:modified">\d{4}-\d\d-\d\dT\d\d:\d\d:\d\dZ<"#, options: .regularExpression) != nil)

        let chapter = text(entries, "OEBPS/text/chapter_01.xhtml")
        #expect(chapter.contains("<p class=\"chapter-label\" aria-hidden=\"true\">Kapitel Eins</p>"))
        #expect(chapter.contains("class=\"chapter-title\" aria-label=\"Kapitel Eins: Chapter &lt;1&gt;\">Chapter &lt;1&gt;</h1>"))
        #expect(!chapter.contains("scene-title"))
        #expect(chapter.contains("<h3>The Heading</h3>"))
        #expect(chapter.contains("<strong>bold</strong>"))
        #expect(chapter.contains("xml:lang=\"de\""))
    }

    @Test func identifierIsStableAcrossExports() throws {
        let project = makeProject()
        let first = text(try epubEntries(project), "OEBPS/content.opf")
        let second = text(try epubEntries(project), "OEBPS/content.opf")
        let identifier = "urn:uuid:\(project.id.uuidString.lowercased())"
        #expect(first.contains(identifier))
        #expect(second.contains(identifier))
    }

    @Test func fullBookParsesLikeAReader() throws {
        let project = makeProject()
        project.chapters.append(Chapter(title: "Second", scenes: [
            Scene(title: "A", content: NSAttributedString(string: "First scene.")),
            Scene(title: "B", content: NSAttributedString(string: "Second scene.")),
        ]))
        project.book.subtitle = "A <Subtitle>"
        project.book.isbn = "978-0-306-40615-7"
        project.book.series = "The & Series"
        project.book.seriesNumber = "2"
        project.book.dedication = "For you & me"
        project.book.epigraph = "Words <matter>."
        project.book.epigraphAttribution = "Someone"
        project.book.acknowledgements = "Thanks.\nMore thanks."
        project.book.aboutAuthor = "Writes things."
        project.book.alsoBy = "Book One\nBook Two"
        project.book.showsSceneTitles = true
        project.book.sceneBreak = .fleuron
        project.book.bodyFont = .quattrocento
        let entries = try epubEntries(project)
        expectWellFormedXML(in: entries)

        let paths = Set(entries.map(\.path))
        for path in ["dedication", "epigraph", "acknowledgements", "about", "also_by"] {
            #expect(paths.contains("OEBPS/text/\(path).xhtml"), "missing \(path)")
        }
        #expect(paths.contains("OEBPS/fonts/Quattrocento-Regular.ttf"))

        let opf = text(entries, "OEBPS/content.opf")
        #expect(opf.contains("urn:isbn:9780306406157"))
        #expect(opf.contains("<meta refines=\"#series\" property=\"group-position\">2</meta>"))
        #expect(opf.contains("<dc:title id=\"subtitle\">A &lt;Subtitle&gt;</dc:title>"))

        let chapter = text(entries, "OEBPS/text/chapter_02.xhtml")
        #expect(chapter.contains("<h2 class=\"scene-title\">A</h2>"))
        #expect(chapter.contains(">❦</p>"))

        let nav = text(entries, "OEBPS/nav.xhtml")
        #expect(nav.contains("chapter_02.xhtml#scene-"))
        #expect(nav.contains("epub:type=\"landmarks\""))
        #expect(nav.contains("Also by T. Author"))
    }

    @Test func spineFollowsBookOrder() {
        let project = makeProject()
        project.book.dedication = "For you"
        project.book.aboutAuthor = "Bio"
        let publication = EpubBuilder.publication(for: BookDocument.make(from: project))
        #expect(publication.spine.map(\.kind) == [.cover, .titlePage, .copyright, .dedication, .contents, .chapter, .backMatter])
    }

    @Test func optionalPagesCanBeTurnedOff() {
        let project = makeProject()
        project.book.cover = .none
        project.book.includesTitlePage = false
        project.book.includesCopyrightPage = false
        project.book.includesTableOfContents = false
        let publication = EpubBuilder.publication(for: BookDocument.make(from: project))
        #expect(publication.spine.map(\.kind) == [.chapter])
        // The navigation document stays in the package; it's required.
        #expect(publication.file(at: "OEBPS/nav.xhtml") != nil)
        #expect(publication.file(at: "OEBPS/images/cover.jpg") == nil)
    }

    @Test func excludedChaptersAreDroppedAndRenumbered() throws {
        let project = makeProject()
        let skipped = project.chapters[0]
        project.chapters.append(Chapter(title: "Kept", scenes: [Scene(title: "S", content: NSAttributedString(string: "Text."))]))
        project.book.excludedChapterIDs = [skipped.id]
        project.book.language = "en"
        let entries = try epubEntries(project)
        let chapter = text(entries, "OEBPS/text/chapter_01.xhtml")
        #expect(chapter.contains("Chapter One"))
        #expect(chapter.contains(">Kept</h1>"))
        #expect(!entries.contains { $0.path == "OEBPS/text/chapter_02.xhtml" })
    }

    /// XML-illegal control characters and the attachment placeholder must
    /// never reach the serialized output, and hostile metadata strings must
    /// be escaped like every other field.
    @Test func controlCharactersAndHostileMetadataAreSanitized() throws {
        let scene = Scene(title: "Bell", content: NSAttributedString(
            string: "A bell\u{07} rang\u{FFFC} and echoed.\n",
            attributes: [.font: NSFont.systemFont(ofSize: 18)]
        ))
        let project = Project(title: "Sanitize", chapters: [Chapter(title: "One", scenes: [scene])])
        project.book.author = "A"
        project.book.language = "de\"><evil>&"

        let entries = try epubEntries(project)
        expectWellFormedXML(in: entries)

        let opf = text(entries, "OEBPS/content.opf")
        #expect(opf.contains("<dc:language>de&quot;&gt;&lt;evil&gt;&amp;</dc:language>"))
        #expect(!opf.contains("<dc:language>de\"><evil>&</dc:language>"))

        let chapter = text(entries, "OEBPS/text/chapter_01.xhtml")
        #expect(!chapter.contains("\u{07}"))
        #expect(!chapter.contains("\u{FFFC}"))
        #expect(chapter.contains("A bell rang and echoed."))
    }

    @Test func manuscriptPreviewIsWellFormed() throws {
        for format in [ExportFormat.rtf, .txt] {
            var options = ExportOptions()
            options.format = format
            let publication = ManuscriptPreview.publication(for: BookDocument.make(from: makeProject()), options: options)
            let file = try #require(publication.files.first)
            let parser = XMLParser(data: file.data)
            #expect(parser.parse(), "\(format) preview is not well-formed")
        }
    }
}

// MARK: - Book model

@MainActor
struct BookDocumentTests {
    @Test func chapterLabelsFollowTheBookLanguage() {
        #expect(ChapterNumbering.label(for: 1, language: "en") == "Chapter One")
        #expect(ChapterNumbering.label(for: 21, language: "en-GB") == "Chapter Twenty-one")
        #expect(ChapterNumbering.label(for: 3, language: "de") == "Kapitel Drei")
        #expect(ChapterNumbering.label(for: 12, language: "ja") == "Chapter 12")
    }

    @Test func copyrightLineIsGeneratedUnlessCustom() {
        let project = makeProject()
        let now = ISO8601DateFormatter().date(from: "2026-05-01T12:00:00Z")!
        #expect(BookDocument.make(from: project, now: now).copyrightLine == "Copyright © 2026 T. Author. All rights reserved.")
        project.book.rights = "© The Estate"
        #expect(BookDocument.make(from: project, now: now).copyrightLine == "© The Estate")
    }

    @Test func isbnChecksums() {
        #expect(ISBN.isValid("978-0-306-40615-7"))
        #expect(ISBN.isValid("0-306-40615-2"))
        #expect(ISBN.isValid("0-8044-2957-X"))
        #expect(!ISBN.isValid("978-0-306-40615-8"))
        #expect(!ISBN.isValid("12345"))
    }

    @Test func readinessFlagsWhatMatters() {
        let project = makeProject()
        project.book.author = ""
        project.book.isbn = "978-0-306-40615-8"
        project.book.cover = .image
        let issues = BookReadiness.issues(for: BookDocument.make(from: project), format: .epub)
        let ids = Set(issues.map(\.id))
        #expect(ids.isSuperset(of: ["author", "isbn", "cover"]))
        #expect(!issues.contains { $0.severity == .blocking })

        // Manuscript formats don't need store metadata.
        let manuscript = BookReadiness.issues(for: BookDocument.make(from: project), format: .rtf)
        #expect(!manuscript.contains { $0.id == "author" })
    }

    @Test func excludingEverythingBlocksExport() {
        let project = makeProject()
        project.book.excludedChapterIDs = Set(project.chapters.map(\.id))
        let issues = BookReadiness.issues(for: BookDocument.make(from: project), format: .txt)
        #expect(issues.first?.severity == .blocking)
    }

    @Test func draftScenesAreSuggested() {
        let project = makeProject()
        project.chapters[0].scenes[0].status = .draft
        let issues = BookReadiness.issues(for: BookDocument.make(from: project), format: .epub)
        #expect(issues.contains { $0.id == "drafts" && $0.severity == .suggestion })
    }

    @Test func unknownSettingValuesDegradeFieldByField() throws {
        let json = #"{"author":"Kept","template":"holographic","sceneBreak":"fleuron","excludedSceneIDs":"nonsense"}"#
        let settings = try JSONDecoder().decode(BookSettings.self, from: Data(json.utf8))
        #expect(settings.author == "Kept")
        #expect(settings.template == .genericNovel)
        #expect(settings.sceneBreak == .fleuron)
        #expect(settings.excludedSceneIDs.isEmpty)
    }
}

// MARK: - Covers

struct CoverRendererTests {
    @Test(arguments: CoverDesign.allCases)
    func rendersEveryDesign(design: CoverDesign) throws {
        let input = CoverRenderer.Input(
            title: "The Extraordinarily Long Title of a Book That Keeps Going",
            subtitle: "A Novel", author: "Jane Writer", series: "Saga · Book 2",
            design: design, palette: .ink
        )
        let data = try #require(CoverRenderer.jpegData(for: input))
        let rep = try #require(NSBitmapImageRep(data: data))
        #expect(rep.pixelsWide == 1600)
        #expect(rep.pixelsHigh == 2560)
    }

    @Test func emptyFieldsStillRender() {
        let input = CoverRenderer.Input(title: "", subtitle: "", author: "", series: "", design: .modern, palette: .paper)
        #expect(CoverRenderer.render(input, size: CGSize(width: 160, height: 256)) != nil)
    }
}
