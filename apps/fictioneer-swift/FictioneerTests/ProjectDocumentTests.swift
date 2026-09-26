import AppKit
import Foundation
import Testing
import UniformTypeIdentifiers
@testable import Fictioneer

@MainActor
struct ProjectDocumentTests {
    private struct Fixture {
        let root: URL
        let url: URL

        func cleanup() {
            // Restore permissions in case a failure test left them read-only.
            try? FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: root.path)
            try? FileManager.default.removeItem(at: root)
        }
    }

    private static let typeName = UTType.fictioneerProject.identifier

    private func makePackage() throws -> Fixture {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("fictioneer-document-tests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        let url = root.appendingPathComponent("Test.fictioneer")
        let project = Project(title: "Document", chapters: [
            Chapter(title: "One", scenes: [
                Scene(title: "Opening", content: NSAttributedString(string: "First draft.")),
                Scene(title: "Untouched", content: NSAttributedString(string: "Leave me be.")),
            ]),
        ])
        try ProjectPackage.write(project, to: url)
        return Fixture(root: root, url: url)
    }

    /// Callers must `close()` the document: an open document with unsaved
    /// changes keeps autosaving, and once the fixture folder is deleted that
    /// fails with an "couldn't be autosaved" alert in the test host.
    private func open(_ url: URL) throws -> (ProjectDocument, ProjectSession) {
        let document = try ProjectDocument(contentsOf: url, ofType: Self.typeName)
        let session = try #require(document.session)
        return (document, session)
    }

    private func save(_ document: ProjectDocument, _ operation: NSDocument.SaveOperationType) async -> Error? {
        await withCheckedContinuation { continuation in
            document.save(to: document.fileURL!, ofType: Self.typeName, for: operation) { error in
                continuation.resume(returning: error)
            }
        }
    }

    private func archiveURL(_ scene: Scene, in url: URL) -> URL {
        url.appendingPathComponent("scenes/\(scene.id.uuidString).textarchive")
    }

    private func inode(_ url: URL) throws -> Int? {
        try FileManager.default.attributesOfItem(atPath: url.path)[.systemFileNumber] as? Int
    }

    @Test func markDirtyMarksDocumentEdited() throws {
        let fixture = try makePackage()
        defer { fixture.cleanup() }
        let (document, session) = try open(fixture.url)
        defer { document.close() }

        #expect(!document.isDocumentEdited)
        session.markDirty()
        #expect(document.isDocumentEdited)
        #expect(document.hasUnautosavedChanges)
    }

    @Test func saveWritesEditsAndReopens() async throws {
        let fixture = try makePackage()
        defer { fixture.cleanup() }
        let (document, session) = try open(fixture.url)
        defer { document.close() }

        let scene = session.project.chapters[0].scenes[0]
        scene.updateContent(NSAttributedString(string: "Rewritten opening."))
        session.selectedItem = .scene(scene.id)
        session.markDirty(sceneID: scene.id)

        #expect(await save(document, .saveOperation) == nil)

        #expect(!session.hasPendingChanges)
        #expect(!document.isDocumentEdited)
        guard case .saved = session.saveState else {
            Issue.record("expected .saved, got \(session.saveState)")
            return
        }
        let reopened = try ProjectPackage.read(from: fixture.url)
        #expect(reopened.chapters[0].scenes[0].content.string == "Rewritten opening.")
        #expect(reopened.lastOpenedSceneID == scene.id)
    }

    @Test func autosaveRewritesOnlyEditedArchives() async throws {
        let fixture = try makePackage()
        defer { fixture.cleanup() }
        let (document, session) = try open(fixture.url)
        defer { document.close() }

        let edited = session.project.chapters[0].scenes[0]
        let untouched = session.project.chapters[0].scenes[1]
        let editedBefore = try inode(archiveURL(edited, in: fixture.url))
        let untouchedBefore = try inode(archiveURL(untouched, in: fixture.url))

        edited.updateContent(NSAttributedString(string: "Only this changed."))
        session.markDirty(sceneID: edited.id)
        #expect(await save(document, .autosaveInPlaceOperation) == nil)

        // Unchanged archives are carried over as the same file (hard link),
        // so iCloud has nothing to upload for them.
        #expect(try inode(archiveURL(untouched, in: fixture.url)) == untouchedBefore)
        #expect(try inode(archiveURL(edited, in: fixture.url)) != editedBefore)
        let reopened = try ProjectPackage.read(from: fixture.url)
        #expect(reopened.chapters[0].scenes[0].content.string == "Only this changed.")
        #expect(reopened.chapters[0].scenes[1].content.string == "Leave me be.")
    }

    @Test func failedSaveKeepsPendingChangesAndLaterSaveRecovers() async throws {
        let fixture = try makePackage()
        defer { fixture.cleanup() }
        let (document, session) = try open(fixture.url)
        defer { document.close() }

        let scene = session.project.chapters[0].scenes[0]
        scene.updateContent(NSAttributedString(string: "Unsaveable for now."))
        session.markDirty(sceneID: scene.id)

        // An unwritable location → the save must fail loudly, not drop work.
        try FileManager.default.setAttributes([.posixPermissions: 0o555], ofItemAtPath: fixture.root.path)
        #expect(await save(document, .autosaveInPlaceOperation) != nil)
        guard case .failed = session.saveState else {
            Issue.record("expected .failed, got \(session.saveState)")
            return
        }
        #expect(session.hasPendingChanges)
        #expect(document.isDocumentEdited)

        // Location restored → a retry writes the pending changes.
        try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: fixture.root.path)
        #expect(await save(document, .autosaveInPlaceOperation) == nil)
        #expect(!session.hasPendingChanges)
        let reopened = try ProjectPackage.read(from: fixture.url)
        #expect(reopened.chapters[0].scenes[0].content.string == "Unsaveable for now.")
    }

    @Test func editDuringSaveStaysPending() async throws {
        let fixture = try makePackage()
        defer { fixture.cleanup() }
        let (document, session) = try open(fixture.url)
        defer { document.close() }

        let scene = session.project.chapters[0].scenes[0]
        session.markDirty(sceneID: scene.id)
        let snapshot = session.beginSave()
        session.markDirty(sceneID: session.project.chapters[0].scenes[1].id)
        session.endSave(snapshot, error: nil)

        #expect(session.hasPendingChanges)
        #expect(session.dirtySceneIDs == [session.project.chapters[0].scenes[1].id])
        #expect(session.saveState == .dirty)
    }

    @Test func revertLoadsNewContentAndKeepsNavigation() throws {
        let fixture = try makePackage()
        defer { fixture.cleanup() }
        let (document, session) = try open(fixture.url)
        defer { document.close() }
        let second = session.project.chapters[0].scenes[1]
        session.selectedItem = .scene(second.id)
        session.isFocusMode = true

        // Another device rewrote the package.
        let changed = try ProjectPackage.read(from: fixture.url)
        changed.chapters[0].scenes[1].updateContent(NSAttributedString(string: "Edited elsewhere."))
        try ProjectPackage.write(changed, to: fixture.url)

        try document.revert(toContentsOf: fixture.url, ofType: Self.typeName)

        let reloaded = try #require(document.session)
        #expect(reloaded !== session)
        #expect(reloaded.project.chapters[0].scenes[1].content.string == "Edited elsewhere.")
        #expect(reloaded.selectedSceneID == second.id)
        #expect(reloaded.isFocusMode)
    }
}
