import AppKit
import Foundation
import Testing
@testable import Fictioneer

@MainActor
struct ProjectSessionTests {
    private func makePackage() throws -> (url: URL, project: Project, cleanup: () -> Void) {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("fictioneer-session-tests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        let url = root.appendingPathComponent("Test.fictioneer")
        let scene = Scene(title: "Opening", content: NSAttributedString(string: "First draft."))
        let project = Project(title: "Session", chapters: [Chapter(title: "One", scenes: [scene])])
        try ProjectPackage.write(project, to: url)
        return (url, project, {
            // Restore permissions in case a failure test left them read-only.
            try? FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: url.path)
            try? FileManager.default.removeItem(at: root)
        })
    }

    @Test func markDirtyThenSaveNowPersistsAndReopens() throws {
        let (url, project, cleanup) = try makePackage()
        defer { cleanup() }

        let session = ProjectSession(url: url, project: project, ownsSecurityScope: false)
        let scene = project.chapters[0].scenes[0]
        scene.updateContent(NSAttributedString(string: "Rewritten opening."))
        session.markDirty(sceneID: scene.id)
        #expect(session.hasPendingChanges)

        session.saveNow()
        #expect(!session.hasPendingChanges)
        guard case .saved = session.saveState else {
            Issue.record("expected .saved, got \(session.saveState)")
            return
        }

        let reopened = try ProjectPackage.read(from: url)
        #expect(reopened.chapters[0].scenes[0].content.string == "Rewritten opening.")
    }

    @Test func closeForceSavesPendingChanges() throws {
        let (url, project, cleanup) = try makePackage()
        defer { cleanup() }

        let session = ProjectSession(url: url, project: project, ownsSecurityScope: false)
        let scene = project.chapters[0].scenes[0]
        scene.updateContent(NSAttributedString(string: "Saved on close."))
        session.markDirty(sceneID: scene.id)

        #expect(session.close())

        let reopened = try ProjectPackage.read(from: url)
        #expect(reopened.chapters[0].scenes[0].content.string == "Saved on close.")
        #expect(reopened.lastOpenedSceneID == session.selectedSceneID)
    }

    @Test func failedSaveKeepsPendingChangesAndLaterSaveRecovers() throws {
        let (url, project, cleanup) = try makePackage()
        defer { cleanup() }

        let session = ProjectSession(url: url, project: project, ownsSecurityScope: false)
        let scene = project.chapters[0].scenes[0]
        scene.updateContent(NSAttributedString(string: "Unsaveable for now."))
        session.markDirty(sceneID: scene.id)

        // Make the package unwritable → the save must fail loudly, not drop work.
        try FileManager.default.setAttributes([.posixPermissions: 0o555], ofItemAtPath: url.path)
        session.saveNow()
        guard case .failed = session.saveState else {
            Issue.record("expected .failed, got \(session.saveState)")
            return
        }
        #expect(session.hasPendingChanges)
        #expect(session.saveFailureMessage != nil)

        // close() must report the failure instead of silently discarding.
        #expect(session.close() == false)
        #expect(session.hasPendingChanges)

        // Location restored → a retry recovers the pending changes.
        try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: url.path)
        session.saveNow()
        #expect(!session.hasPendingChanges)
        let reopened = try ProjectPackage.read(from: url)
        #expect(reopened.chapters[0].scenes[0].content.string == "Unsaveable for now.")
        #expect(session.close())
    }

    @Test func autosaveBurstDebouncesIntoASingleDelayedSave() async throws {
        let (url, project, cleanup) = try makePackage()
        defer { cleanup() }

        let session = ProjectSession(
            url: url,
            project: project,
            ownsSecurityScope: false,
            autosaveDebounce: 0.15,
            autosaveThrottle: 0.2
        )
        let scene = project.chapters[0].scenes[0]
        scene.updateContent(NSAttributedString(string: "Autosaved."))
        session.markDirty(sceneID: scene.id)
        session.markDirty(sceneID: scene.id)
        session.markDirty(sceneID: scene.id)

        // Not saved before the debounce elapses…
        #expect(session.saveState == .dirty)
        try await Task.sleep(for: .milliseconds(50))
        #expect(session.saveState == .dirty)

        // …exactly one save after it.
        var savedAt: Date?
        for _ in 0..<100 {
            if case .saved(let date) = session.saveState {
                savedAt = date
                break
            }
            try await Task.sleep(for: .milliseconds(20))
        }
        #expect(savedAt != nil)
        let reopened = try ProjectPackage.read(from: url)
        #expect(reopened.chapters[0].scenes[0].content.string == "Autosaved.")

        // No further save fires for the burst (the state's timestamp is stable).
        try await Task.sleep(for: .milliseconds(400))
        if case .saved(let date) = session.saveState {
            #expect(date == savedAt)
        } else {
            Issue.record("expected .saved to remain, got \(session.saveState)")
        }
    }
}
