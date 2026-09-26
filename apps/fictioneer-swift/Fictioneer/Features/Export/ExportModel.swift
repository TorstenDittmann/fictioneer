import AppKit
import UniformTypeIdentifiers

/// State behind the export window: the options, the book snapshot, the
/// readiness list and the live preview, rebuilt shortly after each change.
@Observable
final class ExportModel {
    enum Outcome: Equatable {
        case exported(URL)
        case failed(String)
    }

    let session: ProjectSession
    let preview = BookPreviewController()

    var options: ExportOptions {
        didSet {
            guard options != oldValue else { return }
            settings.exportDefaults = options.defaults
            scheduleRebuild(immediately: options.format != oldValue.format)
        }
    }
    var pane: ExportPane = .details
    var outcome: Outcome?

    private(set) var book: BookDocument
    private(set) var issues: [ReadinessIssue] = []
    private(set) var coverData: Data?
    private(set) var isExporting = false

    @ObservationIgnored weak var window: NSWindow?
    @ObservationIgnored private let settings: AppSettings
    @ObservationIgnored private var rebuildTask: Task<Void, Never>?
    @ObservationIgnored private var coverCache: (input: CoverRenderer.Input, data: Data)?

    var project: Project { session.project }

    var canExport: Bool {
        !isExporting && !issues.contains { $0.severity == .blocking }
    }

    init(session: ProjectSession, settings: AppSettings) {
        self.session = session
        self.settings = settings
        self.options = settings.exportDefaults.map(ExportOptions.init(defaults:)) ?? ExportOptions()
        self.book = BookDocument.make(from: session.project)
        scheduleRebuild(immediately: true)
    }

    /// Book settings, title or cover changed in the window.
    func bookDidChange() {
        session.markDirty()
        outcome = nil
        scheduleRebuild()
    }

    func scheduleRebuild(immediately: Bool = false) {
        rebuildTask?.cancel()
        rebuildTask = Task { [weak self] in
            if !immediately {
                try? await Task.sleep(for: .milliseconds(250))
            }
            guard !Task.isCancelled else { return }
            await self?.rebuild()
        }
    }

    private func rebuild() async {
        let book = BookDocument.make(from: project)
        let options = options
        self.book = book
        issues = BookReadiness.issues(for: book, format: options.format)

        let cover = await cover(for: book)
        guard !Task.isCancelled else { return }
        coverData = cover?.data

        let publication: EpubPublication = await Task.detached(priority: .userInitiated) {
            options.format == .epub
                ? EpubBuilder.publication(for: book, coverData: cover)
                : ManuscriptPreview.publication(for: book, options: options)
        }.value
        guard !Task.isCancelled else { return }
        preview.update(publication)
    }

    private func cover(for book: BookDocument) async -> (data: Data, fileExtension: String)? {
        switch book.settings.cover {
        case .none:
            return nil
        case .image:
            return book.coverImage.map { ($0.data, $0.fileExtension) }
        case .generated:
            let input = CoverRenderer.input(for: book)
            if let coverCache, coverCache.input == input {
                return (coverCache.data, "jpg")
            }
            guard let data = await Task.detached(priority: .userInitiated, operation: {
                CoverRenderer.jpegData(for: input)
            }).value else { return nil }
            coverCache = (input, data)
            return (data, "jpg")
        }
    }

    // MARK: - Cover image

