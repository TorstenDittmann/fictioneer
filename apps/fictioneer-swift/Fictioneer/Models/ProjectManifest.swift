import Foundation

nonisolated struct ProjectManifest: Codable {
    var formatVersion: Int
    var id: UUID
    var title: String
    var details: String
    var lastOpenedSceneID: UUID?
    var createdAt: Date
    var updatedAt: Date
    var chapters: [ChapterManifest]
    var notes: [NoteManifest]
    // Optional additions — formatVersion stays 1; old packages decode fine.
    var progressGoals: ProgressGoals?
    var dailyProgress: [DailyProgress]?
    var dailyWordSnapshots: [String: Int]?
    var lastSessionTime: Date?
    var epubMetadata: ProjectEpubMetadata?
    var quoteStyle: QuoteStyle?
    var plotLines: [PlotLine]?
    var beats: [PlotBeat]?
}

nonisolated struct ChapterManifest: Codable {
    var id: UUID
    var title: String
    var isExpanded: Bool
    var createdAt: Date
    var updatedAt: Date
    var scenes: [SceneManifest]
}

nonisolated struct SceneManifest: Codable {
    var id: UUID
    var title: String
    var wordCount: Int
    var characterCount: Int
    var createdAt: Date
    var updatedAt: Date
    // Scene details — optional so older packages decode unchanged.
    var synopsis: String?
    var status: SceneStatus?
    var povNoteID: UUID?
    var labels: [String]?
    var targetWords: Int?
}

nonisolated struct NoteManifest: Codable {
    var id: UUID
    var title: String
    var tags: [String]
    var createdAt: Date
    var updatedAt: Date
}

extension ProjectManifest {
    init(_ project: Project) {
        self.init(
            formatVersion: AppConfig.formatVersion,
            id: project.id,
            title: project.title,
            details: project.details,
            lastOpenedSceneID: project.lastOpenedSceneID,
            createdAt: project.createdAt,
            updatedAt: project.updatedAt,
            chapters: project.chapters.map { chapter in
                ChapterManifest(
                    id: chapter.id,
                    title: chapter.title,
                    isExpanded: chapter.isExpanded,
                    createdAt: chapter.createdAt,
                    updatedAt: chapter.updatedAt,
                    scenes: chapter.scenes.map { scene in
                        SceneManifest(
                            id: scene.id,
                            title: scene.title,
                            wordCount: scene.wordCount,
                            characterCount: scene.characterCount,
                            createdAt: scene.createdAt,
                            updatedAt: scene.updatedAt,
                            synopsis: scene.synopsis.isEmpty ? nil : scene.synopsis,
                            status: scene.status,
                            povNoteID: scene.povNoteID,
                            labels: scene.labels.isEmpty ? nil : scene.labels,
                            targetWords: scene.targetWords
                        )
                    }
                )
            },
            notes: project.notes.map { note in
                NoteManifest(
                    id: note.id,
                    title: note.title,
                    tags: note.tags,
                    createdAt: note.createdAt,
                    updatedAt: note.updatedAt
                )
            },
            progressGoals: project.progressGoals,
            dailyProgress: project.dailyProgress.isEmpty ? nil : project.dailyProgress,
            dailyWordSnapshots: project.dailyWordSnapshots.isEmpty ? nil : project.dailyWordSnapshots,
            lastSessionTime: project.lastSessionTime,
            epubMetadata: project.epubMetadata,
            quoteStyle: project.quoteStyle,
            plotLines: project.plotLines.isEmpty ? nil : project.plotLines,
            beats: Self.beats(of: project)
        )
    }

    /// Beats of existing scenes and plot lines only, in a stable order so
    /// unchanged grids don't rewrite the manifest differently.
    private static func beats(of project: Project) -> [PlotBeat]? {
        let sceneIDs = Set(project.allScenes.map(\.id))
        let lineIDs = Set(project.plotLines.map(\.id))
        let beats = project.beats
            .filter { sceneIDs.contains($0.key.sceneID) && lineIDs.contains($0.key.plotLineID) && !$0.value.isEmpty }
            .map { PlotBeat(sceneID: $0.key.sceneID, plotLineID: $0.key.plotLineID, text: $0.value) }
            .sorted { ($0.sceneID.uuidString, $0.plotLineID.uuidString) < ($1.sceneID.uuidString, $1.plotLineID.uuidString) }
        return beats.isEmpty ? nil : beats
    }
}
