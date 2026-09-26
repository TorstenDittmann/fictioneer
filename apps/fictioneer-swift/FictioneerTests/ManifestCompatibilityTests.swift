import Foundation
import Testing
@testable import Fictioneer

struct ManifestCompatibilityTests {
    /// A manifest written by the original MVP build — none of the parity-era
    /// optional fields exist. Must decode and open.
    @Test func v1ManifestWithoutNewFieldsDecodes() throws {
        let json = """
        {"formatVersion": 1, "id": "\(UUID().uuidString)", "title": "Old Project", "details": "",
         "createdAt": "2026-01-01T00:00:00Z", "updatedAt": "2026-01-01T00:00:00Z",
         "chapters": [], "notes": []}
        """
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let manifest = try decoder.decode(ProjectManifest.self, from: Data(json.utf8))
        #expect(manifest.progressGoals == nil)
        #expect(manifest.dailyProgress == nil)
        #expect(manifest.epubMetadata == nil)
    }

    @Test func newFieldsRoundTripThroughPackage() throws {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("compat-\(UUID().uuidString)")
            .appendingPathComponent("Test.fictioneer")
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }

        let project = Project.makeNew(title: "Progress")
        project.progressGoals = ProgressGoals(
            dailyWordTarget: 750, projectWordTarget: 80_000, createdAt: .now, updatedAt: .now
        )
        project.dailyProgress = [
            DailyProgress(date: "2026-07-31", wordsWritten: 812, goalMet: true, sessionsCount: 2, updatedAt: .now)
        ]
        project.dailyWordSnapshots = ["2026-07-31": 4200, "2026-08-01": 5012]
        project.epubMetadata = ProjectEpubMetadata(
            author: "T. Dittmann", publisher: "Selfpub", language: "de",
            rights: "All rights reserved", subjects: ["Mystery", "Victorian"]
        )

        try ProjectPackage.write(project, to: url)
        let restored = try ProjectPackage.read(from: url)
        #expect(restored.progressGoals?.dailyWordTarget == 750)
        #expect(restored.progressGoals?.projectWordTarget == 80_000)
        #expect(restored.dailyProgress.count == 1)
        #expect(restored.dailyProgress[0].goalMet == true)
        #expect(restored.dailyWordSnapshots["2026-08-01"] == 5012)
        #expect(restored.epubMetadata?.language == "de")
        #expect(restored.epubMetadata?.subjects == ["Mystery", "Victorian"])
    }
}