    func chooseCoverImage() {
        guard let window else { return }
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.jpeg, .png, .heic, .tiff]
        panel.allowsMultipleSelection = false
        panel.message = "Choose cover art — 1600 × 2560 pixels or larger works best."
        panel.beginSheetModal(for: window) { [weak self] response in
            guard response == .OK, let url = panel.url else { return }
            self?.setCoverImage(from: url)
        }
    }

    @discardableResult
    func setCoverImage(from url: URL) -> Bool {
        let scoped = url.startAccessingSecurityScopedResource()
        defer { if scoped { url.stopAccessingSecurityScopedResource() } }
        guard let data = try? Data(contentsOf: url), let image = Self.coverImage(from: data) else { return false }
        project.coverImage = image
        project.book.cover = .image
        return true
    }

    func removeCoverImage() {
        project.coverImage = nil
        if project.book.cover == .image {
            project.book.cover = .generated
        }
    }

    /// JPEG and PNG are stored as-is; anything else is converted to JPEG.
    static func coverImage(from data: Data) -> BookCoverImage? {
        if data.starts(with: [0xFF, 0xD8, 0xFF]) {
            return BookCoverImage(data: data, fileExtension: "jpg")
        }
        if data.starts(with: [0x89, 0x50, 0x4E, 0x47]) {
            return BookCoverImage(data: data, fileExtension: "png")
        }
        guard let rep = NSBitmapImageRep(data: data),
              let jpeg = rep.representation(using: .jpeg, properties: [.compressionFactor: 0.9])
        else { return nil }
        return BookCoverImage(data: jpeg, fileExtension: "jpg")
    }

    // MARK: - Export

    func export() {
        guard canExport, let window else { return }
        session.saveNow()
        let panel = NSSavePanel()
        panel.title = "Export \(options.format.shortLabel)"
        panel.nameFieldStringValue = ExportService.suggestedFilename(for: project.title, format: options.format)
        panel.allowedContentTypes = [options.format.contentType]
        panel.canCreateDirectories = true
        panel.beginSheetModal(for: window) { [weak self] response in
            guard response == .OK, let url = panel.url else { return }
            Task { await self?.write(to: url) }
        }
    }

    private func write(to url: URL) async {
        isExporting = true
        defer { isExporting = false }
        let book = BookDocument.make(from: project)
        do {
            let data = try await ExportService.render(book, options: options)
            try ExportService.write(data, to: url)
            ExportService.rememberDestination(url, projectID: project.id, format: options.format)
            outcome = .exported(url)
        } catch {
            outcome = .failed("The book couldn’t be written: \(error.localizedDescription)")
        }
    }

    func revealExport() {
        guard case .exported(let url) = outcome else { return }
        NSWorkspace.shared.activateFileViewerSelecting([url])
    }

    /// Apple Books imports the file into its library.
    func openExportInBooks() {
        guard case .exported(let url) = outcome else { return }
        let configuration = NSWorkspace.OpenConfiguration()
        if let books = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.apple.iBooksX") {
            NSWorkspace.shared.open([url], withApplicationAt: books, configuration: configuration)
        } else {
            NSWorkspace.shared.open(url)
        }
    }
}

/// A one-page stand-in for RTF and plain-text exports, served through the
/// same preview as EPUB.
nonisolated enum ManuscriptPreview {
    static func publication(for book: BookDocument, options: ExportOptions) -> EpubPublication {
        let escape = XHTMLSerializer.escape
        let isPlain = options.format == .txt
        var body = ""
        if isPlain {
            body = "<pre>\(escape(TextExporter.export(book, options: options)))</pre>"
        } else {
            if options.includeTitle {
                body += "<h1 class=\"title\">\(escape(book.title))</h1>\n"
                if !book.author.isEmpty {
                    body += "<p class=\"byline\">by \(escape(book.author))</p>\n"
                }
            }
            for chapter in book.chapters {
                if options.includeChapterTitles {
                    body += "<h2>\(escape(chapter.title))</h2>\n"
                }
                for scene in chapter.scenes {
                    if options.includeSceneTitles {
                        body += "<h3>\(escape(scene.title))</h3>\n"
                    }
                    body += XHTMLSerializer.serialize(scene.content, headingOffset: 2) + "\n"
                    if options.includeWordCount {
                        body += "<p class=\"count\">Words: \(scene.wordCount)</p>\n"
                    }
                }
            }
        }
        let css = isPlain
            ? "pre { font: 13px/1.5 Menlo, monospace; white-space: pre-wrap; margin: 0; }"
            : """
            body { font-family: "Times New Roman", Times, serif; font-size: 12pt; line-height: 1.5; }
            h1.title { text-align: center; font-size: 18pt; } .byline { text-align: center; }
            h2 { font-size: 16pt; } h3 { font-size: 14pt; } h4, h5 { font-size: 12pt; }
            p { margin: 0 0 8pt 0; } .count { font-size: 10pt; font-style: italic; }
            """
        let page = """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE html>
        <html xmlns="http://www.w3.org/1999/xhtml">
        <head><meta charset="utf-8" /><title>\(escape(book.title))</title><style>\(css)</style></head>
        <body>
        \(body)
        </body>
        </html>
        """
        let path = "preview/manuscript.xhtml"
        return EpubPublication(
            files: [.init(path: path, data: Data(page.utf8), mediaType: "application/xhtml+xml")],
            spine: [.init(id: "manuscript", path: path, title: book.title, kind: .chapter)]
        )
    }
}
