import AppKit
import Foundation

/// Builds "The Bohemian Photograph Affair" example project from the bundled
/// JSON (exported from the Tauri app's data module).
enum ExampleProjectFactory {
    nonisolated private struct ExampleData: Decodable {
        struct SceneData: Decodable {
            var title: String
            var content: String
        }
        struct ChapterData: Decodable {
            var title: String
            var scenes: [SceneData]
        }
        struct NoteData: Decodable {
            var title: String
            var description: String
            var tags: [String]
        }
        var title: String
        var description: String
        var chapters: [ChapterData]
        var notes: [NoteData]
    }

    enum FactoryError: Error {
        case missingResource
    }

    static func build() throws -> Project {
        guard let url = Bundle.main.url(forResource: "ExampleProject", withExtension: "json") else {
            throw FactoryError.missingResource
        }
        return try build(from: try Data(contentsOf: url))
    }

    static func build(from data: Data) throws -> Project {
        let example = try JSONDecoder().decode(ExampleData.self, from: data)
        let chapters = example.chapters.map { chapterData in
            Chapter(title: chapterData.title, scenes: chapterData.scenes.map { sceneData in
                Scene(title: sceneData.title, content: attributedText(fromHTML: sceneData.content))
            })
        }
        let notes = example.notes.map { noteData in
            Note(
                title: noteData.title,
                body: attributedText(fromHTML: noteData.description),
                tags: noteData.tags
            )
        }
        let project = Project(
            title: example.title,
            details: example.description,
            chapters: chapters,
            notes: notes
        )
        project.lastOpenedSceneID = project.allScenes.first?.id
        return project
    }

    /// Minimal HTML-lite conversion for the example content (paragraphs,
    /// list items, strong/em stripped to plain runs). The editor re-themes
    /// fonts on load, so plain body attributes suffice.
    static func attributedText(fromHTML html: String) -> NSAttributedString {
        var text = html
        text = text.replacingOccurrences(of: "</p>", with: "\n")
        text = text.replacingOccurrences(of: "</li>", with: "\n")
        text = text.replacingOccurrences(of: "<li>", with: "• ")
        text = text.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
        text = text.replacingOccurrences(of: "&amp;", with: "&")
        text = text.replacingOccurrences(of: "&lt;", with: "<")
        text = text.replacingOccurrences(of: "&gt;", with: ">")
        text = text.replacingOccurrences(of: "&quot;", with: "\"")
        text = text.replacingOccurrences(of: "&#39;", with: "'")
        text = text.replacingOccurrences(of: "\n{3,}", with: "\n\n", options: .regularExpression)
        text = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return NSAttributedString(string: text, attributes: [
            .font: NSFont.systemFont(ofSize: 18),
            .foregroundColor: NSColor.labelColor,
        ])
    }
}
