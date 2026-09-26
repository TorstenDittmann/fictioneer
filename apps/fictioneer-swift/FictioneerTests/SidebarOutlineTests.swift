import Foundation
import Testing
@testable import Fictioneer

struct SidebarOutlineTests {
    /// Rows: 0 One, 1 1a, 2 1b, 3 Two, 4 2a, 5 Three (collapsed)
    private func makeProject() -> Project {
        Project(title: "T", chapters: [
            Chapter(title: "One", scenes: [Scene(title: "1a"), Scene(title: "1b")]),
            Chapter(title: "Two", scenes: [Scene(title: "2a")]),
            Chapter(title: "Three", scenes: [Scene(title: "3a")], isExpanded: false),
        ])
    }

    private func move(_ project: Project, from: Int, to: Int) -> Bool {
        SidebarOutline.move(
            in: project,
            rows: SidebarOutline.rows(for: project),
            fromOffsets: IndexSet(integer: from),
            toOffset: to
        )
    }

    private func titles(_ project: Project) -> [[String]] {
        project.chapters.map { [$0.title] + $0.scenes.map(\.title) }
    }

    /// Rows: 0 One, 1 1a, 2 Empty, 3 +Empty
    private func makeProjectWithEmptyChapter() -> Project {
        Project(title: "T", chapters: [
            Chapter(title: "One", scenes: [Scene(title: "1a")]),
            Chapter(title: "Empty", scenes: []),
        ])
    }

    @Test func rowsFlattenExpandedChaptersOnly() {
        let rows = SidebarOutline.rows(for: makeProject())
        #expect(rows.count == 6)
        #expect(rows.allSatisfy { $0.isMovable })
    }

    @Test func emptyExpandedChapterGetsPlaceholder() {
        let rows = SidebarOutline.rows(for: makeProjectWithEmptyChapter())
        #expect(rows.count == 4)
        #expect(!rows[3].isMovable)
    }

    @Test func sceneMovesDownWithinChapter() {
        let project = makeProject()
        #expect(move(project, from: 1, to: 3))
        #expect(titles(project)[0] == ["One", "1b", "1a"])
    }

    @Test func sceneMovesToTopOfChapter() {
        let project = makeProject()
        #expect(move(project, from: 2, to: 1))
        #expect(titles(project)[0] == ["One", "1b", "1a"])
    }

    @Test func sceneDroppedOnOwnSlotIsNoOp() {
        let project = makeProject()
        #expect(!move(project, from: 1, to: 1))
        #expect(!move(project, from: 1, to: 2))
    }

    @Test func sceneMovesIntoAnotherChapter() {
        let project = makeProject()
        #expect(move(project, from: 1, to: 4))
        #expect(titles(project)[0] == ["One", "1b"])
        #expect(titles(project)[1] == ["Two", "1a", "2a"])
    }

    @Test func sceneDroppedAboveNextChapterAppendsToPrevious() {
        let project = makeProject()
        #expect(move(project, from: 4, to: 3))
        #expect(titles(project)[0] == ["One", "1a", "1b", "2a"])
        #expect(titles(project)[1] == ["Two"])
    }

    @Test func sceneMovesIntoEmptyChapter() {
        let project = makeProjectWithEmptyChapter()
        #expect(move(project, from: 1, to: 4))
        #expect(titles(project) == [["One"], ["Empty", "1a"]])
    }

    @Test func sceneDroppedAboveFirstChapterIsIgnored() {
        let project = makeProject()
        #expect(!move(project, from: 1, to: 0))
        #expect(titles(project)[0] == ["One", "1a", "1b"])
    }

    @Test func chapterMovesDownPastAnother() {
        let project = makeProject()
        #expect(move(project, from: 0, to: 5))
        #expect(project.chapters.map(\.title) == ["Two", "One", "Three"])
        #expect(titles(project)[1] == ["One", "1a", "1b"])
    }

    @Test func chapterMovesToEnd() {
        let project = makeProject()
        #expect(move(project, from: 0, to: 6))
        #expect(project.chapters.map(\.title) == ["Two", "Three", "One"])
    }

    @Test func chapterMovesUpToTop() {
        let project = makeProject()
        #expect(move(project, from: 5, to: 0))
        #expect(project.chapters.map(\.title) == ["Three", "One", "Two"])
    }

    @Test func chapterDroppedInsideAnotherChapterLandsAfterIt() {
        let project = makeProject()
        #expect(move(project, from: 5, to: 2))
        #expect(project.chapters.map(\.title) == ["One", "Three", "Two"])
    }

    @Test func chapterDroppedOnOwnSlotIsNoOp() {
        let project = makeProject()
        #expect(!move(project, from: 3, to: 3))
        #expect(!move(project, from: 3, to: 4))
    }

    @Test func addScenePlaceholderCannotMove() {
        let project = makeProjectWithEmptyChapter()
        #expect(!move(project, from: 3, to: 0))
    }
}
