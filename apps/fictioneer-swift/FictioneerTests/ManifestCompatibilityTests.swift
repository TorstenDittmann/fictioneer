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
        #expect(manifest.book == nil)
    }

    /// Projects saved before book settings existed carry `epubMetadata`;
    /// it seeds the book settings on open.
    @Test func legacyEpubMetadataSeedsBookSettings() throws {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("compat-\(UUID().uuidString)")
            .appendingPathComponent("Legacy.fictioneer")
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }

        let json = """
        {"formatVersion": 1, "id": "\(UUID().uuidString)", "title": "Old", "details": "",
         "createdAt": "2026-01-01T00:00:00Z", "updatedAt": "2026-01-01T00:00:00Z",
         "chapters": [], "notes": [],
         "epubMetadata": {"author": "Old Author", "publisher": "Old House", "language": "fr",
                          "rights": "", "subjects": ["Drama"]}}
        """
        try Data(json.utf8).write(to: url.appendingPathComponent("project.json"))
        let project = try ProjectPackage.read(from: url)
        #expect(project.book.author == "Old Author")
        #expect(project.book.publisher == "Old House")
        #expect(project.book.language == "fr")
        #expect(project.book.subjects == ["Drama"])
    }

    @Test func coverImageRoundTripsThroughPackage() throws {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("compat-\(UUID().uuidString)")
            .appendingPathComponent("Cover.fictioneer")
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }

        let project = Project.makeNew(title: "Cover")
        let png = Data([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x01, 0x02])
        project.coverImage = BookCoverImage(data: png, fileExtension: "png")
        project.book.cover = .image
        try ProjectPackage.write(project, to: url)

        #expect(FileManager.default.fileExists(atPath: url.appendingPathComponent("cover.png").path))
        let restored = try ProjectPackage.read(from: url)
        #expect(restored.coverImage == project.coverImage)
        #expect(restored.book.cover == .image)
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
        project.book.author = "T. Dittmann"
        project.book.language = "de"
        project.book.subjects = ["Mystery", "Victorian"]
        project.book.chapterHeading = .numeralAndTitle

        try ProjectPackage.write(project, to: url)
        let restored = try ProjectPackage.read(from: url)
        #expect(restored.progressGoals?.dailyWordTarget == 750)
        #expect(restored.progressGoals?.projectWordTarget == 80_000)
        #expect(restored.dailyProgress.count == 1)
        #expect(restored.dailyProgress[0].goalMet == true)
        #expect(restored.dailyWordSnapshots["2026-08-01"] == 5012)
        #expect(restored.book.language == "de")
        #expect(restored.book.subjects == ["Mystery", "Victorian"])
        #expect(restored.book.chapterHeading == .numeralAndTitle)
    }
}
