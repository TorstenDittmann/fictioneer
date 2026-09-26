import AppKit
import Foundation
import os

enum ProjectPackageError: Error, LocalizedError {
    case missingManifest
    case unsupportedFormatVersion(Int)
    case corruptTextArchive(String)

    var errorDescription: String? {
        switch self {
        case .missingManifest:
            "The project file is missing its manifest (project.json)."
        case .unsupportedFormatVersion(let version):
            "This project was saved with a newer version of Fictioneer (format \(version))."
        case .corruptTextArchive(let name):
            "The text content \"\(name)\" could not be read."
        }
    }
}

/// Reads and writes the `.fictioneer` document package:
///
///     MyNovel.fictioneer/
///       project.json               manifest (ids, titles, order, counts, dates)
///       scenes/<uuid>.textarchive  archived NSAttributedString per scene
///       notes/<uuid>.textarchive   archived NSAttributedString per note body
enum ProjectPackage {
    static let manifestFilename = "project.json"
    static let scenesDirectory = "scenes"
    static let notesDirectory = "notes"
    static let textArchiveExtension = "textarchive"

    // MARK: - Write

    /// Builds the package as a file wrapper tree. Archives for scenes/notes
    /// that are not dirty are reused from `previous` (the wrapper last read or
    /// written), so saving rewrites only what changed — NSDocument hard-links
    /// unchanged files, and iCloud only uploads the changed ones. Scenes/notes
    /// that no longer exist are simply left out.
    static func fileWrapper(
        for project: Project,
        reusing previous: FileWrapper? = nil,
        dirtySceneIDs: Set<UUID> = [],
        dirtyNoteIDs: Set<UUID> = []
    ) throws -> FileWrapper {
        let manifestData = try encoder().encode(ProjectManifest(project))
        let previousScenes = previous?.fileWrappers?[scenesDirectory]?.fileWrappers ?? [:]
        let previousNotes = previous?.fileWrappers?[notesDirectory]?.fileWrappers ?? [:]

        var sceneWrappers: [String: FileWrapper] = [:]
        for scene in project.allScenes {
            let filename = archiveFilename(for: scene.id)
            if !dirtySceneIDs.contains(scene.id), let reused = previousScenes[filename] {
                sceneWrappers[filename] = reused
            } else {
                let data = try TextArchive.data(from: scene.content.strippingGhostText())
                sceneWrappers[filename] = FileWrapper(regularFileWithContents: data)
            }
        }
        var noteWrappers: [String: FileWrapper] = [:]
        for note in project.notes {
            let filename = archiveFilename(for: note.id)
            if !dirtyNoteIDs.contains(note.id), let reused = previousNotes[filename] {
                noteWrappers[filename] = reused
            } else {
                let data = try TextArchive.data(from: note.body.strippingGhostText())
                noteWrappers[filename] = FileWrapper(regularFileWithContents: data)
            }
        }

        return FileWrapper(directoryWithFileWrappers: [
            manifestFilename: FileWrapper(regularFileWithContents: manifestData),
            scenesDirectory: directory(named: scenesDirectory, sceneWrappers),
            notesDirectory: directory(named: notesDirectory, noteWrappers),
        ])
    }

    /// FileWrapper hard-links an unchanged file from the previous revision
    /// only when it can resolve the file's original path, which needs an
    /// accurate `filename` on every directory above it.
    private static func directory(named name: String, _ children: [String: FileWrapper]) -> FileWrapper {
        let directory = FileWrapper(directoryWithFileWrappers: children)
        directory.filename = name
        directory.preferredFilename = name
        return directory
    }

    /// Full atomic write of the entire package (create, example project, tests).
    static func write(_ project: Project, to url: URL) throws {
        try fileWrapper(for: project).write(to: url, options: .atomic, originalContentsURL: nil)
    }

    // MARK: - Read

    static func read(from url: URL) throws -> Project {
        try read(from: FileWrapper(url: url, options: .immediate))
    }

