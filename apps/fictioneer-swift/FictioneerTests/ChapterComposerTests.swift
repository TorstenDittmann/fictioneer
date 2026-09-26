import AppKit
import Testing
@testable import Fictioneer

@MainActor
struct ChapterComposerTests {
    private func makeChapter() -> Chapter {
        Chapter(title: "The Visitor", scenes: [
            Scene(title: "An Evening Reunion", content: NSAttributedString(string: "He gestured toward my chair.")),
            Scene(title: "Empty"),
            Scene(title: "The Mysterious Communication", content: NSAttributedString(string: "The letter arrived.\nNo stamp.")),
        ])
    }

    private func heading(_ scene: Scene, _ index: Int) -> NSAttributedString {
        NSAttributedString(attachment: NSTextAttachment())
    }

    private func compose(_ chapter: Chapter) -> (ChapterComposer, NSTextStorage) {
        let composer = ChapterComposer(chapter: chapter)
        let storage = NSTextStorage(attributedString: composer.compose(bodyAttributes: [:], heading: heading))
        storage.delegate = composer
        return (composer, storage)
    }

    @Test func rangesCoverEachScenesTextExactly() {
        let chapter = makeChapter()
        let (_, storage) = compose(chapter)
        let ranges = ChapterComposer.sceneRanges(in: storage)
        #expect(ranges.map(\.sceneID) == chapter.scenes.map(\.id))
        for (range, scene) in zip(ranges, chapter.scenes) {
            #expect((storage.string as NSString).substring(with: range.content) == scene.content.string)
        }
    }

    @Test func editsInsideASceneAreAllowedButHeadingsAreProtected() {
        let (_, storage) = compose(makeChapter())
        let ranges = ChapterComposer.sceneRanges(in: storage)
        let first = ranges[0].content
        #expect(ChapterComposer.allowsChange(in: NSRange(location: first.location + 2, length: 3), of: storage))
        // Insertion at the very end of a scene belongs to that scene.
        #expect(ChapterComposer.allowsChange(in: NSRange(location: NSMaxRange(first), length: 0), of: storage))
        // Empty scene: its (empty) text range accepts typing.
        #expect(ChapterComposer.allowsChange(in: NSRange(location: ranges[1].content.location, length: 0), of: storage))
        // Anything spanning into a heading is refused.
        #expect(!ChapterComposer.allowsChange(in: NSRange(location: NSMaxRange(first) - 1, length: 3), of: storage))
        #expect(!ChapterComposer.allowsChange(in: NSRange(location: 0, length: 1), of: storage))
    }

    @Test func syncWritesBackOnlyTouchedScenes() {
        let chapter = makeChapter()
        let (composer, storage) = compose(chapter)
        let third = ChapterComposer.sceneRanges(in: storage)[2].content
        storage.replaceCharacters(in: NSRange(location: NSMaxRange(third), length: 0), with: " Only a crest.")

        let changed = composer.sync(from: storage)
        #expect(changed.map(\.scene.id) == [chapter.scenes[2].id])
        #expect(chapter.scenes[2].content.string == "The letter arrived.\nNo stamp. Only a crest.")
        #expect(chapter.scenes[0].content.string == "He gestured toward my chair.")
        #expect(composer.sync(from: storage).isEmpty)
    }

    @Test func typingIntoAnEmptySceneLandsInThatScene() {
        let chapter = makeChapter()
        let (composer, storage) = compose(chapter)
        let empty = ChapterComposer.sceneRanges(in: storage)[1].content
        // Typing attributes next to a heading would carry its boundary marker.
        let contaminated = NSAttributedString(string: "Night falls.", attributes: [.sceneBoundary: chapter.scenes[0].id.uuidString])
        storage.replaceCharacters(in: NSRange(location: empty.location, length: 0), with: contaminated)

        _ = composer.sync(from: storage)
        #expect(chapter.scenes[1].content.string == "Night falls.")
        #expect(ChapterComposer.sceneRanges(in: storage).count == 3)
    }

    @Test func caretSelectionClampsIntoTheScene() {
        let chapter = makeChapter()
        let (_, storage) = compose(chapter)
        let third = ChapterComposer.sceneRanges(in: storage)[2].content
        #expect(ChapterEditorView.selection(for: (chapter.scenes[2].id, 3), in: storage)?.location == third.location + 3)
        #expect(ChapterEditorView.selection(for: (chapter.scenes[2].id, .max), in: storage)?.location == NSMaxRange(third))
        #expect(ChapterEditorView.selection(for: (UUID(), 0), in: storage) == nil)
    }

    @Test func refreshingHeadingsKeepsTextAndTouchesNoScene() {
        let chapter = makeChapter()
        let (composer, storage) = compose(chapter)
        let before = ChapterComposer.sceneRanges(in: storage)
        let text = storage.string
        let freshAttachment = NSTextAttachment()

        chapter.scenes[1].title = "Renamed"
        composer.refreshHeadings(in: storage) { scene, _ in
            NSAttributedString(attachment: scene.title == "Renamed" ? freshAttachment : NSTextAttachment())
        }

        #expect(storage.string == text)
        #expect(ChapterComposer.sceneRanges(in: storage) == before)
        let headingIndex = before[1].content.location - 2
        #expect(storage.attribute(.attachment, at: headingIndex, effectiveRange: nil) as? NSTextAttachment === freshAttachment)
        #expect(composer.sync(from: storage).isEmpty)
    }

