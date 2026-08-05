import Foundation

enum EpubTemplate: String, CaseIterable, Identifiable, Codable {
    case genericNovel = "generic_novel"
    case modernCompact = "modern_compact"
    case classicBook = "classic_book"

    var id: String { rawValue }
    var label: String {
        switch self {
        case .genericNovel: "Generic Novel"
        case .modernCompact: "Modern Compact"
        case .classicBook: "Classic Book"
        }
    }
    var blurb: String {
        switch self {
        case .genericNovel: "A standard novel template with title page, chapters, and scenes"
        case .modernCompact: "Clean modern typography with compact spacing for fast reading"
        case .classicBook: "Traditional print-inspired layout with generous margins and elegant rhythm"
        }
    }

    var stylesheet: String {
        guard let url = Bundle.main.url(forResource: rawValue, withExtension: "css"),
              let css = try? String(contentsOf: url, encoding: .utf8)
        else { return "" }
        return css
    }
}

/// Builds the EPUB container following the Tauri app's structure: mimetype
/// first (STORED), then chapters, container.xml, content.opf, toc.ncx,
/// nav.xhtml, stylesheet, title page. All titles are XML-escaped.
enum EpubBuilder {
    static func export(project: Project, options: ExportOptions) -> Data {
        let escape = XHTMLSerializer.escape
        let metadata = resolvedMetadata(project: project, options: options)
        var entries: [ZipWriter.Entry] = [
            ZipWriter.Entry(path: "mimetype", text: "application/epub+zip"),
        ]

        struct Item {
            var id: String
            var href: String
            var title: String
        }
        var items: [Item] = []
        var chapterFiles: [(path: String, xhtml: String)] = []

        for (index, chapter) in project.chapters.enumerated() {
            let number = index + 1
            let filename = String(format: "chapter_%02d.xhtml", number)
            var body = ""
            if options.includeChapterTitles {
                body += "\t\t<h2 class=\"chapter-title\">\(escape(chapter.title))</h2>\n"
            }
            for (sceneIndex, scene) in chapter.scenes.enumerated() {
                if options.includeSceneTitles {
                    body += "\t\t<h3 class=\"scene-title\">\(escape(scene.title))</h3>\n"
                }
                let xhtml = XHTMLSerializer.serialize(scene.content)
                if !xhtml.isEmpty {
                    body += xhtml + "\n"
                }
                if options.includeWordCount {
                    body += "\t\t<p class=\"word-count\">Words: \(scene.wordCount)</p>\n"
                }
                if sceneIndex < chapter.scenes.count - 1 {
                    body += "\t\t<div class=\"scene-break\">* * *</div>\n"
                }
            }
            chapterFiles.append((filename, page(title: escape(chapter.title), body: body)))
            items.append(Item(id: "chapter_\(number)", href: filename, title: chapter.title))
        }

        for file in chapterFiles {
            entries.append(ZipWriter.Entry(path: "OEBPS/\(file.path)", text: file.xhtml))
        }

        entries.append(ZipWriter.Entry(path: "META-INF/container.xml", text: """
        <?xml version="1.0" encoding="UTF-8"?>
        <container version="1.0" xmlns="urn:oasis:names:tc:opendocument:xmlns:container">
        \t<rootfiles>
        \t\t<rootfile full-path="OEBPS/content.opf" media-type="application/oebps-package+xml"/>
        \t</rootfiles>
        </container>
        """))

        let identifier = "urn:uuid:\(UUID().uuidString.lowercased())"
        let date = ISO8601DateFormatter().string(from: .now)
        let dayOnly = String(date.prefix(10))

        var manifest = """
        \t\t<item id="ncx" href="toc.ncx" media-type="application/x-dtbncx+xml"/>
        \t\t<item id="nav" href="nav.xhtml" media-type="application/xhtml+xml" properties="nav"/>
        \t\t<item id="css" href="stylesheet.css" media-type="text/css"/>
        """
        var spine = ""
        if options.includeTitle {
            manifest += "\n\t\t<item id=\"title\" href=\"title.xhtml\" media-type=\"application/xhtml+xml\"/>"
            spine += "\n\t\t<itemref idref=\"title\"/>"
        }
        for item in items {
            manifest += "\n\t\t<item id=\"\(item.id)\" href=\"\(item.href)\" media-type=\"application/xhtml+xml\"/>"
            spine += "\n\t\t<itemref idref=\"\(item.id)\"/>"
        }

        var metadataXML = """
        \t\t<dc:identifier id="BookId">\(identifier)</dc:identifier>
        \t\t<dc:title>\(escape(project.title))</dc:title>
        \t\t<dc:creator>\(escape(metadata.author.isEmpty ? "Unknown Author" : metadata.author))</dc:creator>
        \t\t<dc:language>\(escape(metadata.language))</dc:language>
        """
        if !project.details.isEmpty {
            metadataXML += "\n\t\t<dc:description>\(escape(project.details))</dc:description>"
        }
        metadataXML += "\n\t\t<dc:publisher>\(escape(metadata.publisher.isEmpty ? "Fictioneer" : metadata.publisher))</dc:publisher>"
        metadataXML += "\n\t\t<dc:date>\(dayOnly)</dc:date>"
        for subject in metadata.subjects {
            metadataXML += "\n\t\t<dc:subject>\(escape(subject))</dc:subject>"
        }
        metadataXML += "\n\t\t<dc:rights>\(escape(metadata.rights.isEmpty ? "All rights reserved" : metadata.rights))</dc:rights>"
        metadataXML += "\n\t\t<meta property=\"dcterms:modified\">\(date)</meta>"

        entries.append(ZipWriter.Entry(path: "OEBPS/content.opf", text: """
        <?xml version="1.0" encoding="UTF-8"?>
        <package version="3.0" xmlns="http://www.idpf.org/2007/opf" unique-identifier="BookId">
        \t<metadata xmlns:dc="http://purl.org/dc/elements/1.1/">
        \(metadataXML)
        \t</metadata>
        \t<manifest>
        \(manifest)
        \t</manifest>
        \t<spine toc="ncx">\(spine)
        \t</spine>
        </package>
        """))

        var navPoints = ""
        var playOrder = 1
        var navList = ""
        if options.includeTitle {
            navPoints += navPoint(id: "title", title: escape(project.title), href: "title.xhtml", playOrder: playOrder)
            navList += "\t\t\t\t<li><a href=\"title.xhtml\">\(escape(project.title))</a></li>\n"
            playOrder += 1
        }
        for item in items {
            navPoints += navPoint(id: item.id, title: escape(item.title), href: item.href, playOrder: playOrder)
            navList += "\t\t\t\t<li><a href=\"\(item.href)\">\(escape(item.title))</a></li>\n"
            playOrder += 1
        }

        entries.append(ZipWriter.Entry(path: "OEBPS/toc.ncx", text: """
        <?xml version="1.0" encoding="UTF-8"?>
        <ncx xmlns="http://www.daisy.org/z3986/2005/ncx/" version="2005-1">
        \t<head>
        \t\t<meta name="dtb:uid" content="\(identifier)"/>
        \t\t<meta name="dtb:depth" content="2"/>
        \t\t<meta name="dtb:totalPageCount" content="0"/>
        \t\t<meta name="dtb:maxPageNumber" content="0"/>
        \t</head>
        \t<docTitle><text>\(escape(project.title))</text></docTitle>
        \t<navMap>
        \(navPoints)\t</navMap>
        </ncx>
        """))

        entries.append(ZipWriter.Entry(path: "OEBPS/nav.xhtml", text: """
        <?xml version="1.0" encoding="UTF-8"?>
        <html xmlns="http://www.w3.org/1999/xhtml" xmlns:epub="http://www.idpf.org/2007/ops">
        \t<head>
        \t\t<title>Navigation</title>
        \t\t<meta charset="utf-8" />
        \t\t<link rel="stylesheet" type="text/css" href="stylesheet.css" />
        \t</head>
        \t<body>
        \t\t<nav epub:type="toc" id="toc" class="toc">
        \t\t\t<h2>Table of Contents</h2>
        \t\t\t<ol>
        \(navList)\t\t\t</ol>
        \t\t</nav>
        \t</body>
        </html>
        """))

        entries.append(ZipWriter.Entry(path: "OEBPS/stylesheet.css", text: options.epubTemplate.stylesheet))

        if options.includeTitle {
            var titleBody = "\t\t<div class=\"title-page\">\n"
            titleBody += "\t\t\t<h1>\(escape(project.title))</h1>\n"
            titleBody += "\t\t\t<p class=\"author\">by \(escape(metadata.author.isEmpty ? "Unknown Author" : metadata.author))</p>\n"
            if !project.details.isEmpty {
                titleBody += "\t\t\t<div class=\"description\">\(escape(project.details))</div>\n"
            }
            titleBody += "\t\t</div>\n"
            entries.append(ZipWriter.Entry(
                path: "OEBPS/title.xhtml",
                text: page(title: escape(project.title), body: titleBody)
            ))
        }

        return ZipWriter.archive(entries)
    }

