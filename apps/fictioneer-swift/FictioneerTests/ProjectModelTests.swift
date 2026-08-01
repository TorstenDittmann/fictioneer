import Foundation
import Testing
@testable import Fictioneer

struct ProjectModelTests {
    @Test func newProjectHasChapterAndScene() {
        let project = Project.makeNew(title: "My Novel")
        #expect(project.chapters.count == 1)
        #expect(project.chapters[0].scenes.count == 1)
        #expect(project.lastOpenedSceneID == project.chapters[0].scenes[0].id)
    }

    @Test func addChapterAndScene() {
        let project = Project.makeNew(title: "T")
        let chapter = project.addChapter()
        #expect(chapter.title == "Chapter 2")
        let scene = project.addScene(to: chapter)
        #expect(scene.title == "Scene 1")
        #expect(project.allScenes.count == 2)
    }

    @Test func deleteSceneClearsLastOpened() {
        let project = Project.makeNew(title: "T")
        let scene = project.chapters[0].scenes[0]
        project.deleteScene(scene)
        #expect(project.allScenes.isEmpty)
        #expect(project.lastOpenedSceneID == nil)
    }

    @Test func deleteChapterRemovesItsScenes() {
        let project = Project.makeNew(title: "T")
        let chapter = project.chapters[0]
        let sceneID = chapter.scenes[0].id
        project.deleteChapter(chapter)
        #expect(project.chapters.isEmpty)
        #expect(project.scene(withID: sceneID) == nil)
        #expect(project.lastOpenedSceneID == nil)
    }

    @Test func totalWordCountSumsScenes() {
        let project = Project.makeNew(title: "T")
        let scene = project.chapters[0].scenes[0]
        scene.updateContent(NSAttributedString(string: "one two three"))
        let chapter = project.addChapter()
        let second = project.addScene(to: chapter)
        second.updateContent(NSAttributedString(string: "four five"))
        #expect(project.totalWordCount == 5)
    }

    @Test func notesInsertNewestFirst() {
        let project = Project.makeNew(title: "T")
        let first = project.addNote(titled: "A")
        let second = project.addNote(titled: "B")
        #expect(project.notes.map(\.id) == [second.id, first.id])
        project.deleteNote(first)
        #expect(project.notes.count == 1)
    }
}
