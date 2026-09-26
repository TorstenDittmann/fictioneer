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
    /// Plot grid: columns and the beats in their cells.
    var plotLines: [PlotLine] = []
    var beats: [BeatKey: String] = [:]

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
        for scene in allScenes where scene.povNoteID == note.id {
            scene.povNoteID = nil
        }
        touch()
    }

    func touch() {
        updatedAt = .now
    }

    // MARK: - Plot grid

    func beat(scene: Scene, line: PlotLine) -> String {
        beats[BeatKey(sceneID: scene.id, plotLineID: line.id)] ?? ""
    }

    func setBeat(_ text: String, scene: Scene, line: PlotLine) {
        let key = BeatKey(sceneID: scene.id, plotLineID: line.id)
        beats[key] = text.isEmpty ? nil : text
        touch()
    }

    @discardableResult
    func addPlotLine(titled title: String? = nil) -> PlotLine {
        let used = Set(plotLines.map(\.tint))
        let tint = PlotLine.Tint.allCases.first { !used.contains($0) }
            ?? PlotLine.Tint.allCases[plotLines.count % PlotLine.Tint.allCases.count]
        let line = PlotLine(title: title ?? "Plot Line \(plotLines.count + 1)", tint: tint)
        plotLines.append(line)
        touch()
        return line
    }

    func deletePlotLine(_ line: PlotLine) {
        plotLines.removeAll { $0.id == line.id }
        beats = beats.filter { $0.key.plotLineID != line.id }
        touch()
    }

    // MARK: - Splitting and merging scenes

    /// Splits `scene` at a UTF-16 `offset`: the text after it moves into a new
    /// scene right after this one. A single newline at the split is dropped
    /// so neither scene starts or ends with an empty paragraph.
    @discardableResult
    func splitScene(_ scene: Scene, at offset: Int) -> Scene? {
        guard let chapter = chapter(containing: scene.id),
              let index = chapter.scenes.firstIndex(where: { $0.id == scene.id }) else { return nil }
        let content = scene.content
        let split = min(max(offset, 0), content.length)
        var head = content.attributedSubstring(from: NSRange(location: 0, length: split))
        var tail = content.attributedSubstring(from: NSRange(location: split, length: content.length - split))
        if tail.string.hasPrefix("\n") {
            tail = tail.attributedSubstring(from: NSRange(location: 1, length: tail.length - 1))
        } else if head.string.hasSuffix("\n") {
            head = head.attributedSubstring(from: NSRange(location: 0, length: head.length - 1))
        }
        scene.updateContent(head)
        let newScene = Scene(title: "\(scene.title) (continued)", content: tail, status: scene.status, povNoteID: scene.povNoteID)
        chapter.scenes.insert(newScene, at: index + 1)
        chapter.updatedAt = .now
        touch()
        return newScene
    }

    /// Appends `scene` to the scene before it in the same chapter and deletes
    /// it. Returns the merged-into scene.
    @discardableResult
    func mergeSceneIntoPrevious(_ scene: Scene) -> Scene? {
        guard let chapter = chapter(containing: scene.id),
              let index = chapter.scenes.firstIndex(where: { $0.id == scene.id }), index > 0 else { return nil }
        let previous = chapter.scenes[index - 1]
        let merged = NSMutableAttributedString(attributedString: previous.content)
        if merged.length > 0, scene.content.length > 0 {
            let attributes = merged.attributes(at: merged.length - 1, effectiveRange: nil)
            merged.append(NSAttributedString(string: "\n", attributes: attributes))
        }
        merged.append(scene.content)
        previous.updateContent(merged)
        for key in beats.keys where key.sceneID == scene.id {
            let target = BeatKey(sceneID: previous.id, plotLineID: key.plotLineID)
            if let text = beats[key], (beats[target] ?? "").isEmpty {
                beats[target] = text
            }
        }
        deleteScene(scene)
        return previous
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

    // Scene details (planning metadata).
    var synopsis: String
    var status: SceneStatus
    /// The note of the point-of-view character, if one is set.
    var povNoteID: UUID?
    var labels: [String]
    var targetWords: Int?

    init(
        id: UUID = UUID(),
        title: String,
        content: NSAttributedString = NSAttributedString(),
        createdAt: Date = .now,
        updatedAt: Date = .now,
        synopsis: String = "",
        status: SceneStatus? = nil,
        povNoteID: UUID? = nil,
        labels: [String] = [],
        targetWords: Int? = nil
    ) {
        self.id = id
        self.title = title
        self.content = content
        let counts = WordCounter.counts(for: content.string)
        self.wordCount = counts.words
        self.characterCount = counts.characters
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.synopsis = synopsis
        self.status = status ?? SceneStatus.inferred(wordCount: counts.words)
        self.povNoteID = povNoteID
        self.labels = labels
        self.targetWords = targetWords
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
