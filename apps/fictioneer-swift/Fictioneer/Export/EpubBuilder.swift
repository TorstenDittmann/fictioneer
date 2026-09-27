import Foundation

/// A built EPUB before zipping: every file by path, plus the reading order.
/// The preview serves these same files, so it can't drift from the export.
nonisolated struct EpubPublication: Sendable {
    struct File: Sendable {
        let path: String
        let data: Data
        let mediaType: String
    }

    struct SpineItem: Sendable, Equatable {
        enum Kind: Sendable, Equatable {
            case cover, titlePage, copyright, dedication, epigraph, contents, chapter, backMatter
        }
        let id: String
        /// Path inside the container, e.g. `OEBPS/text/chapter_01.xhtml`.
        let path: String
        let title: String
        let kind: Kind
    }

    /// In zip order: `mimetype` first.
    let files: [File]
    let spine: [SpineItem]

    func file(at path: String) -> File? {
        files.first { $0.path == path }
    }
}

/// Builds an EPUB 3 publication (with an EPUB 2 NCX for older readers):
/// cover, title and copyright pages, dedication, epigraph, contents, one
/// file per chapter, then back matter. Everything user-supplied is escaped.
nonisolated enum EpubBuilder {
    static func export(_ book: BookDocument) -> Data {
        archive(publication(for: book))
    }

    static func archive(_ publication: EpubPublication) -> Data {
        ZipWriter.archive(publication.files.map { ZipWriter.Entry(path: $0.path, data: $0.data) })
    }

    static func publication(for book: BookDocument) -> EpubPublication {
        publication(for: book, coverData: resolvedCover(for: book))
    }

    /// The supplied image, or a designed cover rendered at full size.
    static func resolvedCover(for book: BookDocument) -> (data: Data, fileExtension: String)? {
        switch book.settings.cover {
        case .none:
            return nil
        case .image:
            return book.coverImage.map { ($0.data, $0.fileExtension) }
        case .generated:
            return CoverRenderer.jpegData(for: CoverRenderer.input(for: book)).map { ($0, "jpg") }
        }
    }

    static func publication(for book: BookDocument, coverData: (data: Data, fileExtension: String)?) -> EpubPublication {
        var builder = Builder(book: book)
        return builder.build(coverData: coverData)
    }

    private struct ManifestItem {
        let id: String
        let href: String
        let mediaType: String
        var properties: String?
    }

    private struct Builder {
        let book: BookDocument
        var files: [EpubPublication.File] = []
        var manifest: [ManifestItem] = []
        var spine: [EpubPublication.SpineItem] = []

        init(book: BookDocument) {
            self.book = book
        }

        private var escape: (String) -> String { XHTMLSerializer.escape }

        mutating func build(coverData: (data: Data, fileExtension: String)?) -> EpubPublication {
            let settings = book.settings
            files.append(.init(path: "mimetype", data: Data("application/epub+zip".utf8), mediaType: "text/plain"))
            addFile("META-INF/container.xml", containerXML, mediaType: "application/xml")

            addFile("OEBPS/styles/book.css", BookStylesheet.css(for: settings), mediaType: "text/css")
            manifest.append(ManifestItem(id: "css", href: "styles/book.css", mediaType: "text/css"))
            for font in BookStylesheet.embeddedFonts(for: settings) {
                guard let data = font.data else { continue }
                files.append(.init(path: "OEBPS/fonts/\(font.filename)", data: data, mediaType: "font/ttf"))
                manifest.append(ManifestItem(
                    id: "font-\(font.weight)", href: "fonts/\(font.filename)", mediaType: "font/ttf"
                ))
            }

            if let coverData {
                let mediaType = coverData.fileExtension == "png" ? "image/png" : "image/jpeg"
                let href = "images/cover.\(coverData.fileExtension)"
                files.append(.init(path: "OEBPS/\(href)", data: coverData.data, mediaType: mediaType))
                manifest.append(ManifestItem(id: "cover-image", href: href, mediaType: mediaType, properties: "cover-image"))
                addPage(id: "cover", name: "cover", title: "Cover", kind: .cover, bodyClass: "cover-page", body: """
                \t\t<section epub:type="cover">
                \t\t\t<img src="../\(href)" alt="\(escape(coverAltText))" role="doc-cover" />
                \t\t</section>
                """)
            }

            if settings.includesTitlePage {
                var body = "\t\t<section class=\"titlepage\" epub:type=\"titlepage\">\n"
                body += "\t\t\t<h1 class=\"book-title\">\(escape(book.title))</h1>\n"
                if !book.subtitle.isEmpty {
                    body += "\t\t\t<p class=\"book-subtitle\">\(escape(book.subtitle))</p>\n"
                }
                if !book.author.isEmpty {
                    body += "\t\t\t<p class=\"book-author\">\(escape(book.author))</p>\n"
                }
                let publisher = settings.publisher.trimmingCharacters(in: .whitespaces)
                if !publisher.isEmpty {
                    body += "\t\t\t<p class=\"book-publisher\">\(escape(publisher))</p>\n"
                }
                body += "\t\t</section>"
                addPage(id: "titlepage", name: "title", title: book.title, kind: .titlePage, bodyClass: "frontmatter", body: body)
            }

            if settings.includesCopyrightPage {
                var lines = [book.title + (book.subtitle.isEmpty ? "" : ": \(book.subtitle)")]
                lines.append(book.copyrightLine)
                if let isbn = book.normalizedISBN {
                    lines.append("ISBN \(isbn)")
                }
                let publisher = settings.publisher.trimmingCharacters(in: .whitespaces)
                if !publisher.isEmpty {
                    lines.append("Published by \(publisher)")
                }
                let body = "\t\t<section class=\"copyright\" epub:type=\"copyright-page\">\n"
                    + lines.map { "\t\t\t<p>\(escape($0))</p>\n" }.joined()
                    + "\t\t</section>"
                addPage(id: "copyright", name: "copyright", title: "Copyright", kind: .copyright, bodyClass: "frontmatter", body: body)
            }

            let dedication = settings.dedication.trimmingCharacters(in: .whitespacesAndNewlines)
            if !dedication.isEmpty {
                addPage(id: "dedication", name: "dedication", title: "Dedication", kind: .dedication, bodyClass: "frontmatter", body: """
                \t\t<section class="dedication" epub:type="dedication" role="doc-dedication">
                \(paragraphs(dedication, indent: 3))
                \t\t</section>
                """)
            }

            let epigraph = settings.epigraph.trimmingCharacters(in: .whitespacesAndNewlines)
            if !epigraph.isEmpty {
                var body = "\t\t<section class=\"epigraph\" epub:type=\"epigraph\" role=\"doc-epigraph\">\n"
                body += "\t\t\t<blockquote>\n\(paragraphs(epigraph, indent: 4))\n\t\t\t</blockquote>\n"
                let attribution = settings.epigraphAttribution.trimmingCharacters(in: .whitespaces)
                if !attribution.isEmpty {
                    body += "\t\t\t<p class=\"attribution\">— \(escape(attribution))</p>\n"
                }
                body += "\t\t</section>"
                addPage(id: "epigraph", name: "epigraph", title: "Epigraph", kind: .epigraph, bodyClass: "frontmatter", body: body)
            }

            // The navigation document is always in the manifest; it is a
            // visible page only when the writer wants a contents page.
            let navIndex = spine.count
            manifest.append(ManifestItem(id: "nav", href: "nav.xhtml", mediaType: "application/xhtml+xml", properties: "nav"))

            for chapter in book.chapters {
                addChapter(chapter)
            }

            let acknowledgements = settings.acknowledgements.trimmingCharacters(in: .whitespacesAndNewlines)
            if !acknowledgements.isEmpty {
                addMatter(id: "acknowledgements", title: "Acknowledgements", epubType: "acknowledgments", role: "doc-acknowledgments", text: acknowledgements)
            }
            let about = settings.aboutAuthor.trimmingCharacters(in: .whitespacesAndNewlines)
            if !about.isEmpty {
                addMatter(id: "about", title: "About the Author", epubType: "contributors", role: nil, text: about)
            }
            let alsoBy = settings.alsoByTitles
            if !alsoBy.isEmpty {
                let heading = book.author.isEmpty ? "Also Available" : "Also by \(book.author)"
                var body = "\t\t<section class=\"matter also-by\" epub:type=\"backmatter\">\n"
                body += "\t\t\t<h1 class=\"matter-title\">\(escape(heading))</h1>\n\t\t\t<ul>\n"
                body += alsoBy.map { "\t\t\t\t<li>\(escape($0))</li>\n" }.joined()
                body += "\t\t\t</ul>\n\t\t</section>"
                addPage(id: "also-by", name: "also_by", title: heading, kind: .backMatter, bodyClass: "backmatter", body: body)
            }

            files.append(.init(path: "OEBPS/nav.xhtml", data: Data(navXHTML.utf8), mediaType: "application/xhtml+xml"))
            if settings.includesTableOfContents {
                spine.insert(
                    .init(id: "nav", path: "OEBPS/nav.xhtml", title: "Contents", kind: .contents),
                    at: navIndex
                )
            }

            addFile("OEBPS/toc.ncx", ncxXML, mediaType: "application/x-dtbncx+xml")
            manifest.append(ManifestItem(id: "ncx", href: "toc.ncx", mediaType: "application/x-dtbncx+xml"))
            addFile("OEBPS/content.opf", packageXML(hasCover: coverData != nil), mediaType: "application/oebps-package+xml")

            return EpubPublication(files: files, spine: spine)
        }

        // MARK: - Pages

        private mutating func addFile(_ path: String, _ text: String, mediaType: String) {
            files.append(.init(path: path, data: Data(text.utf8), mediaType: mediaType))
        }

        private mutating func addPage(
            id: String,
            name: String,
            title: String,
            kind: EpubPublication.SpineItem.Kind,
            bodyClass: String,
            body: String
        ) {
            let href = "text/\(name).xhtml"
            addFile("OEBPS/\(href)", page(title: title, bodyClass: bodyClass, body: body), mediaType: "application/xhtml+xml")
            manifest.append(ManifestItem(id: id, href: href, mediaType: "application/xhtml+xml"))
            spine.append(.init(id: id, path: "OEBPS/\(href)", title: title, kind: kind))
        }

        private mutating func addMatter(id: String, title: String, epubType: String, role: String?, text: String) {
            let roleAttribute = role.map { " role=\"\($0)\"" } ?? ""
            let body = """
            \t\t<section class="matter" epub:type="\(epubType)"\(roleAttribute)>
            \t\t\t<h1 class="matter-title">\(escape(title))</h1>
            \(paragraphs(text, indent: 3))
            \t\t</section>
            """
            addPage(id: id, name: id, title: title, kind: .backMatter, bodyClass: "backmatter", body: body)
        }

        private mutating func addChapter(_ chapter: BookChapter) {
            let settings = book.settings
            let headingID = "chapter-\(chapter.number)"
            var body = "\t\t<section class=\"chapter\" epub:type=\"chapter\" role=\"doc-chapter\" aria-labelledby=\"\(headingID)\">\n"
            body += "\t\t\t<header class=\"chapter-heading\">\n"
            let label = book.chapterLabel(for: chapter)
            let title = book.chapterTitle(for: chapter)
            let labelClass = settings.chapterHeading == .numeralAndTitle ? "chapter-numeral" : "chapter-label"
            if let title {
                if let label {
                    body += "\t\t\t\t<p class=\"\(labelClass)\" aria-hidden=\"true\">\(escape(label))</p>\n"
                }
                let accessible = label.map { " aria-label=\"\(escape($0)): \(escape(title))\"" } ?? ""
                body += "\t\t\t\t<h1 id=\"\(headingID)\" class=\"chapter-title\"\(accessible)>\(escape(title))</h1>\n"
            } else if let label {
                body += "\t\t\t\t<h1 id=\"\(headingID)\" class=\"chapter-label\">\(escape(label))</h1>\n"
            }
            body += "\t\t\t</header>\n"

            let sceneBreak = sceneBreakMarkup(settings)
            for (index, scene) in chapter.scenes.enumerated() {
                if index > 0 {
                    body += sceneBreak
                }
                body += "\t\t\t<section class=\"scene\" id=\"scene-\(scene.id.uuidString.lowercased())\">\n"
                if settings.showsSceneTitles {
                    body += "\t\t\t\t<h2 class=\"scene-title\">\(escape(scene.title))</h2>\n"
                }
                let opening = index == 0 ? " opening" : ""
                body += "\t\t\t\t<div class=\"scene-body\(opening)\">\n"
                let xhtml = XHTMLSerializer.serialize(scene.content, headingOffset: 1)
                if !xhtml.isEmpty {
                    body += xhtml.split(separator: "\n", omittingEmptySubsequences: false)
                        .map { "\t\t\t\t\t\($0)" }.joined(separator: "\n") + "\n"
                }
                body += "\t\t\t\t</div>\n\t\t\t</section>\n"
            }
            body += "\t\t</section>"

            let name = String(format: "chapter_%02d", chapter.number)
            let href = "text/\(name).xhtml"
            addFile("OEBPS/\(href)", page(title: book.tocEntry(for: chapter), bodyClass: "bodymatter", body: body), mediaType: "application/xhtml+xml")
            manifest.append(ManifestItem(id: name, href: href, mediaType: "application/xhtml+xml"))
            spine.append(.init(id: name, path: "OEBPS/\(href)", title: book.tocEntry(for: chapter), kind: .chapter))
        }

        private func sceneBreakMarkup(_ settings: BookSettings) -> String {
            switch settings.sceneBreak {
            case .rule:
                "\t\t\t<hr class=\"scene-break rule\" />\n"
            case .blank:
                "\t\t\t<hr class=\"scene-break blank\" />\n"
            case .asterisks, .asterism, .fleuron, .custom:
                "\t\t\t<p class=\"scene-break\" role=\"separator\" aria-label=\"Scene break\">\(escape(settings.sceneBreak.glyph(custom: settings.customSceneBreak) ?? "* * *"))</p>\n"
            }
        }

        private func paragraphs(_ text: String, indent: Int) -> String {
            let tabs = String(repeating: "\t", count: indent)
            return text.split(whereSeparator: \.isNewline)
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty }
                .map { "\(tabs)<p>\(escape($0))</p>" }
                .joined(separator: "\n")
        }

        private var coverAltText: String {
            book.author.isEmpty ? "Cover of \(book.title)" : "Cover of \(book.title) by \(book.author)"
        }

        private func page(title: String, bodyClass: String, body: String) -> String {
            """
            <?xml version="1.0" encoding="UTF-8"?>
            <!DOCTYPE html>
            <html xmlns="http://www.w3.org/1999/xhtml" xmlns:epub="http://www.idpf.org/2007/ops" xml:lang="\(escape(book.language))" lang="\(escape(book.language))">
            \t<head>
            \t\t<meta charset="utf-8" />
            \t\t<title>\(escape(title))</title>
            \t\t<link rel="stylesheet" type="text/css" href="../styles/book.css" />
            \t</head>
            \t<body class="\(bodyClass)">
            \(body)
            \t</body>
            </html>
            """
        }

        // MARK: - Navigation

        private var tocEntries: [(title: String, href: String, children: [(title: String, href: String)])] {
            book.chapters.map { chapter in
                let href = String(format: "text/chapter_%02d.xhtml", chapter.number)
                let children = book.settings.showsSceneTitles
                    ? chapter.scenes.map { ($0.title, "\(href)#scene-\($0.id.uuidString.lowercased())") }
                    : []
                return (book.tocEntry(for: chapter), href, children)
            }
        }

        private var navXHTML: String {
            var list = ""
            for entry in tocEntries {
                list += "\t\t\t\t<li><a href=\"\(entry.href)\">\(escape(entry.title))</a>"
                if !entry.children.isEmpty {
                    list += "\n\t\t\t\t\t<ol>\n"
                    list += entry.children.map { "\t\t\t\t\t\t<li><a href=\"\($0.href)\">\(escape($0.title))</a></li>\n" }.joined()
                    list += "\t\t\t\t\t</ol>\n\t\t\t\t"
                }
                list += "</li>\n"
            }
            for item in spine where item.kind == .backMatter {
                let href = String(item.path.dropFirst("OEBPS/".count))
                list += "\t\t\t\t<li><a href=\"\(href)\">\(escape(item.title))</a></li>\n"
            }

            var landmarks = ""
            if let cover = spine.first(where: { $0.kind == .cover }) {
                landmarks += "\t\t\t\t<li><a epub:type=\"cover\" href=\"\(cover.path.dropFirst("OEBPS/".count))\">Cover</a></li>\n"
            }
            if book.settings.includesTableOfContents {
                landmarks += "\t\t\t\t<li><a epub:type=\"toc\" href=\"nav.xhtml\">Contents</a></li>\n"
            }
            if let first = tocEntries.first {
                landmarks += "\t\t\t\t<li><a epub:type=\"bodymatter\" href=\"\(first.href)\">Start of Content</a></li>\n"
            }

            return """
            <?xml version="1.0" encoding="UTF-8"?>
            <!DOCTYPE html>
            <html xmlns="http://www.w3.org/1999/xhtml" xmlns:epub="http://www.idpf.org/2007/ops" xml:lang="\(escape(book.language))" lang="\(escape(book.language))">
            \t<head>
            \t\t<meta charset="utf-8" />
            \t\t<title>Contents</title>
            \t\t<link rel="stylesheet" type="text/css" href="styles/book.css" />
            \t</head>
            \t<body class="frontmatter">
            \t\t<nav class="toc" epub:type="toc" role="doc-toc" id="toc">
            \t\t\t<h1 class="matter-title">Contents</h1>
            \t\t\t<ol>
            \(list)\t\t\t</ol>
            \t\t</nav>
            \t\t<nav epub:type="landmarks" hidden="hidden">
            \t\t\t<ol>
            \(landmarks)\t\t\t</ol>
            \t\t</nav>
            \t</body>
            </html>
            """
        }

        private var ncxXML: String {
            var points = ""
            var order = 1
            for entry in tocEntries {
                points += "\t\t<navPoint id=\"nav-\(order)\" playOrder=\"\(order)\">\n"
                points += "\t\t\t<navLabel><text>\(escape(entry.title))</text></navLabel>\n"
                points += "\t\t\t<content src=\"\(entry.href)\"/>\n"
                order += 1
                for child in entry.children {
                    points += "\t\t\t<navPoint id=\"nav-\(order)\" playOrder=\"\(order)\">\n"
                    points += "\t\t\t\t<navLabel><text>\(escape(child.title))</text></navLabel>\n"
                    points += "\t\t\t\t<content src=\"\(child.href)\"/>\n"
                    points += "\t\t\t</navPoint>\n"
                    order += 1
                }
                points += "\t\t</navPoint>\n"
            }
            let depth = book.settings.showsSceneTitles ? 2 : 1
            return """
            <?xml version="1.0" encoding="UTF-8"?>
            <ncx xmlns="http://www.daisy.org/z3986/2005/ncx/" version="2005-1" xml:lang="\(escape(book.language))">
            \t<head>
            \t\t<meta name="dtb:uid" content="\(book.identifier)"/>
            \t\t<meta name="dtb:depth" content="\(depth)"/>
            \t\t<meta name="dtb:totalPageCount" content="0"/>
            \t\t<meta name="dtb:maxPageNumber" content="0"/>
            \t</head>
            \t<docTitle><text>\(escape(book.title))</text></docTitle>
            \t<navMap>
            \(points)\t</navMap>
            </ncx>
            """
        }

        // MARK: - Package

        private var containerXML: String {
            """
            <?xml version="1.0" encoding="UTF-8"?>
            <container version="1.0" xmlns="urn:oasis:names:tc:opendocument:xmlns:container">
            \t<rootfiles>
            \t\t<rootfile full-path="OEBPS/content.opf" media-type="application/oebps-package+xml"/>
            \t</rootfiles>
            </container>
            """
        }

        private func packageXML(hasCover: Bool) -> String {
            let settings = book.settings
            var metadata: [String] = []
            metadata.append("<dc:identifier id=\"book-id\">\(book.identifier)</dc:identifier>")
            if let isbn = book.normalizedISBN {
                metadata.append("<dc:identifier id=\"isbn\">urn:isbn:\(escape(isbn))</dc:identifier>")
            }
            metadata.append("<dc:title id=\"title\">\(escape(book.title))</dc:title>")
            metadata.append("<meta refines=\"#title\" property=\"title-type\">main</meta>")
            if !book.subtitle.isEmpty {
                metadata.append("<dc:title id=\"subtitle\">\(escape(book.subtitle))</dc:title>")
                metadata.append("<meta refines=\"#subtitle\" property=\"title-type\">subtitle</meta>")
            }
            if !book.author.isEmpty {
                metadata.append("<dc:creator id=\"author\">\(escape(book.author))</dc:creator>")
                metadata.append("<meta refines=\"#author\" property=\"role\" scheme=\"marc:relators\">aut</meta>")
            }
            metadata.append("<dc:language>\(escape(book.language))</dc:language>")
            let publisher = settings.publisher.trimmingCharacters(in: .whitespaces)
            if !publisher.isEmpty {
                metadata.append("<dc:publisher>\(escape(publisher))</dc:publisher>")
            }
            metadata.append("<dc:rights>\(escape(book.copyrightLine))</dc:rights>")
            if !book.description.isEmpty {
                metadata.append("<dc:description>\(escape(book.description))</dc:description>")
            }
            for subject in settings.subjects where !subject.isEmpty {
                metadata.append("<dc:subject>\(escape(subject))</dc:subject>")
            }
            metadata.append("<dc:date>\(Self.dayFormatter.string(from: book.modified))</dc:date>")
            metadata.append("<meta property=\"dcterms:modified\">\(Self.timestampFormatter.string(from: book.modified))</meta>")

            let series = settings.series.trimmingCharacters(in: .whitespaces)
            if !series.isEmpty {
                metadata.append("<meta property=\"belongs-to-collection\" id=\"series\">\(escape(series))</meta>")
                metadata.append("<meta refines=\"#series\" property=\"collection-type\">series</meta>")
                metadata.append("<meta name=\"calibre:series\" content=\"\(escape(series))\"/>")
                let number = settings.seriesNumber.trimmingCharacters(in: .whitespaces)
                if !number.isEmpty {
                    metadata.append("<meta refines=\"#series\" property=\"group-position\">\(escape(number))</meta>")
                    metadata.append("<meta name=\"calibre:series_index\" content=\"\(escape(number))\"/>")
                }
            }
            if hasCover {
                metadata.append("<meta name=\"cover\" content=\"cover-image\"/>")
            }

            // Accessibility (EPUB Accessibility 1.1 / schema.org).
            metadata.append("<meta property=\"schema:accessMode\">textual</meta>")
            if hasCover {
                metadata.append("<meta property=\"schema:accessMode\">visual</meta>")
            }
            metadata.append("<meta property=\"schema:accessModeSufficient\">textual</meta>")
            for feature in ["structuralNavigation", "tableOfContents", "readingOrder"] {
                metadata.append("<meta property=\"schema:accessibilityFeature\">\(feature)</meta>")
            }
            if hasCover {
                metadata.append("<meta property=\"schema:accessibilityFeature\">alternativeText</meta>")
            }
            metadata.append("<meta property=\"schema:accessibilityHazard\">none</meta>")
            metadata.append("<meta property=\"schema:accessibilitySummary\">A text-only book with a navigable table of contents and headings for every chapter.</meta>")

            let manifestXML = manifest.map { item in
                let properties = item.properties.map { " properties=\"\($0)\"" } ?? ""
                return "\t\t<item id=\"\(item.id)\" href=\"\(item.href)\" media-type=\"\(item.mediaType)\"\(properties)/>"
            }.joined(separator: "\n")
            let spineXML = spine.map { "\t\t<itemref idref=\"\($0.id)\"/>" }.joined(separator: "\n")
            let guide = hasCover
                ? "\n\t<guide>\n\t\t<reference type=\"cover\" title=\"Cover\" href=\"text/cover.xhtml\"/>\n\t</guide>"
                : ""

            return """
            <?xml version="1.0" encoding="UTF-8"?>
            <package xmlns="http://www.idpf.org/2007/opf" version="3.0" unique-identifier="book-id" xml:lang="\(escape(book.language))" prefix="schema: http://schema.org/">
            \t<metadata xmlns:dc="http://purl.org/dc/elements/1.1/">
            \(metadata.map { "\t\t\($0)" }.joined(separator: "\n"))
            \t</metadata>
            \t<manifest>
            \(manifestXML)
            \t</manifest>
            \t<spine toc="ncx">
            \(spineXML)
            \t</spine>\(guide)
            </package>
            """
        }

        private static let dayFormatter: DateFormatter = {
            let formatter = DateFormatter()
            formatter.calendar = Calendar(identifier: .gregorian)
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.timeZone = TimeZone(identifier: "UTC")
            formatter.dateFormat = "yyyy-MM-dd"
            return formatter
        }()

        private static let timestampFormatter: DateFormatter = {
            let formatter = DateFormatter()
            formatter.calendar = Calendar(identifier: .gregorian)
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.timeZone = TimeZone(identifier: "UTC")
            formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
            return formatter
        }()
    }
}