    static func read(from wrapper: FileWrapper) throws -> Project {
        guard let manifestData = wrapper.fileWrappers?[manifestFilename]?.regularFileContents else {
            throw ProjectPackageError.missingManifest
        }
        let manifest = try decoder().decode(ProjectManifest.self, from: manifestData)
        guard manifest.formatVersion <= AppConfig.formatVersion else {
            throw ProjectPackageError.unsupportedFormatVersion(manifest.formatVersion)
        }

        let sceneFiles = wrapper.fileWrappers?[scenesDirectory]?.fileWrappers ?? [:]
        let noteFiles = wrapper.fileWrappers?[notesDirectory]?.fileWrappers ?? [:]

        let chapters = manifest.chapters.map { chapterManifest in
            let scenes = chapterManifest.scenes.map { sceneManifest in
                Scene(
                    id: sceneManifest.id,
                    title: sceneManifest.title,
                    content: readArchive(named: archiveFilename(for: sceneManifest.id), in: sceneFiles),
                    createdAt: sceneManifest.createdAt,
                    updatedAt: sceneManifest.updatedAt,
                    synopsis: sceneManifest.synopsis ?? "",
                    status: sceneManifest.status,
                    povNoteID: sceneManifest.povNoteID,
                    labels: sceneManifest.labels ?? [],
                    targetWords: sceneManifest.targetWords
                )
            }
            return Chapter(
                id: chapterManifest.id,
                title: chapterManifest.title,
                scenes: scenes,
                isExpanded: chapterManifest.isExpanded,
                createdAt: chapterManifest.createdAt,
                updatedAt: chapterManifest.updatedAt
            )
        }
        let notes = manifest.notes.map { noteManifest in
            Note(
                id: noteManifest.id,
                title: noteManifest.title,
                body: readArchive(named: archiveFilename(for: noteManifest.id), in: noteFiles),
                tags: noteManifest.tags,
                createdAt: noteManifest.createdAt,
                updatedAt: noteManifest.updatedAt
            )
        }

        let project = Project(
            id: manifest.id,
            title: manifest.title,
            details: manifest.details,
            chapters: chapters,
            notes: notes,
            lastOpenedSceneID: manifest.lastOpenedSceneID,
            createdAt: manifest.createdAt,
            updatedAt: manifest.updatedAt
        )
        project.progressGoals = manifest.progressGoals
        project.dailyProgress = manifest.dailyProgress ?? []
        project.dailyWordSnapshots = manifest.dailyWordSnapshots ?? [:]
        project.lastSessionTime = manifest.lastSessionTime
        project.epubMetadata = manifest.epubMetadata
        project.quoteStyle = manifest.quoteStyle
        project.plotLines = manifest.plotLines ?? []
        for beat in manifest.beats ?? [] {
            project.beats[BeatKey(sceneID: beat.sceneID, plotLineID: beat.plotLineID)] = beat.text
        }
        return project
    }

    // MARK: - Helpers

    private static let logger = Logger(subsystem: "app.fictioneer", category: "ProjectPackage")

    private static func readArchive(named filename: String, in files: [String: FileWrapper]) -> NSAttributedString {
        guard let data = files[filename]?.regularFileContents else {
            // A missing archive (e.g. crash between manifest and archive writes)
            // degrades to an empty scene rather than refusing to open the project.
            return NSAttributedString()
        }
        do {
            return try TextArchive.attributedString(from: data)
        } catch {
            // A corrupt or undecodable archive must never brick the whole
            // project — degrade that one scene/note to empty content, like the
            // missing-archive branch, so the rest of the manuscript opens.
            logger.error("Corrupt text archive \(filename, privacy: .public): \(error.localizedDescription, privacy: .public)")
            return NSAttributedString()
        }
    }

    private static func archiveFilename(for id: UUID) -> String {
        "\(id.uuidString).\(textArchiveExtension)"
    }

    private nonisolated static func encoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }

    private nonisolated static func decoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}

/// Lossless archiving of NSAttributedString including the custom
/// `.headingLevel` / `.blockquote` attributes.
nonisolated enum TextArchive {
    static func data(from attributedString: NSAttributedString) throws -> Data {
        try NSKeyedArchiver.archivedData(withRootObject: attributedString, requiringSecureCoding: true)
    }

    static func attributedString(from data: Data) throws -> NSAttributedString {
        let unarchiver = try NSKeyedUnarchiver(forReadingFrom: data)
        unarchiver.requiresSecureCoding = true
        defer { unarchiver.finishDecoding() }
        guard
            let result = unarchiver.decodeObject(
                of: [
                    NSAttributedString.self, NSMutableAttributedString.self, NSString.self,
                    NSNumber.self, NSFont.self, NSColor.self, NSParagraphStyle.self,
                    NSMutableParagraphStyle.self, NSDictionary.self, NSArray.self,
                    // Rich-text attributes the editor can pick up from pastes
                    // (a Safari link carries NSURL, styled clipboards can carry
                    // shadows, lists, tables, tabs, attachments). Omitting
                    // these made a paste permanently unreadable on reopen.
                    NSURL.self, NSTextAttachment.self, NSShadow.self,
                    NSTextList.self, NSTextBlock.self, NSTextTab.self,
                    NSData.self,
                ],
                forKey: NSKeyedArchiveRootObjectKey
            ) as? NSAttributedString
        else {
            throw CocoaError(.coderReadCorrupt)
        }
        return result
    }
}
