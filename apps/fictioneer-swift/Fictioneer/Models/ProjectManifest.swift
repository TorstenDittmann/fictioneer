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
                            updatedAt: scene.updatedAt
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
            epubMetadata: project.epubMetadata
        )
    }
}
