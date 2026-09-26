import Foundation
import Testing
@testable import Fictioneer

struct SidebarItemMappingTests {
    private func makeSession() -> ProjectSession {
        ProjectSession(project: Project.makeNew(title: "T"))
    }

    @Test func freshSessionSelectsFirstScene() {
        let session = makeSession()
        let sceneID = session.project.chapters[0].scenes[0].id
        #expect(session.selectedItem == .scene(sceneID))
    }

    @Test func overviewClearsBothSelections() {
        let session = makeSession()
        session.selectedItem = .overview
        #expect(session.selectedSceneID == nil)
        #expect(session.selectedNoteID == nil)
        #expect(session.selectedItem == .overview)
    }

    @Test func selectingSceneClearsNote() {
        let session = makeSession()
        let sceneID = session.project.chapters[0].scenes[0].id
        let noteID = UUID()
        session.selectedNoteID = noteID
        session.selectedItem = .scene(sceneID)
        #expect(session.selectedSceneID == sceneID)
        #expect(session.selectedNoteID == nil)
    }

    @Test func selectingNotePreservesSceneSelection() {
        let session = makeSession()
        let sceneID = session.project.chapters[0].scenes[0].id
        session.selectedItem = .scene(sceneID)
        let noteID = UUID()
        session.selectedItem = .note(noteID)
        #expect(session.selectedItem == .note(noteID))
        // ⌘N chapter targeting and lastOpenedSceneID restoration depend on this.
        #expect(session.selectedSceneID == sceneID)
    }

    @Test func searchPreservesSceneSelection() {
        let session = makeSession()
        let sceneID = session.project.chapters[0].scenes[0].id
        session.selectedItem = .scene(sceneID)
        session.selectedItem = .search
        #expect(session.selectedItem == .search)
        #expect(session.selectedSceneID == sceneID)
        session.selectedItem = .scene(sceneID)
        #expect(session.selectedItem == .scene(sceneID))
        #expect(session.showsSearch == false)
    }

    @Test func nilSelectionIsIgnored() {
        let session = makeSession()
        let sceneID = session.project.chapters[0].scenes[0].id
        session.selectedItem = .scene(sceneID)
        session.selectedItem = nil
        #expect(session.selectedItem == .scene(sceneID))
        #expect(session.selectedSceneID == sceneID)
    }
}
