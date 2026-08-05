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

// MARK: - Serializers / exporters

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
    project.epubMetadata = ProjectEpubMetadata(
        author: "T. Author", publisher: "", language: "de", rights: "", subjects: ["Mystery & Co"]
    )
    return project
}

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
        let text = TextExporter.export(project: makeProject(), options: options)
        #expect(text.hasPrefix("Export & Test\n\n"))
        #expect(text.contains("CHAPTER <1>\n\n"))
        #expect(text.contains("Scene <One>\n\n"))
        #expect(text.contains("The Heading"))
        #expect(text.contains("Words: "))
    }
}

@MainActor
struct RTFExporterTests {
    @Test func rtfRoundTripsThroughAppKit() throws {
        var options = ExportOptions()
        options.format = .rtf
        let data = try RTFExporter.export(project: makeProject(), options: options)
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
        var options = ExportOptions()
        options.format = .epub
        let data = EpubBuilder.export(project: makeProject(), options: options)
        let entries = try readZip(data)

        #expect(entries.first?.path == "mimetype")
        #expect(entries.first?.method == 0)
        let paths = entries.map(\.path)
        #expect(paths.contains("META-INF/container.xml"))
        #expect(paths.contains("OEBPS/content.opf"))
        #expect(paths.contains("OEBPS/toc.ncx"))
        #expect(paths.contains("OEBPS/nav.xhtml"))
        #expect(paths.contains("OEBPS/stylesheet.css"))
        #expect(paths.contains("OEBPS/title.xhtml"))
        #expect(paths.contains("OEBPS/chapter_01.xhtml"))

        let opf = String(data: entries.first { $0.path == "OEBPS/content.opf" }!.data, encoding: .utf8)!
        #expect(opf.contains("<dc:title>Export &amp; Test</dc:title>"))
        #expect(opf.contains("<dc:creator>T. Author</dc:creator>"))
        #expect(opf.contains("<dc:language>de</dc:language>"))
        #expect(opf.contains("<dc:subject>Mystery &amp; Co</dc:subject>"))
        #expect(opf.contains("properties=\"nav\""))

        let chapter = String(data: entries.first { $0.path == "OEBPS/chapter_01.xhtml" }!.data, encoding: .utf8)!
        #expect(chapter.contains("<h2 class=\"chapter-title\">Chapter &lt;1&gt;</h2>"))
        #expect(chapter.contains("<h3 class=\"scene-title\">Scene &lt;One&gt;</h3>"))
        #expect(chapter.contains("<strong>bold</strong>"))
    }

    @Test func everyXMLEntryParsesLikeAReader() throws {
        var options = ExportOptions()
        options.format = .epub
        options.includeWordCount = true
        let data = EpubBuilder.export(project: makeProject(), options: options)
        let entries = try readZip(data)
        expectWellFormedXML(in: entries)
    }

    /// XML-illegal control characters and the attachment placeholder must
    /// never reach the serialized output, and hostile metadata strings must
    /// be escaped like every other field.
    @Test func controlCharactersAndHostileMetadataAreSanitized() throws {
        let scene = Scene(title: "Bell", content: NSAttributedString(
            string: "A bell\u{07} rang\u{FFFC} and echoed.\n",
            attributes: [.font: NSFont.systemFont(ofSize: 18)]
        ))
        let project = Project(
            title: "Sanitize",
            chapters: [Chapter(title: "One", scenes: [scene])]
        )
        var options = ExportOptions()
        options.format = .epub
        options.epubMetadata = ProjectEpubMetadata(
            author: "A", publisher: "", language: "de\"><evil>&", rights: "", subjects: []
        )

        let data = EpubBuilder.export(project: project, options: options)
        let entries = try readZip(data)
        expectWellFormedXML(in: entries)

        let opf = String(data: entries.first { $0.path == "OEBPS/content.opf" }!.data, encoding: .utf8)!
        #expect(opf.contains("<dc:language>de&quot;&gt;&lt;evil&gt;&amp;</dc:language>"))
        #expect(!opf.contains("<dc:language>de\"><evil>&</dc:language>"))

        let chapter = String(data: entries.first { $0.path == "OEBPS/chapter_01.xhtml" }!.data, encoding: .utf8)!
        #expect(!chapter.contains("\u{07}"))
        #expect(!chapter.contains("\u{FFFC}"))
        #expect(chapter.contains("A bell rang and echoed."))
    }

    @Test func metadataOverridesProjectDefaults() throws {
        var options = ExportOptions()
        options.format = .epub
        options.epubMetadata = ProjectEpubMetadata(
            author: "Override Author", publisher: "", language: "", rights: "", subjects: []
        )
        let data = EpubBuilder.export(project: makeProject(), options: options)
        let entries = try readZip(data)
        let opf = String(data: entries.first { $0.path == "OEBPS/content.opf" }!.data, encoding: .utf8)!
        #expect(opf.contains("<dc:creator>Override Author</dc:creator>"))
        #expect(opf.contains("<dc:language>de</dc:language>")) // project value survives empty override
    }
}
