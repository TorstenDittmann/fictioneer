import AppKit
import Foundation

@Observable
final class Project {
    let id: UUID
    var title: String
    var details: String
    var chapters: [Chapter]
    var notes: [Note]
    var lastOpenedSceneID: UUID?
    let createdAt: Date
    var updatedAt: Date

    var progressGoals: ProgressGoals?
    var dailyProgress: [DailyProgress] = []
    var dailyWordSnapshots: [String: Int] = [:]
    var lastSessionTime: Date?
    var epubMetadata: ProjectEpubMetadata?
    /// nil until the writer picks one; `effectiveQuoteStyle` then follows
    /// their language.
    var quoteStyle: QuoteStyle?

    var effectiveQuoteStyle: QuoteStyle {
        quoteStyle ?? QuoteStyle.defaultStyle()
    }

    init(
        id: UUID = UUID(),
        title: String,
        details: String = "",
        chapters: [Chapter] = [],
        notes: [Note] = [],
        lastOpenedSceneID: UUID? = nil,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.title = title
        self.details = details
        self.chapters = chapters
        self.notes = notes
        self.lastOpenedSceneID = lastOpenedSceneID
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    static func makeNew(title: String, details: String = "") -> Project {
        let scene = Scene(title: "Scene 1")
        let chapter = Chapter(title: "Chapter 1", scenes: [scene])
        let project = Project(title: title, details: details, chapters: [chapter])
        project.lastOpenedSceneID = scene.id
        return project
    }

    var allScenes: [Scene] {
        chapters.flatMap(\.scenes)
    }

    var totalWordCount: Int {
        allScenes.reduce(0) { $0 + $1.wordCount }
    }

    func scene(withID id: UUID) -> Scene? {
        allScenes.first { $0.id == id }
    }

    func note(withID id: UUID) -> Note? {
        notes.first { $0.id == id }
    }

    func chapter(containing sceneID: UUID) -> Chapter? {
        chapters.first { $0.scenes.contains { $0.id == sceneID } }
    }

    @discardableResult
    func addChapter(titled title: String? = nil) -> Chapter {
        let chapter = Chapter(title: title ?? "Chapter \(chapters.count + 1)")
        chapters.append(chapter)
        touch()
        return chapter
    }

    @discardableResult
    func addScene(to chapter: Chapter, titled title: String? = nil) -> Scene {
        let scene = Scene(title: title ?? "Scene \(chapter.scenes.count + 1)")
        chapter.scenes.append(scene)
        chapter.updatedAt = .now
        touch()
        return scene
    }

    func deleteChapter(_ chapter: Chapter) {
        chapters.removeAll { $0.id == chapter.id }
        if let last = lastOpenedSceneID, chapter.scenes.contains(where: { $0.id == last }) {
            lastOpenedSceneID = nil
        }
        touch()
    }

    func deleteScene(_ scene: Scene) {
        for chapter in chapters {
            chapter.scenes.removeAll { $0.id == scene.id }
        }
        if lastOpenedSceneID == scene.id {
            lastOpenedSceneID = nil
        }
        touch()
    }

    @discardableResult
    func addNote(titled title: String = "Untitled Note") -> Note {
        let note = Note(title: title)
        notes.insert(note, at: 0)
        touch()
        return note
    }

    func deleteNote(_ note: Note) {
        notes.removeAll { $0.id == note.id }
        touch()
    }

    func touch() {
        updatedAt = .now
    }

    // MARK: - Reordering

    func moveChapters(fromOffsets source: IndexSet, toOffset destination: Int) {
        chapters.move(fromOffsets: source, toOffset: destination)
        touch()
    }

    func moveScene(_ scene: Scene, to targetChapter: Chapter) {
        guard let sourceChapter = chapter(containing: scene.id), sourceChapter.id != targetChapter.id else { return }
        sourceChapter.scenes.removeAll { $0.id == scene.id }
        targetChapter.scenes.append(scene)
        sourceChapter.updatedAt = .now
        targetChapter.updatedAt = .now
        touch()
    }

    /// Moves a scene to `index` in `targetChapter` (which may be its own
    /// chapter); `index` counts the target's scenes without the moved one.
    @discardableResult
    func moveScene(_ scene: Scene, from sourceChapter: Chapter, to targetChapter: Chapter, at index: Int) -> Bool {
        guard let current = sourceChapter.scenes.firstIndex(where: { $0.id == scene.id }) else { return false }
        if sourceChapter.id == targetChapter.id, current == index { return false }
        sourceChapter.scenes.remove(at: current)
        targetChapter.scenes.insert(scene, at: min(max(index, 0), targetChapter.scenes.count))
        sourceChapter.updatedAt = .now
        targetChapter.updatedAt = .now
        touch()
        return true
    }
}

@Observable
final class Chapter {
    let id: UUID
    var title: String
    var scenes: [Scene]
    var isExpanded: Bool
    let createdAt: Date
    var updatedAt: Date

    func moveScenes(fromOffsets source: IndexSet, toOffset destination: Int) {
        scenes.move(fromOffsets: source, toOffset: destination)
        updatedAt = .now
    }

    init(
        id: UUID = UUID(),
        title: String,
        scenes: [Scene] = [],
        isExpanded: Bool = true,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.title = title
        self.scenes = scenes
        self.isExpanded = isExpanded
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

@Observable
final class Scene {
    let id: UUID
    var title: String
    var content: NSAttributedString
    var wordCount: Int
    var characterCount: Int
    let createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        title: String,
        content: NSAttributedString = NSAttributedString(),
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.title = title
        self.content = content
        let counts = WordCounter.counts(for: content.string)
        self.wordCount = counts.words
        self.characterCount = counts.characters
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    func updateContent(_ content: NSAttributedString) {
        self.content = content
        let counts = WordCounter.counts(for: content.string)
        wordCount = counts.words
        characterCount = counts.characters
        updatedAt = .now
    }
}

@Observable
final class Note {
    let id: UUID
    var title: String
    var body: NSAttributedString
    var tags: [String]
    let createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        title: String,
        body: NSAttributedString = NSAttributedString(),
        tags: [String] = [],
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.title = title
        self.body = body
        self.tags = tags
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
