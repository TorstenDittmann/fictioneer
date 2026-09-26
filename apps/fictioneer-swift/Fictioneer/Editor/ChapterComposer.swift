import AppKit

extension NSAttributedString.Key {
    /// Marks the protected characters that start each scene in the continuous
    /// chapter view (value: the scene's UUID string). Never persisted: scene
    /// content is always read from between these runs.
    static let sceneBoundary = NSAttributedString.Key("app.fictioneer.sceneBoundary")
}

/// Lays out a chapter's scenes as one document and maps edits back.
///
/// Each scene starts with a boundary: for every scene but the first a
/// newline (ending the previous scene's last paragraph), then a heading
/// paragraph — one attachment character (ornament + scene title, drawn by
/// the caller) and a newline. Boundary characters carry `.sceneBoundary`,
/// and scenes are located by enumerating that attribute, never by cached
/// offsets, so edits can't knock the mapping out of line.
@MainActor
final class ChapterComposer: NSObject, NSTextStorageDelegate {
    struct SceneRange: Equatable {
        let sceneID: UUID
        /// The scene's own text, excluding its boundary.
        let content: NSRange
    }

    let chapter: Chapter
    /// Scenes whose text changed since the last `sync`.
    private(set) var touchedSceneIDs: Set<UUID> = []
    private var isComposing = false

    init(chapter: Chapter) {
        self.chapter = chapter
    }

    // MARK: - Building

    /// `heading` draws scene `index`'s heading attachment string (one
    /// U+FFFC character with its attachment and paragraph attributes).
    func compose(
        bodyAttributes: [NSAttributedString.Key: Any],
        heading: (Scene, Int) -> NSAttributedString
    ) -> NSAttributedString {
        let result = NSMutableAttributedString()
        for (index, scene) in chapter.scenes.enumerated() {
            let marker: [NSAttributedString.Key: Any] = [.sceneBoundary: scene.id.uuidString]
            if index > 0 {
                var attributes = bodyAttributes
                if result.length > 0 {
                    attributes = result.attributes(at: result.length - 1, effectiveRange: nil)
                }
                attributes.merge(marker) { $1 }
                result.append(NSAttributedString(string: "\n", attributes: attributes))
            }
            let head = NSMutableAttributedString(attributedString: heading(scene, index))
            head.append(NSAttributedString(
                string: "\n",
                attributes: head.length > 0 ? head.attributes(at: 0, effectiveRange: nil) : bodyAttributes
            ))
            head.addAttributes(marker, range: NSRange(location: 0, length: head.length))
            head.removeAttribute(.attachment, range: NSRange(location: head.length - 1, length: 1))
            result.append(head)
            result.append(scene.content)
        }
        return result
    }

    /// Call around programmatic replacement of the whole text (initial load).
    func performComposing(_ body: () -> Void) {
        isComposing = true
        defer { isComposing = false }
        body()
    }

    /// Redraws every scene heading in place (title, status or details
    /// changed) without touching text, undo or the caret.
    func refreshHeadings(in storage: NSTextStorage, heading: (Scene, Int) -> NSAttributedString) {
        var attachments: [(sceneID: UUID, location: Int)] = []
        storage.enumerateAttribute(.attachment, in: NSRange(location: 0, length: storage.length)) { value, range, _ in
            guard value != nil,
                  let id = (storage.attribute(.sceneBoundary, at: range.location, effectiveRange: nil) as? String)
                    .flatMap(UUID.init(uuidString:)) else { return }
            attachments.append((id, range.location))
        }
        performComposing {
            storage.beginEditing()
            for item in attachments {
                guard let index = chapter.scenes.firstIndex(where: { $0.id == item.sceneID }) else { continue }
                let fresh = heading(chapter.scenes[index], index)
                guard fresh.length > 0 else { continue }
                storage.setAttributes(
                    fresh.attributes(at: 0, effectiveRange: nil).merging([.sceneBoundary: item.sceneID.uuidString]) { $1 },
                    range: NSRange(location: item.location, length: 1)
                )
            }
            storage.endEditing()
        }
    }

