import AppKit

nonisolated struct BookScene: @unchecked Sendable {
    let id: UUID
    let title: String
    /// An immutable copy with transient editor attributes stripped.
    let content: NSAttributedString
    let wordCount: Int
    let status: SceneStatus
}

nonisolated struct BookChapter: Sendable {
    let id: UUID
    /// 1-based position among the chapters in the book.
    let number: Int
    let title: String
    let scenes: [BookScene]

    var wordCount: Int { scenes.reduce(0) { $0 + $1.wordCount } }
}

/// A snapshot of everything one export needs: the included chapters and
/// scenes plus the book's settings. Built on the main actor, then rendered
/// anywhere — every export format and the preview read from it.
nonisolated struct BookDocument: Sendable {
    let projectID: UUID
    let title: String
    let description: String
    let settings: BookSettings
    let chapters: [BookChapter]
    /// The supplied cover image, when the settings ask for one.
    let coverImage: BookCoverImage?
    let modified: Date

    @MainActor
    static func make(from project: Project, now: Date = .now) -> BookDocument {
        let settings = project.book
        var chapters: [BookChapter] = []
        for chapter in project.chapters where settings.includes(chapter: chapter.id) {
            let scenes = chapter.scenes
                .filter { settings.includes(scene: $0.id) }
                .map { scene in
                    BookScene(
                        id: scene.id,
                        title: scene.title,
                        content: scene.content.strippingTransientAttributes().copy() as! NSAttributedString,
                        wordCount: scene.wordCount,
                        status: scene.status
                    )
                }
            guard !scenes.isEmpty else { continue }
            chapters.append(BookChapter(id: chapter.id, number: chapters.count + 1, title: chapter.title, scenes: scenes))
        }
        return BookDocument(
            projectID: project.id,
            title: project.title,
            description: project.details,
            settings: settings,
            chapters: chapters,
            coverImage: settings.cover == .image ? project.coverImage : nil,
            modified: now
        )
    }

    /// Stable across exports, so readers and stores recognize a new export
    /// as the same book.
    var identifier: String { "urn:uuid:\(projectID.uuidString.lowercased())" }

    var author: String { settings.author.trimmingCharacters(in: .whitespaces) }

    var subtitle: String { settings.subtitle.trimmingCharacters(in: .whitespaces) }

    var language: String {
        let trimmed = settings.language.trimmingCharacters(in: .whitespaces)
        return trimmed.isEmpty ? "en" : trimmed
    }

    var year: Int { Calendar(identifier: .gregorian).component(.year, from: modified) }

    var copyrightLine: String {
        let custom = settings.rights.trimmingCharacters(in: .whitespacesAndNewlines)
        if !custom.isEmpty { return custom }
        let holder = author.isEmpty ? "" : " \(author)"
        return "Copyright © \(year)\(holder). All rights reserved."
    }

    var wordCount: Int { chapters.reduce(0) { $0 + $1.wordCount } }

    var normalizedISBN: String? {
        let digits = ISBN.normalized(settings.isbn)
        return digits.isEmpty ? nil : digits
    }

    /// The small line above a chapter's title ("Chapter One"), if the
    /// heading style has one.
    func chapterLabel(for chapter: BookChapter) -> String? {
        switch settings.chapterHeading {
        case .labelAndTitle, .labelOnly: ChapterNumbering.label(for: chapter.number, language: language)
        case .numeralAndTitle: "\(chapter.number)"
        case .titleOnly: nil
        }
    }

    /// The chapter's own title, if the heading style shows it.
    func chapterTitle(for chapter: BookChapter) -> String? {
        switch settings.chapterHeading {
        case .labelOnly: nil
        default: chapter.title
        }
    }

    /// How a chapter reads in the table of contents.
    func tocEntry(for chapter: BookChapter) -> String {
        switch settings.chapterHeading {
        case .labelOnly:
            ChapterNumbering.label(for: chapter.number, language: language)
        case .labelAndTitle, .numeralAndTitle, .titleOnly:
            chapter.title
        }
    }
}

// MARK: - Chapter numbering

nonisolated enum ChapterNumbering {
    private static let chapterWords: [String: String] = [
        "en": "Chapter", "de": "Kapitel", "fr": "Chapitre", "es": "Capítulo", "it": "Capitolo",
        "pt": "Capítulo", "nl": "Hoofdstuk", "sv": "Kapitel", "da": "Kapitel", "nb": "Kapittel",
        "no": "Kapittel", "fi": "Luku", "pl": "Rozdział", "cs": "Kapitola",
    ]

    /// "Chapter One", in the book's language where known; otherwise
    /// "Chapter 1".
    static func label(for number: Int, language: String) -> String {
        let base = language.split(separator: "-").first.map { String($0).lowercased() } ?? "en"
        guard let word = chapterWords[base] else { return "Chapter \(number)" }
        let formatter = NumberFormatter()
        formatter.numberStyle = .spellOut
        formatter.locale = Locale(identifier: base)
        guard let spelled = formatter.string(from: NSNumber(value: number)) else { return "\(word) \(number)" }
        return "\(word) \(spelled.prefix(1).uppercased())\(spelled.dropFirst())"
    }
}