    private static func resolvedMetadata(project: Project, options: ExportOptions) -> ProjectEpubMetadata {
        var resolved = project.epubMetadata ?? ProjectEpubMetadata()
        let override = options.epubMetadata
        if !override.author.isEmpty { resolved.author = override.author }
        if !override.publisher.isEmpty { resolved.publisher = override.publisher }
        if !override.language.isEmpty { resolved.language = override.language }
        if !override.rights.isEmpty { resolved.rights = override.rights }
        if !override.subjects.isEmpty { resolved.subjects = override.subjects }
        if resolved.language.isEmpty { resolved.language = "en" }
        return resolved
    }

    private static func page(title: String, body: String) -> String {
        """
        <?xml version="1.0" encoding="UTF-8"?>
        <html xmlns="http://www.w3.org/1999/xhtml">
        \t<head>
        \t\t<title>\(title)</title>
        \t\t<meta charset="utf-8" />
        \t\t<link rel="stylesheet" type="text/css" href="stylesheet.css" />
        \t</head>
        \t<body>
        \(body)\t</body>
        </html>
        """
    }

    private static func navPoint(id: String, title: String, href: String, playOrder: Int) -> String {
        """
        \t\t<navPoint id="\(id)" playOrder="\(playOrder)">
        \t\t\t<navLabel><text>\(title)</text></navLabel>
        \t\t\t<content src="\(href)"/>
        \t\t</navPoint>\n
        """
    }
}