    // MARK: - Mapping

    static func sceneRanges(in text: NSAttributedString) -> [SceneRange] {
        var boundaries: [(id: UUID, range: NSRange)] = []
        text.enumerateAttribute(.sceneBoundary, in: NSRange(location: 0, length: text.length)) { value, range, _ in
            guard let string = value as? String, let id = UUID(uuidString: string) else { return }
            if let last = boundaries.last, last.id == id, NSMaxRange(last.range) == range.location {
                boundaries[boundaries.count - 1].range.length += range.length
            } else {
                boundaries.append((id, range))
            }
        }
        return boundaries.enumerated().map { index, boundary in
            let start = NSMaxRange(boundary.range)
            let end = index + 1 < boundaries.count ? boundaries[index + 1].range.location : text.length
            return SceneRange(sceneID: boundary.id, content: NSRange(location: start, length: max(0, end - start)))
        }
    }

    /// Edits must stay inside one scene's text; boundaries are read-only.
    static func allowsChange(in range: NSRange, of text: NSAttributedString) -> Bool {
        sceneRanges(in: text).contains { scene in
            range.location >= scene.content.location && NSMaxRange(range) <= NSMaxRange(scene.content)
        }
    }

    /// The scene whose text contains `location`, and the offset within it.
    static func scene(at location: Int, in text: NSAttributedString) -> (sceneID: UUID, offset: Int)? {
        for scene in sceneRanges(in: text)
        where location >= scene.content.location && location <= NSMaxRange(scene.content) {
            return (scene.sceneID, location - scene.content.location)
        }
        return nil
    }

    // MARK: - Writing back

    /// Updates every touched scene from `text` (transient state already
    /// stripped) and returns them with their previous word counts.
    func sync(from text: NSAttributedString) -> [(scene: Scene, previousWords: Int, previousCharacters: Int)] {
        guard !touchedSceneIDs.isEmpty else { return [] }
        var changed: [(Scene, Int, Int)] = []
        for range in Self.sceneRanges(in: text) where touchedSceneIDs.contains(range.sceneID) {
            guard let scene = chapter.scenes.first(where: { $0.id == range.sceneID }) else { continue }
            let content = NSMutableAttributedString(attributedString: text.attributedSubstring(from: range.content))
            content.removeAttribute(.sceneBoundary, range: NSRange(location: 0, length: content.length))
            guard !content.isEqual(to: scene.content) else { continue }
            let previous = (scene.wordCount, scene.characterCount)
            scene.updateContent(content)
            changed.append((scene, previous.0, previous.1))
        }
        touchedSceneIDs = []
        return changed
    }

    // MARK: - NSTextStorageDelegate

    nonisolated func textStorage(
        _ textStorage: NSTextStorage,
        willProcessEditing editedMask: NSTextStorageEditActions,
        range editedRange: NSRange,
        changeInLength delta: Int
    ) {
        // Text storage delegates run on the main thread (the text view's).
        nonisolated(unsafe) let textStorage = textStorage
        MainActor.assumeIsolated {
            guard !isComposing, editedMask.contains(.editedCharacters), editedRange.length > 0 else { return }
            // Boundaries can't be edited, so boundary markers inside newly
            // edited characters came in by paste or typing attributes: drop them.
            textStorage.removeAttribute(.sceneBoundary, range: editedRange)
        }
    }

    nonisolated func textStorage(
        _ textStorage: NSTextStorage,
        didProcessEditing editedMask: NSTextStorageEditActions,
        range editedRange: NSRange,
        changeInLength delta: Int
    ) {
        nonisolated(unsafe) let textStorage = textStorage
        MainActor.assumeIsolated {
            guard !isComposing else { return }
            let start = Self.scene(at: editedRange.location, in: textStorage)
            let end = Self.scene(at: NSMaxRange(editedRange), in: textStorage)
            for scene in [start, end].compactMap({ $0 }) {
                touchedSceneIDs.insert(scene.sceneID)
            }
        }
    }
}
