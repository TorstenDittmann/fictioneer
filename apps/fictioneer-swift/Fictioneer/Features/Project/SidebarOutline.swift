import Foundation

/// The manuscript section of the sidebar as flat rows. A flat list (instead
/// of DisclosureGroups) keeps the sidebar out of outline mode, which reserves
/// a disclosure column on *every* row and pushes everything right.
enum SidebarRow: Identifiable {
    case chapter(Chapter)
    case scene(Scene, in: Chapter)
    case addScene(Chapter)

    var id: String {
        switch self {
        case .chapter(let chapter): "chapter-\(chapter.id)"
        case .scene(let scene, _): "scene-\(scene.id)"
        case .addScene(let chapter): "add-scene-\(chapter.id)"
        }
    }

    var isMovable: Bool {
        if case .addScene = self { return false }
        return true
    }
}

enum SidebarOutline {
    static func rows(for project: Project) -> [SidebarRow] {
        project.chapters.flatMap { chapter -> [SidebarRow] in
            guard chapter.isExpanded else { return [.chapter(chapter)] }
            // Empty chapters get an Add Scene placeholder; populated ones add
            // scenes from the chapter row's hover button instead.
            guard !chapter.scenes.isEmpty else { return [.chapter(chapter), .addScene(chapter)] }
            return [.chapter(chapter)] + chapter.scenes.map { .scene($0, in: chapter) }
        }
    }

    /// Applies a List `onMove` on the flat rows to the model. `destination` is
    /// an offset into `rows` *before* the move, as SwiftUI reports it.
    /// Chapters move as a whole (with their scenes); scenes land in whichever
    /// chapter the drop point falls into. Returns false when nothing changed.
    @discardableResult
    static func move(
        in project: Project,
        rows: [SidebarRow],
        fromOffsets source: IndexSet,
        toOffset destination: Int
    ) -> Bool {
        guard source.count == 1, let from = source.first, rows.indices.contains(from) else { return false }
        var remaining = rows
        let moved = remaining.remove(at: from)
        let insertion = destination > from ? destination - 1 : destination

        switch moved {
        case .chapter(let chapter):
            let target = remaining[..<insertion].filter {
                if case .chapter = $0 { return true }
                return false
            }.count
            guard let current = project.chapters.firstIndex(where: { $0.id == chapter.id }),
                  current != target else { return false }
            project.moveChapters(
                fromOffsets: IndexSet(integer: current),
                toOffset: target > current ? target + 1 : target
            )
            return true

        case .scene(let scene, let sourceChapter):
            // The row above the drop point decides the target: a chapter
            // header means "first scene", a scene means "right after it", and
            // an empty chapter's Add Scene placeholder means "into it".
            guard insertion > 0 else { return false }
            let targetChapter: Chapter
            let targetIndex: Int
            switch remaining[insertion - 1] {
            case .chapter(let chapter):
                targetChapter = chapter
                targetIndex = 0
            case .scene(let above, let chapter):
                targetChapter = chapter
                let siblings = chapter.scenes.filter { $0.id != scene.id }
                let aboveIndex = siblings.firstIndex { $0.id == above.id } ?? -1
                targetIndex = aboveIndex + 1
            case .addScene(let chapter):
                targetChapter = chapter
                targetIndex = chapter.scenes.filter { $0.id != scene.id }.count
            }
            return project.moveScene(scene, from: sourceChapter, to: targetChapter, at: targetIndex)

        case .addScene:
            return false
        }
    }
}
