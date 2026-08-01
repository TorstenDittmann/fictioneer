import Foundation
import Testing
@testable import Fictioneer

struct ExampleProjectFactoryTests {
    private func loadData() throws -> Data {
        // The test bundle hosts in the app, so the app bundle's resource is reachable.
        let url = try #require(Bundle.main.url(forResource: "ExampleProject", withExtension: "json"))
        return try Data(contentsOf: url)
    }

    @Test func buildsFullExampleProject() throws {
        let project = try ExampleProjectFactory.build(from: loadData())
        #expect(project.title == "The Bohemian Photograph Affair")
        #expect(project.chapters.count == 3)
        #expect(project.allScenes.count == 9)
        #expect(project.notes.count == 5)
        #expect(project.chapters[0].title == "I. The Visitor")
        #expect(project.notes.allSatisfy { !$0.tags.isEmpty })
        #expect(project.allScenes.allSatisfy { $0.wordCount > 100 })
        #expect(project.totalWordCount > 3000)
        #expect(project.lastOpenedSceneID == project.chapters[0].scenes[0].id)
    }

    @Test func htmlConversionStripsTagsAndDecodesEntities() {
        let converted = ExampleProjectFactory.attributedText(
            fromHTML: "<p>He said &quot;hi&quot; &amp; left.</p>\n\n<p><strong>Traits:</strong></p><ul><li>Sharp</li><li>Wry</li></ul>"
        )
        let text = converted.string
        #expect(text.contains("He said \"hi\" & left."))
        #expect(text.contains("• Sharp"))
        #expect(!text.contains("<"))
    }

    @Test func exampleProjectSavesAndReopens() throws {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("example-\(UUID().uuidString)")
            .appendingPathComponent("Example.fictioneer")
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }

        let project = try ExampleProjectFactory.build(from: loadData())
        try ProjectPackage.write(project, to: url)
        let restored = try ProjectPackage.read(from: url)
        #expect(restored.allScenes.count == 9)
        #expect(restored.totalWordCount == project.totalWordCount)
    }
}
