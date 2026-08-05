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

    /// Full atomic write of the entire package (used for create and save-as).
    static func write(_ project: Project, to url: URL) throws {
        let manifest = ProjectManifest(project)
        let manifestData = try encoder().encode(manifest)

        var sceneWrappers: [String: FileWrapper] = [:]
        for scene in project.allScenes {
            let data = try TextArchive.data(from: scene.content.strippingGhostText())
            sceneWrappers[archiveFilename(for: scene.id)] = FileWrapper(regularFileWithContents: data)
        }
        var noteWrappers: [String: FileWrapper] = [:]
        for note in project.notes {
            let data = try TextArchive.data(from: note.body.strippingGhostText())
            noteWrappers[archiveFilename(for: note.id)] = FileWrapper(regularFileWithContents: data)
        }

        let root = FileWrapper(directoryWithFileWrappers: [
            manifestFilename: FileWrapper(regularFileWithContents: manifestData),
            scenesDirectory: FileWrapper(directoryWithFileWrappers: sceneWrappers),
            notesDirectory: FileWrapper(directoryWithFileWrappers: noteWrappers),
        ])
        try root.write(to: url, options: .atomic, originalContentsURL: url)
    }

    /// Incremental save: always rewrites the manifest, but only the archives whose
    /// ids appear in the dirty sets. Removes archive files for deleted scenes/notes.
    static func save(
        _ project: Project,
        to url: URL,
        dirtySceneIDs: Set<UUID>,
        dirtyNoteIDs: Set<UUID>
    ) throws {
        let fileManager = FileManager.default
        guard fileManager.fileExists(atPath: url.appendingPathComponent(manifestFilename).path) else {
            // Package doesn't exist yet (or was moved out from under us) — full write.
            try write(project, to: url)
            return
        }

        let manifest = ProjectManifest(project)
        let manifestData = try encoder().encode(manifest)
        try manifestData.write(to: url.appendingPathComponent(manifestFilename), options: .atomic)

        let scenesURL = url.appendingPathComponent(scenesDirectory, isDirectory: true)
        let notesURL = url.appendingPathComponent(notesDirectory, isDirectory: true)
        try fileManager.createDirectory(at: scenesURL, withIntermediateDirectories: true)
        try fileManager.createDirectory(at: notesURL, withIntermediateDirectories: true)

        for scene in project.allScenes where dirtySceneIDs.contains(scene.id) {
            let data = try TextArchive.data(from: scene.content.strippingGhostText())
            try data.write(to: scenesURL.appendingPathComponent(archiveFilename(for: scene.id)), options: .atomic)
        }
        for note in project.notes where dirtyNoteIDs.contains(note.id) {
            let data = try TextArchive.data(from: note.body.strippingGhostText())
            try data.write(to: notesURL.appendingPathComponent(archiveFilename(for: note.id)), options: .atomic)
        }

        try removeOrphans(in: scenesURL, keeping: Set(project.allScenes.map(\.id)))
        try removeOrphans(in: notesURL, keeping: Set(project.notes.map(\.id)))
    }

    // MARK: - Read

    static func read(from url: URL) throws -> Project {
        let manifestURL = url.appendingPathComponent(manifestFilename)
        guard let manifestData = try? Data(contentsOf: manifestURL) else {
            throw ProjectPackageError.missingManifest
        }
        let manifest = try decoder().decode(ProjectManifest.self, from: manifestData)
        guard manifest.formatVersion <= AppConfig.formatVersion else {
            throw ProjectPackageError.unsupportedFormatVersion(manifest.formatVersion)
        }

        let scenesURL = url.appendingPathComponent(scenesDirectory, isDirectory: true)
        let notesURL = url.appendingPathComponent(notesDirectory, isDirectory: true)

        let chapters = try manifest.chapters.map { chapterManifest in
            let scenes = try chapterManifest.scenes.map { sceneManifest in
                let content = try readArchive(named: archiveFilename(for: sceneManifest.id), in: scenesURL)
                return Scene(
                    id: sceneManifest.id,
                    title: sceneManifest.title,
                    content: content,
                    createdAt: sceneManifest.createdAt,
                    updatedAt: sceneManifest.updatedAt
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
        let notes = try manifest.notes.map { noteManifest in
            let body = try readArchive(named: archiveFilename(for: noteManifest.id), in: notesURL)
            return Note(
                id: noteManifest.id,
                title: noteManifest.title,
                body: body,
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
        return project
    }

    // MARK: - Helpers

    private static let logger = Logger(subsystem: "app.fictioneer", category: "ProjectPackage")

    private static func readArchive(named filename: String, in directory: URL) throws -> NSAttributedString {
        let fileURL = directory.appendingPathComponent(filename)
        guard let data = try? Data(contentsOf: fileURL) else {
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

    private static func removeOrphans(in directory: URL, keeping ids: Set<UUID>) throws {
        let keep = Set(ids.map(archiveFilename(for:)))
        let contents = (try? FileManager.default.contentsOfDirectory(atPath: directory.path)) ?? []
        for filename in contents where filename.hasSuffix(".\(textArchiveExtension)") && !keep.contains(filename) {
            try FileManager.default.removeItem(at: directory.appendingPathComponent(filename))
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
