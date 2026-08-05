import AppKit
import Foundation
import Testing
@testable import Fictioneer

struct ProjectPackageRoundTripTests {
    private func temporaryPackageURL() -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent("fictioneer-tests-\(UUID().uuidString)")
            .appendingPathComponent("Test.fictioneer")
    }

    private func makeRichContent() -> NSAttributedString {
        let content = NSMutableAttributedString()
        content.append(NSAttributedString(string: "Chapter One\n", attributes: [
            .headingLevel: 1,
            .font: NSFont.boldSystemFont(ofSize: 28),
            .foregroundColor: NSColor.labelColor,
        ]))
        content.append(NSAttributedString(string: "It was a dark and stormy night.\n", attributes: [
            .font: NSFont.systemFont(ofSize: 18),
            .foregroundColor: NSColor.labelColor,
        ]))
        content.append(NSAttributedString(string: "A remembered whisper.\n", attributes: [
            .blockquote: true,
            .font: NSFont.systemFont(ofSize: 18).withItalicTrait(),
            .foregroundColor: NSColor.secondaryLabelColor,
        ]))
        return content
    }

    private func makeProject() -> Project {
        let sceneOne = Scene(title: "Opening", content: makeRichContent())
        let sceneTwo = Scene(title: "The Meeting", content: NSAttributedString(string: "They met at dawn."))
        let sceneThree = Scene(title: "Empty Scene")
        let project = Project(
            title: "Round Trip",
            details: "A test novel",
            chapters: [
                Chapter(title: "Act I", scenes: [sceneOne, sceneTwo]),
                Chapter(title: "Act II", scenes: [sceneThree], isExpanded: false),
            ],
            notes: [Note(title: "Marlowe", body: NSAttributedString(string: "A detective."), tags: ["character", "pov"])]
        )
        project.lastOpenedSceneID = sceneTwo.id
        return project
    }

    @Test func fullWriteAndReadRoundTrip() throws {
        let url = temporaryPackageURL()
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }

        let original = makeProject()
        try ProjectPackage.write(original, to: url)
        let restored = try ProjectPackage.read(from: url)

        #expect(restored.id == original.id)
        #expect(restored.title == "Round Trip")
        #expect(restored.details == "A test novel")
        #expect(restored.lastOpenedSceneID == original.lastOpenedSceneID)
        #expect(restored.chapters.count == 2)
        #expect(restored.chapters[0].title == "Act I")
        #expect(restored.chapters[1].isExpanded == false)
        #expect(restored.chapters[0].scenes.map(\.title) == ["Opening", "The Meeting"])

        // Rich content round-trips including custom attributes.
        let content = restored.chapters[0].scenes[0].content
        #expect(content.string == makeRichContent().string)
        let headingAttributes = content.attributes(at: 0, effectiveRange: nil)
        #expect((headingAttributes[.headingLevel] as? Int) == 1)
        let quoteLocation = content.string.utf16.distance(
            from: content.string.utf16.startIndex,
            to: content.string.range(of: "A remembered")!.lowerBound.samePosition(in: content.string.utf16)!
        )
        let quoteAttributes = content.attributes(at: quoteLocation, effectiveRange: nil)
        #expect((quoteAttributes[.blockquote] as? Bool) == true)

        // Word counts recomputed from restored content match.
        #expect(restored.chapters[0].scenes[1].wordCount == 4)
        #expect(restored.notes[0].tags == ["character", "pov"])
        #expect(restored.notes[0].body.string == "A detective.")
    }

    @Test func incrementalSaveWritesDirtyAndRemovesOrphans() throws {
        let url = temporaryPackageURL()
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }

        let project = makeProject()
        try ProjectPackage.write(project, to: url)

        let editedScene = project.chapters[0].scenes[0]
        editedScene.updateContent(NSAttributedString(string: "Rewritten entirely."))
        let deletedScene = project.chapters[0].scenes[1]
        project.deleteScene(deletedScene)

        try ProjectPackage.save(project, to: url, dirtySceneIDs: [editedScene.id], dirtyNoteIDs: [])

        let restored = try ProjectPackage.read(from: url)
        #expect(restored.chapters[0].scenes.count == 1)
        #expect(restored.chapters[0].scenes[0].content.string == "Rewritten entirely.")

        let scenesDir = url.appendingPathComponent("scenes")
        let files = try FileManager.default.contentsOfDirectory(atPath: scenesDir.path)
        #expect(!files.contains("\(deletedScene.id.uuidString).textarchive"))
        #expect(files.count == 2)
    }

    @Test func ghostTextIsNeverPersisted() throws {
        let url = temporaryPackageURL()
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }

        let content = NSMutableAttributedString(string: "Real text.")
        content.append(NSAttributedString(string: " ghost suggestion", attributes: [.ghostText: true]))
        let scene = Scene(title: "S", content: content)
        let project = Project(title: "G", chapters: [Chapter(title: "C", scenes: [scene])])

        try ProjectPackage.write(project, to: url)
        let restored = try ProjectPackage.read(from: url)
        #expect(restored.chapters[0].scenes[0].content.string == "Real text.")
    }

    /// Pasted rich text can carry attributes beyond the editor's own set —
    /// a Safari link (NSURL), bulleted lists (NSTextList inside the paragraph
    /// style), attachments. The secure-decoding allowlist must round-trip
    /// them all; a too-narrow list permanently bricked the project.
    @Test func pastedRichAttributesRoundTrip() throws {
        let url = temporaryPackageURL()
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }

        let content = NSMutableAttributedString()
        content.append(NSAttributedString(string: "A link", attributes: [
            .link: URL(string: "https://example.com/page")! as NSURL,
            .font: NSFont.systemFont(ofSize: 18),
        ]))
        content.append(NSAttributedString(string: " and shadowed text.\n", attributes: [
            .shadow: NSShadow(),
            .font: NSFont.systemFont(ofSize: 18),
        ]))
        let listStyle = NSMutableParagraphStyle()
        listStyle.textLists = [NSTextList(markerFormat: .disc, options: 0)]
        content.append(NSAttributedString(string: "\t•\tBullet item\n", attributes: [
            .paragraphStyle: listStyle,
            .font: NSFont.systemFont(ofSize: 18),
        ]))
        let attachment = NSTextAttachment()
        attachment.fileWrapper = FileWrapper(regularFileWithContents: Data([0x1, 0x2, 0x3]))
        attachment.fileWrapper?.preferredFilename = "blob.bin"
        content.append(NSAttributedString(attachment: attachment))

        let scene = Scene(title: "Pasted", content: content)
        let project = Project(title: "P", chapters: [Chapter(title: "C", scenes: [scene])])
        try ProjectPackage.write(project, to: url)

        let restored = try ProjectPackage.read(from: url)
        let restoredContent = restored.chapters[0].scenes[0].content
        #expect(restoredContent.string == content.string)
        let linkAttributes = restoredContent.attributes(at: 0, effectiveRange: nil)
        #expect((linkAttributes[.link] as? URL)?.absoluteString == "https://example.com/page"
            || (linkAttributes[.link] as? NSURL)?.absoluteString == "https://example.com/page")
        let bulletLocation = (restoredContent.string as NSString).range(of: "Bullet").location
        let bulletStyle = restoredContent.attribute(.paragraphStyle, at: bulletLocation, effectiveRange: nil) as? NSParagraphStyle
        #expect(bulletStyle?.textLists.isEmpty == false)
    }

    /// A corrupt archive must not fail the whole read — the project opens
    /// with that one scene degraded to empty content.
    @Test func corruptArchiveDegradesToEmptyScene() throws {
        let url = temporaryPackageURL()
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }

        let project = makeProject()
        try ProjectPackage.write(project, to: url)
        let corruptedScene = project.chapters[0].scenes[0]
        let archiveURL = url
            .appendingPathComponent("scenes")
            .appendingPathComponent("\(corruptedScene.id.uuidString).textarchive")
        try Data("not an archive".utf8).write(to: archiveURL)

        let restored = try ProjectPackage.read(from: url)
        #expect(restored.chapters[0].scenes[0].content.string.isEmpty)
        // The rest of the manuscript survives untouched.
        #expect(restored.chapters[0].scenes[1].content.string == "They met at dawn.")
        #expect(restored.notes[0].body.string == "A detective.")
    }

    /// A missing archive (crash between manifest and archive writes) also
    /// degrades to an empty scene rather than refusing to open.
    @Test func missingArchiveDegradesToEmptyScene() throws {
        let url = temporaryPackageURL()
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }

        let project = makeProject()
        try ProjectPackage.write(project, to: url)
        let missingScene = project.chapters[0].scenes[0]
        let archiveURL = url
            .appendingPathComponent("scenes")
            .appendingPathComponent("\(missingScene.id.uuidString).textarchive")
        try FileManager.default.removeItem(at: archiveURL)

        let restored = try ProjectPackage.read(from: url)
        #expect(restored.chapters[0].scenes[0].content.string.isEmpty)
        #expect(restored.chapters[0].scenes[1].content.string == "They met at dawn.")
    }

    @Test func newerFormatVersionIsRejected() throws {
        let url = temporaryPackageURL()
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }

        let manifest = """
        {"formatVersion": 999, "id": "\(UUID().uuidString)", "title": "X", "details": "",
         "createdAt": "2026-01-01T00:00:00Z", "updatedAt": "2026-01-01T00:00:00Z",
         "chapters": [], "notes": []}
        """
        try manifest.data(using: .utf8)!.write(to: url.appendingPathComponent("project.json"))
        #expect(throws: ProjectPackageError.self) {
            _ = try ProjectPackage.read(from: url)
        }
    }
}

extension NSFont {
    func withItalicTrait() -> NSFont {
        NSFontManager.shared.convert(self, toHaveTrait: .italicFontMask)
    }
}