// MARK: - ISBN

nonisolated enum ISBN {
    static func normalized(_ raw: String) -> String {
        raw.uppercased().filter { $0.isNumber || $0 == "X" }
    }

    static func isValid(_ raw: String) -> Bool {
        let digits = normalized(raw)
        let values = digits.map { $0 == "X" ? 10 : Int(String($0)) ?? 0 }
        switch digits.count {
        case 10:
            guard !digits.dropLast().contains("X") else { return false }
            let sum = values.enumerated().reduce(0) { $0 + $1.element * (10 - $1.offset) }
            return sum % 11 == 0
        case 13:
            guard !digits.contains("X") else { return false }
            let sum = values.enumerated().reduce(0) { $0 + $1.element * ($1.offset.isMultiple(of: 2) ? 1 : 3) }
            return sum % 10 == 0
        default:
            return false
        }
    }
}

// MARK: - Readiness

/// Where in the export window an issue is fixed.
nonisolated enum ExportPane: String, CaseIterable, Identifiable, Sendable {
    case details, cover, design, matter, contents

    var id: String { rawValue }
    var title: String {
        switch self {
        case .details: "Details"
        case .cover: "Cover"
        case .design: "Design"
        case .matter: "Pages"
        case .contents: "Contents"
        }
    }
    var systemImage: String {
        switch self {
        case .details: "info.circle"
        case .cover: "photo.on.rectangle"
        case .design: "textformat"
        case .matter: "doc.plaintext"
        case .contents: "list.bullet.indent"
        }
    }
}

nonisolated struct ReadinessIssue: Identifiable, Equatable, Sendable {
    enum Severity: Int, Comparable, Sendable {
        /// Export is not possible.
        case blocking
        /// The book works, but something looks wrong.
        case warning
        /// Worth considering.
        case suggestion

        static func < (lhs: Severity, rhs: Severity) -> Bool { lhs.rawValue < rhs.rawValue }
    }

    let id: String
    let severity: Severity
    let message: String
    let pane: ExportPane
}

nonisolated enum BookReadiness {
    static func issues(for book: BookDocument, format: ExportFormat) -> [ReadinessIssue] {
        var issues: [ReadinessIssue] = []
        let settings = book.settings

        if book.chapters.isEmpty {
            issues.append(ReadinessIssue(
                id: "nothing", severity: .blocking,
                message: "Nothing to export — every chapter or scene is left out.",
                pane: .contents
            ))
        }

        let emptyChapters = book.chapters.filter { $0.wordCount == 0 }
        if emptyChapters.count == 1 {
            issues.append(ReadinessIssue(
                id: "empty-chapter", severity: .warning,
                message: "“\(emptyChapters[0].title)” has no text yet.",
                pane: .contents
            ))
        } else if emptyChapters.count > 1 {
            issues.append(ReadinessIssue(
                id: "empty-chapter", severity: .warning,
                message: "\(emptyChapters.count) chapters have no text yet.",
                pane: .contents
            ))
        }

        let unfinished = book.chapters.flatMap(\.scenes).filter { $0.status == .idea || $0.status == .draft }
        if !unfinished.isEmpty {
            let noun = unfinished.count == 1 ? "scene is" : "scenes are"
            issues.append(ReadinessIssue(
                id: "drafts", severity: .suggestion,
                message: "\(unfinished.count) included \(noun) still marked Idea or Draft.",
                pane: .contents
            ))
        }

        guard format == .epub else { return issues.sorted { $0.severity < $1.severity } }

        if book.author.isEmpty {
            issues.append(ReadinessIssue(
                id: "author", severity: .warning,
                message: "Add the author’s name — readers and stores show it everywhere.",
                pane: .details
            ))
        }
        let isbn = settings.isbn.trimmingCharacters(in: .whitespaces)
        if !isbn.isEmpty, !ISBN.isValid(isbn) {
            issues.append(ReadinessIssue(
                id: "isbn", severity: .warning,
                message: "The ISBN doesn’t check out — look for a typo.",
                pane: .details
            ))
        }
        if book.language.range(of: #"^[A-Za-z]{2,3}(-[A-Za-z0-9]{2,8})*$"#, options: .regularExpression) == nil {
            issues.append(ReadinessIssue(
                id: "language", severity: .warning,
                message: "Use a language code like “en” or “en-GB”.",
                pane: .details
            ))
        }
        if !settings.seriesNumber.trimmingCharacters(in: .whitespaces).isEmpty,
           settings.series.trimmingCharacters(in: .whitespaces).isEmpty {
            issues.append(ReadinessIssue(
                id: "series", severity: .suggestion,
                message: "The series number needs a series name.",
                pane: .details
            ))
        }
        switch settings.cover {
        case .none:
            issues.append(ReadinessIssue(
                id: "cover", severity: .suggestion,
                message: "Add a cover — libraries and stores show it first.",
                pane: .cover
            ))
        case .image where book.coverImage == nil:
            issues.append(ReadinessIssue(
                id: "cover", severity: .warning,
                message: "Choose a cover image, or switch to a designed cover.",
                pane: .cover
            ))
        default:
            break
        }
        return issues.sorted { $0.severity < $1.severity }
    }
}
