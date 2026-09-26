import Foundation

/// How a book is published: its details, front and back matter, design,
/// cover and which parts of the manuscript it contains. Stored per project
/// and edited in the export window.
///
/// Decoding is lenient field by field, so settings written by a newer build
/// (or an unknown enum value) never wipe the rest.
nonisolated struct BookSettings: Codable, Sendable, Equatable {
    // Details
    var subtitle = ""
    var author = ""
    var publisher = ""
    var language = "en"
    /// Custom copyright line; empty means one is generated from the author.
    var rights = ""
    var subjects: [String] = []
    var isbn = ""
    var series = ""
    /// Free-form so "2" and "2.5" both work.
    var seriesNumber = ""

    // Front and back matter
    var includesTitlePage = true
    var includesCopyrightPage = true
    var includesTableOfContents = true
    var dedication = ""
    var epigraph = ""
    var epigraphAttribution = ""
    var acknowledgements = ""
    var aboutAuthor = ""
    /// Other titles by the author, one per line.
    var alsoBy = ""

    // Design
    var template: EpubTemplate = .genericNovel
    var chapterHeading: ChapterHeadingStyle = .labelAndTitle
    var sceneBreak: SceneBreakStyle = .asterisks
    var customSceneBreak = ""
    var chapterOpening: ChapterOpeningStyle = .smallCaps
    var bodyFont: BookFont = .template
    var showsSceneTitles = false

    // Cover
    var cover: CoverSource = .generated
    var coverDesign: CoverDesign = .classic
    var coverPalette: CoverPalette = .ink

    // Contents
    var excludedChapterIDs: Set<UUID> = []
    var excludedSceneIDs: Set<UUID> = []

    init() {}

    /// Carries over the metadata of projects saved before book settings.
    init(legacy: ProjectEpubMetadata) {
        author = legacy.author
        publisher = legacy.publisher
        language = legacy.language.isEmpty ? "en" : legacy.language
        rights = legacy.rights
        subjects = legacy.subjects
    }

    var alsoByTitles: [String] {
        alsoBy.split(whereSeparator: \.isNewline)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }

    func includes(chapter id: UUID) -> Bool { !excludedChapterIDs.contains(id) }
    func includes(scene id: UUID) -> Bool { !excludedSceneIDs.contains(id) }

    private enum CodingKeys: String, CodingKey {
        case subtitle, author, publisher, language, rights, subjects, isbn, series, seriesNumber
        case includesTitlePage, includesCopyrightPage, includesTableOfContents
        case dedication, epigraph, epigraphAttribution, acknowledgements, aboutAuthor, alsoBy
        case template, chapterHeading, sceneBreak, customSceneBreak, chapterOpening, bodyFont, showsSceneTitles
        case cover, coverDesign, coverPalette
        case excludedChapterIDs, excludedSceneIDs
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        func value<T: Decodable>(_ key: CodingKeys, _ fallback: T) -> T {
            (try? c.decodeIfPresent(T.self, forKey: key)) ?? fallback
        }
        let defaults = BookSettings()
        subtitle = value(.subtitle, defaults.subtitle)
        author = value(.author, defaults.author)
        publisher = value(.publisher, defaults.publisher)
        language = value(.language, defaults.language)
        rights = value(.rights, defaults.rights)
        subjects = value(.subjects, defaults.subjects)
        isbn = value(.isbn, defaults.isbn)
        series = value(.series, defaults.series)
        seriesNumber = value(.seriesNumber, defaults.seriesNumber)
        includesTitlePage = value(.includesTitlePage, defaults.includesTitlePage)
        includesCopyrightPage = value(.includesCopyrightPage, defaults.includesCopyrightPage)
        includesTableOfContents = value(.includesTableOfContents, defaults.includesTableOfContents)
        dedication = value(.dedication, defaults.dedication)
        epigraph = value(.epigraph, defaults.epigraph)
        epigraphAttribution = value(.epigraphAttribution, defaults.epigraphAttribution)
        acknowledgements = value(.acknowledgements, defaults.acknowledgements)
        aboutAuthor = value(.aboutAuthor, defaults.aboutAuthor)
        alsoBy = value(.alsoBy, defaults.alsoBy)
        template = value(.template, defaults.template)
        chapterHeading = value(.chapterHeading, defaults.chapterHeading)
        sceneBreak = value(.sceneBreak, defaults.sceneBreak)
        customSceneBreak = value(.customSceneBreak, defaults.customSceneBreak)
        chapterOpening = value(.chapterOpening, defaults.chapterOpening)
        bodyFont = value(.bodyFont, defaults.bodyFont)
        showsSceneTitles = value(.showsSceneTitles, defaults.showsSceneTitles)
        cover = value(.cover, defaults.cover)
        coverDesign = value(.coverDesign, defaults.coverDesign)
        coverPalette = value(.coverPalette, defaults.coverPalette)
        excludedChapterIDs = value(.excludedChapterIDs, defaults.excludedChapterIDs)
        excludedSceneIDs = value(.excludedSceneIDs, defaults.excludedSceneIDs)
    }
}