    @Test func sceneAtLocationGivesLocalOffset() {
        let chapter = makeChapter()
        let (_, storage) = compose(chapter)
        let third = ChapterComposer.sceneRanges(in: storage)[2].content
        let hit = ChapterComposer.scene(at: third.location + 4, in: storage)
        #expect(hit?.sceneID == chapter.scenes[2].id)
        #expect(hit?.offset == 4)
    }
}

struct SceneSplitMergeTests {
    private func makeProject() -> (Project, Chapter) {
        let chapter = Chapter(title: "One", scenes: [
            Scene(title: "Opening", content: NSAttributedString(string: "First part.\nSecond part."), status: .revised),
            Scene(title: "Next", content: NSAttributedString(string: "Later.")),
        ])
        return (Project(title: "T", chapters: [chapter]), chapter)
    }

    @Test func splitMovesTextAfterCaretIntoANewSceneAfterIt() throws {
        let (project, chapter) = makeProject()
        let scene = chapter.scenes[0]
        let newScene = try #require(project.splitScene(scene, at: 11))
        #expect(chapter.scenes.map(\.title) == ["Opening", "Opening (continued)", "Next"])
        #expect(scene.content.string == "First part.")
        #expect(newScene.content.string == "Second part.")
        #expect(newScene.status == .revised)
    }

    @Test func mergeAppendsToPreviousAndCarriesBeats() throws {
        let (project, chapter) = makeProject()
        let line = project.addPlotLine()
        project.setBeat("Later beat", scene: chapter.scenes[1], line: line)
        let second = chapter.scenes[1]
        let merged = try #require(project.mergeSceneIntoPrevious(second))
        #expect(chapter.scenes.count == 1)
        #expect(merged.content.string == "First part.\nSecond part.\nLater.")
        #expect(project.beat(scene: merged, line: line) == "Later beat")
    }

    @Test func firstSceneCannotMergeUpward() {
        let (project, chapter) = makeProject()
        #expect(project.mergeSceneIntoPrevious(chapter.scenes[0]) == nil)
        #expect(chapter.scenes.count == 2)
    }
}

/// Through the real text view and RichTextEditor coordinator, as the
/// chapter editor wires it.
@MainActor
struct ChapterEditingIntegrationTests {
    @Test func typingAndDeletingAtASceneHeading() throws {
        let chapter = Chapter(title: "One", scenes: [
            Scene(title: "A", content: NSAttributedString(string: "Alpha.")),
            Scene(title: "B", content: NSAttributedString(string: "Beta.")),
        ])
        let composer = ChapterComposer(chapter: chapter)
        let settings = AppSettings(defaults: UserDefaults(suiteName: "chapter-\(UUID().uuidString)")!)
        let theme = EditorTheme(settings: settings)
        let content = composer.compose(bodyAttributes: theme.bodyAttributes) { scene, index in
            ChapterEditorView.heading(for: scene, isFirst: index == 0, fontSize: theme.fontSize)
        }

        let textView = FictioneerTextView(usingTextLayoutManager: false)
        textView.isRichText = true
        textView.allowsUndo = true
        textView.textStorage?.setAttributedString(content)
        let controller = EditorController()
        controller.textView = textView
        controller.applyTheme(theme)
        let coordinator = RichTextEditor.Coordinator(
            controller: controller,
            shouldChangeText: { range, _, storage in ChapterComposer.allowsChange(in: range, of: storage) }
        ) { content in
            _ = composer.sync(from: content)
        }
        textView.delegate = coordinator
        textView.textStorage?.delegate = composer
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 700, height: 500), styleMask: [.borderless], backing: .buffered, defer: false)
        window.contentView = textView

        let storage = try #require(textView.textStorage)
        let sceneB = ChapterComposer.sceneRanges(in: storage)[1].content

        // Typing at the start of scene B: lands in B with body styling.
        textView.setSelectedRange(NSRange(location: sceneB.location, length: 0))
        textView.insertText("Then ", replacementRange: NSRange(location: NSNotFound, length: 0))
        #expect(chapter.scenes[1].content.string == "Then Beta.")
        let typed = storage.attributes(at: sceneB.location, effectiveRange: nil)
        #expect(typed[.sceneBoundary] == nil)
        #expect((typed[.paragraphStyle] as? NSParagraphStyle)?.alignment != .center)

        // Backspace at the start of B would eat the heading: refused.
        let before = storage.string
        textView.setSelectedRange(NSRange(location: ChapterComposer.sceneRanges(in: storage)[1].content.location, length: 0))
        textView.deleteBackward(nil)
        #expect(storage.string == before)
        #expect(chapter.scenes[0].content.string == "Alpha.")
        #expect(ChapterComposer.sceneRanges(in: storage).count == 2)
    }
}
