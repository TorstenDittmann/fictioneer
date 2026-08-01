import Foundation
import Testing
@testable import Fictioneer

struct ReorderingTests {
    private func makeProject() -> Project {
        let project = Project(title: "T", chapters: [
            Chapter(title: "One", scenes: [Scene(title: "1a"), Scene(title: "1b"), Scene(title: "1c")]),
            Chapter(title: "Two", scenes: [Scene(title: "2a")]),
        ])
        return project
    }

    @Test func moveScenesWithinChapter() {
        let project = makeProject()
        let chapter = project.chapters[0]
        chapter.moveScenes(fromOffsets: IndexSet(integer: 0), toOffset: 3)
        #expect(chapter.scenes.map(\.title) == ["1b", "1c", "1a"])
    }

    @Test func moveChapters() {
        let project = makeProject()
        project.moveChapters(fromOffsets: IndexSet(integer: 1), toOffset: 0)
        #expect(project.chapters.map(\.title) == ["Two", "One"])
    }

    @Test func moveSceneAcrossChaptersPreservesIdentity() {
        let project = makeProject()
        let scene = project.chapters[0].scenes[1]
        project.lastOpenedSceneID = scene.id
        project.moveScene(scene, to: project.chapters[1])
        #expect(project.chapters[0].scenes.map(\.title) == ["1a", "1c"])
        #expect(project.chapters[1].scenes.map(\.title) == ["2a", "1b"])
        #expect(project.lastOpenedSceneID == scene.id)
        #expect(project.chapter(containing: scene.id)?.title == "Two")
    }

    @Test func moveSceneToOwnChapterIsNoOp() {
        let project = makeProject()
        let scene = project.chapters[0].scenes[0]
        project.moveScene(scene, to: project.chapters[0])
        #expect(project.chapters[0].scenes.count == 3)
    }
}