nonisolated enum ChapterHeadingStyle: String, Codable, CaseIterable, Identifiable, Sendable {
    /// "Chapter One" above the chapter's title.
    case labelAndTitle
    /// A large numeral above the chapter's title.
    case numeralAndTitle
    /// "Chapter One" only.
    case labelOnly
    /// The chapter's title only.
    case titleOnly

    var id: String { rawValue }
    var label: String {
        switch self {
        case .labelAndTitle: "Chapter One + Title"
        case .numeralAndTitle: "1 + Title"
        case .labelOnly: "Chapter One"
        case .titleOnly: "Title Only"
        }
    }
}

nonisolated enum SceneBreakStyle: String, Codable, CaseIterable, Identifiable, Sendable {
    case asterisks
    case asterism
    case fleuron
    case rule
    case blank
    case custom

    var id: String { rawValue }
    var label: String {
        switch self {
        case .asterisks: "* * *"
        case .asterism: "⁂"
        case .fleuron: "❦"
        case .rule: "Short Rule"
        case .blank: "Blank Line"
        case .custom: "Custom"
        }
    }

    /// The glyphs shown between scenes; nil for the rule and blank styles,
    /// which are drawn by CSS.
    func glyph(custom: String) -> String? {
        switch self {
        case .asterisks: "* * *"
        case .asterism: "⁂"
        case .fleuron: "❦"
        case .rule, .blank: nil
        case .custom:
            custom.trimmingCharacters(in: .whitespaces).isEmpty
                ? "* * *"
                : custom.trimmingCharacters(in: .whitespaces)
        }
    }
}

nonisolated enum ChapterOpeningStyle: String, Codable, CaseIterable, Identifiable, Sendable {
    case plain
    case smallCaps
    case dropCap

    var id: String { rawValue }
    var label: String {
        switch self {
        case .plain: "Plain"
        case .smallCaps: "Small Caps"
        case .dropCap: "Drop Cap"
        }
    }
}

nonisolated enum BookFont: String, Codable, CaseIterable, Identifiable, Sendable {
    /// The template's own font stack.
    case template
    /// Quattrocento, embedded in the book.
    case quattrocento
    /// No font set: readers use their own default.
    case reader

    var id: String { rawValue }
    var label: String {
        switch self {
        case .template: "Template Default"
        case .quattrocento: "Quattrocento (embedded)"
        case .reader: "Reader’s Choice"
        }
    }
}

nonisolated enum CoverSource: String, Codable, CaseIterable, Identifiable, Sendable {
    case none
    case generated
    case image

    var id: String { rawValue }
    var label: String {
        switch self {
        case .none: "None"
        case .generated: "Designed"
        case .image: "Image"
        }
    }
}

nonisolated enum CoverDesign: String, Codable, CaseIterable, Identifiable, Sendable {
    case classic
    case modern
    case minimal

    var id: String { rawValue }
    var label: String { rawValue.capitalized }
}

nonisolated enum CoverPalette: String, Codable, CaseIterable, Identifiable, Sendable {
    case ink
    case paper
    case forest
    case oxblood
    case dusk

    var id: String { rawValue }
    var label: String { rawValue.capitalized }
}

/// A cover image the writer supplied, stored inside the project package.
nonisolated struct BookCoverImage: Sendable, Equatable {
    var data: Data
    /// "jpg" or "png".
    var fileExtension: String

    var mediaType: String {
        fileExtension == "png" ? "image/png" : "image/jpeg"
    }
}
