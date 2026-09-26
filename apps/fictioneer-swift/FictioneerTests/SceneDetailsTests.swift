import Foundation
import Testing
@testable import Fictioneer

struct SceneDetailsTests {
    @Test func statusDefaultsFromContent() {
        #expect(Scene(title: "Empty").status == .idea)
        #expect(Scene(title: "Written", content: NSAttributedString(string: "Some words here.")).status == .draft)
        #expect(Scene(title: "Explicit", status: .done).status == .done)
    }

    @Test func detailsRoundTripThroughPackage() throws {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("details-\(UUID().uuidString).fictioneer")
        defer { try? FileManager.default.removeItem(at: url) }

        let note = Note(title: "Dr. William Jameson")
        let scene = Scene(
            title: "The Mysterious Communication",
            content: NSAttributedString(string: "The letter arrived without a stamp."),
            synopsis: "An unsigned letter arrives.",
            status: .revised,
            povNoteID: note.id,
            labels: ["Clue", "Night"],
            targetWords: 1200
        )
        let project = Project(title: "T", chapters: [Chapter(title: "One", scenes: [scene])], notes: [note])
        try ProjectPackage.write(project, to: url)

        let restored = try #require(try ProjectPackage.read(from: url).chapters.first?.scenes.first)
        #expect(restored.synopsis == "An unsigned letter arrives.")
        #expect(restored.status == .revised)
        #expect(restored.povNoteID == note.id)
        #expect(restored.labels == ["Clue", "Night"])
        #expect(restored.targetWords == 1200)
    }

    @Test func olderPackagesInferStatusAndHaveNoDetails() throws {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("legacy-\(UUID().uuidString).fictioneer")
        defer { try? FileManager.default.removeItem(at: url) }
        let project = Project(title: "T", chapters: [Chapter(title: "One", scenes: [
            Scene(title: "Written", content: NSAttributedString(string: "Words and more words.")),
            Scene(title: "Empty"),
        ])])
        try ProjectPackage.write(project, to: url)

        // Strip the new keys, as a package saved before scene details would be.
        let manifestURL = url.appendingPathComponent("project.json")
        var json = try JSONSerialization.jsonObject(with: Data(contentsOf: manifestURL)) as! [String: Any]
        var chapters = json["chapters"] as! [[String: Any]]
        chapters[0]["scenes"] = (chapters[0]["scenes"] as! [[String: Any]]).map { scene in
            scene.filter { !["synopsis", "status", "povNoteID", "labels", "targetWords"].contains($0.key) }
        }
        json["chapters"] = chapters
        try JSONSerialization.data(withJSONObject: json).write(to: manifestURL)

        let scenes = try ProjectPackage.read(from: url).chapters[0].scenes
        #expect(scenes.map(\.status) == [.draft, .idea])
        #expect(scenes.allSatisfy { $0.synopsis.isEmpty && $0.labels.isEmpty && $0.povNoteID == nil && $0.targetWords == nil })
    }

    @Test func deletingANoteClearsPointOfView() {
        let note = Note(title: "Violet Thornton")
        let scene = Scene(title: "S", povNoteID: note.id)
        let project = Project(title: "T", chapters: [Chapter(title: "One", scenes: [scene])], notes: [note])
        project.deleteNote(note)
        #expect(scene.povNoteID == nil)
    }
}
