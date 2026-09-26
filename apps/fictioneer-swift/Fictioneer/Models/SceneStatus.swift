import Foundation

/// Where a scene stands in the writing process; shown as a dot in the
/// sidebar, on plot grid cards and in the scene's details line.
nonisolated enum SceneStatus: String, Codable, CaseIterable, Identifiable, Sendable {
    case idea
    case draft
    case revised
    case done

    var id: String { rawValue }

    var title: String {
        switch self {
        case .idea: "Idea"
        case .draft: "Draft"
        case .revised: "Revised"
        case .done: "Done"
        }
    }

    /// Scenes saved before statuses existed: written ones count as drafts.
    static func inferred(wordCount: Int) -> SceneStatus {
        wordCount > 0 ? .draft : .idea
    }
}
