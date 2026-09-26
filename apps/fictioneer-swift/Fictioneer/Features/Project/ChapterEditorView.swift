import SwiftUI

/// The writing view. Selecting a scene opens its whole chapter as one
/// continuous document, scrolled to that scene; each scene is opened by a
/// protected heading (break ornament, status, title, details) that can be
/// clicked to edit the scene's details. Edits are written back to the scenes
/// they touch, so saving, word counts and progress stay per scene — see
/// ChapterComposer for the mapping.
struct ChapterEditorView: View {
    @Environment(AppModel.self) private var appModel
    let session: ProjectSession
    let chapter: Chapter

    @State private var controller = EditorController()
    @State private var analysis = AnalysisCoordinator()
    @State private var composer: ChapterComposer
    @State private var detailsPopover = PopoverHolder()
    @State private var rephrasePayload: RephrasePayload?
    @State private var showingPromptSheet = false
    @State private var showingNotesPopover = false
    @State private var isTyping = false
    @State private var typingGeneration = 0

    init(session: ProjectSession, chapter: Chapter) {
        self.session = session
        self.chapter = chapter
        _composer = State(initialValue: ChapterComposer(chapter: chapter))
    }

    /// Rebuilds the view only when the chapter's structure changes (scenes
    /// added, removed or reordered). Title, status and details changes redraw
    /// the headings in place (see `headingSignature`).
    static func identity(of chapter: Chapter) -> String {
        chapter.id.uuidString + chapter.scenes.map(\.id.uuidString).joined(separator: ";")
    }

    /// Everything the scene headings draw; a change redraws them in place.
    private var headingSignature: String {
        chapter.scenes.map { scene in
            [
                scene.title, scene.status.rawValue, scene.synopsis,
                povTitle(for: scene) ?? "", scene.labels.joined(separator: ","),
                scene.targetWords.map(String.init) ?? "",
            ].joined(separator: "|")
        }
        .joined(separator: "\n") + "\(appModel.settings.editorFontSize)"
    }

    private var numeral: String {
        let index = session.project.chapters.firstIndex { $0.id == chapter.id } ?? 0
        return RomanNumeral.format(index + 1)
    }

    /// The scene holding the caret (the sidebar's selection).
    private var caretScene: Scene? {
        session.selectedSceneID.flatMap { id in chapter.scenes.first { $0.id == id } } ?? chapter.scenes.first
    }

    private var dimsParagraphs: Bool {
        session.isFocusMode && appModel.settings.dimsParagraphsInFocusMode
    }

    var body: some View {
        ManuscriptPage {
            if chapter.scenes.isEmpty {
                emptyChapter
            } else {
                editorSurface
            }
        }
        .overlay(alignment: .bottomTrailing) {
            if !session.isFocusMode, let scene = caretScene {
                AnalysisPanelView(
                    analysis: analysis,
                    scene: scene,
                    aiReady: appModel.license.isReadyForSuggestions
                )
                .opacity(isTyping ? 0.3 : 1)
                .animation(.easeOut(duration: 0.4), value: isTyping)
                .onHover { hovering in
                    if hovering { isTyping = false }
                }
                .padding(.trailing, 18)
                .padding(.bottom, 14)
            }
        }
        .overlay(alignment: .bottom) {
            if session.progress.showGoalToast {
                GoalToast()
                    .task {
                        try? await Task.sleep(for: .seconds(3))
                        session.progress.showGoalToast = false
                    }
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                editorToolbar
            }
        }
        // The corner readout dims while typing and returns after a pause.
        .task(id: typingGeneration) {
            guard isTyping else { return }
            try? await Task.sleep(for: .seconds(1.5))
            if !Task.isCancelled { isTyping = false }
        }
        .onChange(of: dimsParagraphs, initial: true) {
            controller.textView?.dimsInactiveParagraphs = dimsParagraphs
        }
        .onChange(of: headingSignature) {
            guard let storage = controller.textView?.textStorage else { return }
            composer.refreshHeadings(in: storage) { scene, index in heading(for: scene, at: index) }
        }
        .onChange(of: session.chapterScrollRequest) {
            guard let sceneID = session.chapterScrollRequest else { return }
            session.chapterScrollRequest = nil
            reveal(sceneID: sceneID, offset: 0)
        }
        .onAppear { session.activeEditor = controller }
        .onDisappear {
            if session.activeEditor === controller { session.activeEditor = nil }
            detailsPopover.close()
        }
        .navigationTitle(caretScene?.title ?? ManuscriptTitle.strippingNumbering(chapter.title))
        .navigationSubtitle("\(numeral). \(ManuscriptTitle.strippingNumbering(chapter.title))")
        .sheet(item: $rephrasePayload) { payload in
            RephraseSheet(payload: payload, controller: controller)
        }
        .sheet(isPresented: $showingPromptSheet) {
            PromptSheet(controller: controller)
        }
    }

    private var emptyChapter: some View {
        VStack(spacing: 10) {
            Text("This chapter has no scenes yet.")
                .foregroundStyle(.secondary)
            Button("Add Scene") {
                session.createScene(in: chapter)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Editor

    private var editorSurface: some View {
        let theme = EditorTheme(settings: appModel.settings)
        let content = composer.compose(bodyAttributes: theme.bodyAttributes) { scene, index in
            heading(for: scene, at: index)
        }
        return RichTextEditor(
            initialContent: content,
            settings: appModel.settings,
            controller: controller,
            configureGhost: { textView, editorController in
                configure(textView, editorController)
            },
            shouldChangeText: { range, replacement, storage in
                if ChapterComposer.allowsChange(in: range, of: storage) { return true }
                offerMergeIfBackspacingAtBreak(range: range, replacement: replacement, storage: storage)
                return false
            },
            initialSelection: { [weak session] in
                guard let session, let storage = controller.textView?.textStorage else { return nil }
                session.chapterScrollRequest = nil
                // Where the writer was (after a rebuild), unless another scene
                // was selected meanwhile (e.g. a scene just added): then the
                // start of that scene.
                if let caret = session.chapterCaret, caret.sceneID == session.selectedSceneID,
                   let selection = Self.selection(for: caret, in: storage) {
                    return selection
                }
                if let sceneID = session.selectedSceneID {
                    return Self.selection(for: (sceneID, 0), in: storage)
                }
                return nil
            },
            onAttachmentClick: { charIndex, frame in
                showDetails(at: charIndex, frame: frame)
            }
        ) { content in
            for change in composer.sync(from: content) {
                session.progress.recordEdit(
                    totalWords: session.project.totalWordCount,
                    wordDelta: abs(change.scene.wordCount - change.previousWords),
                    characterDelta: abs(change.scene.characterCount - change.previousCharacters)
                )
                session.markDirty(sceneID: change.scene.id)
            }
            analysis.contentDidChange(content.string, noteCandidates: noteCandidates)
            isTyping = true
            typingGeneration += 1
        }
    }

    /// Lightweight (id, tags) view of the notes for mention matching.
    private var noteCandidates: [NoteMatcher.Candidate] {
        session.project.notes.map { NoteMatcher.Candidate(id: $0.id, tags: $0.tags) }
    }

    /// Notes mentioned in this chapter, in project order.
    private var matchingNotes: [Note] {
        guard !analysis.matchingNoteIDs.isEmpty else { return [] }
        let ids = Set(analysis.matchingNoteIDs)
        return session.project.notes.filter { ids.contains($0.id) }
    }

    private func configure(_ textView: FictioneerTextView, _ editorController: EditorController) {
        let settings = appModel.settings
        let license = appModel.license
        // Attached after the initial load and theming, so only real edits
        // mark scenes as touched.
        textView.textStorage?.delegate = composer

        let ghostController = GhostTextController { content, context in
            IntelligenceClient(baseURL: settings.intelligenceBaseURL, licenseKey: settings.licenseKey)
                .continueWriting(content: content, context: context)
        }
        editorController.ghostPresenter = GhostTextPresenter(
            textView: textView,
            editorController: editorController,
            controller: ghostController,
            isEnabled: { license.isReadyForSuggestions },
            contextInfo: { [weak session] in
                (session?.selectedSceneID.flatMap { session?.project.scene(withID: $0) }?.title,
                 session?.project.details.isEmpty == false ? session?.project.details : nil)
            }
        )
        analysis.attach(editorController: editorController, settings: settings, noteCandidates: noteCandidates)
        textView.quoteStyle = { [weak session] in session?.project.effectiveQuoteStyle }
        textView.dimsInactiveParagraphs = dimsParagraphs
        textView.onEscape = { [weak session] in
            guard let session, session.isFocusMode else { return false }
            session.isFocusMode = false
            return true
        }
        textView.pageHeaderView = ChapterHeaderHostingView(
            rootView: ChapterPageHeader(session: session, chapter: chapter, numeral: numeral, settings: settings)
        )

        // Selection bar: formatting, plus "✦ Rephrase" when AI is available.
        let payloadBinding = $rephrasePayload
        editorController.attachSelectionBar(to: textView) { [weak editorController] in
            guard let editorController else { return [] }
            var items = editorController.formattingBarItems()
            if license.isReadyForSuggestions {
                items.append(SelectionBarItem(
                    id: "rephrase",
                    label: "Rephrase selection — five AI alternatives",
                    systemImage: "sparkles",
                    title: "Rephrase",
                    isAccent: true
                ) { [weak editorController] in
                    guard let context = editorController?.selectionContext() else { return }
                    payloadBinding.wrappedValue = RephrasePayload(
                        selected: context.selected,
                        before: context.before,
                        after: context.after
                    )
                })
            }
            return items
        }

        // The caret's scene: highlighted in the sidebar, titled in the
        // window, restored on rebuild.
        editorController.selectionChangeObservers.append { [weak textView, weak session] in
            guard let textView, let session, let storage = textView.textStorage,
                  let hit = ChapterComposer.scene(at: textView.selectedRange().location, in: storage) else { return }
            session.chapterCaret = hit
            if session.selectedSceneID != hit.sceneID {
                session.selectedSceneID = hit.sceneID
            }
        }

        editorController.onSplitScene = { [weak textView, weak session, composer] in
            guard let textView, let session, let storage = textView.textStorage,
                  !editorController.isGhostActive,
                  let location = ChapterComposer.scene(at: textView.selectedRange().location, in: storage),
                  let scene = session.project.scene(withID: location.sceneID) else { return }
            // Flush pending edits so the split sees the current text.
            for change in composer.sync(from: storage.strippingTransientAttributes()) {
                session.markDirty(sceneID: change.scene.id)
            }
            guard let newScene = session.project.splitScene(scene, at: location.offset) else { return }
            session.markDirty(sceneID: scene.id)
            session.markDirty(sceneID: newScene.id)
            // The view rebuilds for the new scene; continue writing at its start.
            session.chapterCaret = (newScene.id, 0)
            session.selectedSceneID = newScene.id
        }
    }

    // MARK: - Toolbar

    @ViewBuilder
    private var editorToolbar: some View {
        Menu {
            ParagraphStyleButtons(controller: controller)
        } label: {
            Label("Paragraph Style", systemImage: "paragraphsign")
        }
        .help("Paragraph style")

        Button {
            analysis.setHighlightsEnabled(!analysis.highlightsEnabled)
        } label: {
            Label("Prose Highlights", systemImage: "textformat.abc.dottedunderline")
        }
        .foregroundStyle(analysis.highlightsEnabled ? Color.accentColor : Color.secondary)
        .help("Prose highlights — flag adverbs, passive voice, clichés and more")
        .accessibilityValue(analysis.highlightsEnabled ? "On" : "Off")

        Menu {
            Button("Prompt…") {
                showingPromptSheet = true
            }
            Button("Rephrase Selection…") {
                guard let context = controller.selectionContext() else { return }
                rephrasePayload = RephrasePayload(
                    selected: context.selected,
                    before: context.before,
                    after: context.after
                )
            }
            .disabled(!controller.hasSelection)
            Divider()
            Text("Hold ⌥ in the text for a continuation")
        } label: {
            Label("AI", systemImage: "sparkles")
        }
        .disabled(!appModel.license.isReadyForSuggestions)
        .help(appModel.license.isReadyForSuggestions
            ? "AI prompt and rephrasing"
            : "AI needs a license — Settings ▸ AI")

        if !matchingNotes.isEmpty {
            Button {
                showingNotesPopover = true
            } label: {
                Label("\(matchingNotes.count) Notes", systemImage: "note.text")
                    .labelStyle(.titleAndIcon)
            }
            .help("Notes mentioned in this chapter")
            .accessibilityLabel("Notes mentioned in this chapter")
            .accessibilityValue("\(matchingNotes.count)")
            .popover(isPresented: $showingNotesPopover, arrowEdge: .bottom) {
                NotesInChapterList(notes: matchingNotes) { note in
                    session.selectedItem = .note(note.id)
                    showingNotesPopover = false
                }
            }
        }
    }

    // MARK: - Caret, scrolling, details, merging

    static func selection(for caret: (sceneID: UUID, offset: Int), in text: NSAttributedString) -> NSRange? {
        guard let range = ChapterComposer.sceneRanges(in: text).first(where: { $0.sceneID == caret.sceneID }) else {
            return nil
        }
        return NSRange(location: range.content.location + min(max(caret.offset, 0), range.content.length), length: 0)
    }

    private func reveal(sceneID: UUID, offset: Int) {
        guard let textView = controller.textView, let storage = textView.textStorage,
              let selection = Self.selection(for: (sceneID, offset), in: storage) else { return }
        textView.window?.makeFirstResponder(textView)
        textView.setSelectedRange(selection)
        textView.centerCaret()
    }

    /// Clicking a scene heading opens that scene's details (title, synopsis,
    /// status, point of view, labels, target).
    private func showDetails(at charIndex: Int, frame: NSRect) {
        guard let textView = controller.textView, let storage = textView.textStorage,
              charIndex < storage.length,
              let id = (storage.attribute(.sceneBoundary, at: charIndex, effectiveRange: nil) as? String)
                .flatMap(UUID.init(uuidString:)),
              let scene = session.project.scene(withID: id) else { return }
        detailsPopover.show(
            SceneDetailsEditor(session: session, scene: scene, showsTitle: true),
            relativeTo: frame,
            of: textView
        )
    }

    /// Backspace at the start of a scene would delete the break before it:
    /// offer to merge the two scenes instead.
    private func offerMergeIfBackspacingAtBreak(range: NSRange, replacement: String?, storage: NSAttributedString) {
        guard replacement?.isEmpty == true, range.length == 1 else { return }
        let ranges = ChapterComposer.sceneRanges(in: storage)
        guard let index = ranges.firstIndex(where: { $0.content.location == NSMaxRange(range) }), index > 0,
              let scene = session.project.scene(withID: ranges[index].sceneID),
              let previous = session.project.scene(withID: ranges[index - 1].sceneID),
              let window = controller.textView?.window else { return }
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = "Merge “\(scene.title)” into “\(previous.title)”?"
            alert.informativeText = "The two scenes become one. “\(scene.title)”'s synopsis and labels are dropped; its plot grid beats move to “\(previous.title)”."
            alert.addButton(withTitle: "Merge Scenes")
            alert.addButton(withTitle: "Cancel")
            alert.beginSheetModal(for: window) { response in
                guard response == .alertFirstButtonReturn else { return }
                MainActor.assumeIsolated {
                    merge(scene, into: previous)
                }
            }
        }
    }

    private func merge(_ scene: Scene, into previous: Scene) {
        if let storage = controller.textView?.textStorage {
            for change in composer.sync(from: storage.strippingTransientAttributes()) {
                session.markDirty(sceneID: change.scene.id)
            }
        }
        let joinOffset = previous.content.length
        guard let merged = session.project.mergeSceneIntoPrevious(scene) else { return }
        session.markDirty(sceneID: merged.id)
        // The view rebuilds without the merged scene; keep writing at the join.
        session.chapterCaret = (merged.id, joinOffset)
        session.selectedSceneID = merged.id
    }

    // MARK: - Scene headings

    private func povTitle(for scene: Scene) -> String? {
        scene.povNoteID.flatMap { session.project.note(withID: $0) }?.title
    }

    private func heading(for scene: Scene, at index: Int) -> NSAttributedString {
        Self.heading(
            for: scene,
            isFirst: index == 0,
            fontSize: CGFloat(appModel.settings.editorFontSize),
            povTitle: povTitle(for: scene)
        )
    }

    /// The protected heading that opens each scene: a break ornament (not
    /// before the first scene), status dot and title in small caps, a line
    /// of details, and the synopsis. Drawn as one attachment image.
    static func heading(for scene: Scene, isFirst: Bool, fontSize: CGFloat, povTitle: String? = nil) -> NSAttributedString {
        let width: CGFloat = 460
        let centered = NSMutableParagraphStyle()
        centered.alignment = .center

        let title = NSAttributedString(string: scene.title.uppercased(), attributes: [
            .font: NSFont(name: "Quattrocento-Bold", size: 11) ?? .boldSystemFont(ofSize: 11),
            .kern: 1.8,
            .foregroundColor: NSColor.secondaryLabelColor,
        ])
        let ornament = NSAttributedString(string: "*   *   *", attributes: [
            .font: NSFont.systemFont(ofSize: 12),
            .foregroundColor: NSColor.tertiaryLabelColor,
            .paragraphStyle: centered,
        ])
        var metaParts: [String] = [scene.status.title]
        if let povTitle { metaParts.append(povTitle) }
        if !scene.labels.isEmpty { metaParts.append(scene.labels.joined(separator: ", ")) }
        if let target = scene.targetWords, target > 0 { metaParts.append("target \(target.formatted()) words") }
        let meta = NSAttributedString(string: metaParts.joined(separator: "  ·  "), attributes: [
            .font: NSFont.systemFont(ofSize: 10.5),
            .foregroundColor: NSColor.tertiaryLabelColor,
            .paragraphStyle: centered,
        ])
        let synopsisFont = NSFont(name: "Quattrocento", size: 13) ?? .systemFont(ofSize: 13)
        let synopsis = NSAttributedString(
            string: scene.synopsis.isEmpty ? "Add a synopsis" : scene.synopsis,
            attributes: [
                .font: NSFontManager.shared.convert(synopsisFont, toHaveTrait: .italicFontMask),
                .foregroundColor: scene.synopsis.isEmpty ? NSColor.quaternaryLabelColor : NSColor.secondaryLabelColor,
                .paragraphStyle: centered,
            ]
        )

        let textWidth = width - 40
        let ornamentHeight: CGFloat = isFirst ? 0 : 30
        let titleSize = title.size()
        let metaHeight = ceil(meta.boundingRect(with: NSSize(width: textWidth, height: 40), options: [.usesLineFragmentOrigin]).height)
        let synopsisLineHeight = ceil(synopsisFont.ascender - synopsisFont.descender + synopsisFont.leading)
        let synopsisHeight = min(
            ceil(synopsis.boundingRect(with: NSSize(width: textWidth, height: 400), options: [.usesLineFragmentOrigin]).height),
            synopsisLineHeight * 3
        )
        let titleY = ornamentHeight
        let metaY = titleY + ceil(titleSize.height) + 4
        let synopsisY = metaY + metaHeight + 6
        let size = NSSize(width: width, height: synopsisY + synopsisHeight + 2)

        let dotColor = NSColor(scene.status.color)
        let isIdea = scene.status == .idea
        let image = NSImage(size: size, flipped: true) { rect in
            if !isFirst {
                ornament.draw(with: NSRect(x: 0, y: 4, width: rect.width, height: 20), options: [.usesLineFragmentOrigin])
            }
            let dotSize: CGFloat = 6
            let lineWidth = dotSize + 8 + titleSize.width
            let x = (rect.width - lineWidth) / 2
            let dotRect = NSRect(x: x, y: titleY + (titleSize.height - dotSize) / 2, width: dotSize, height: dotSize)
            let dot = NSBezierPath(ovalIn: isIdea ? dotRect.insetBy(dx: 0.6, dy: 0.6) : dotRect)
            if isIdea {
                dotColor.setStroke()
                dot.lineWidth = 1.2
                dot.stroke()
            } else {
                dotColor.setFill()
                dot.fill()
            }
            title.draw(at: NSPoint(x: x + dotSize + 8, y: titleY))
            meta.draw(with: NSRect(x: 20, y: metaY, width: textWidth, height: metaHeight), options: [.usesLineFragmentOrigin])
            synopsis.draw(
                with: NSRect(x: 20, y: synopsisY, width: textWidth, height: synopsisHeight),
                options: [.usesLineFragmentOrigin, .truncatesLastVisibleLine]
            )
            return true
        }
        image.accessibilityDescription = "Scene \(scene.title), \(metaParts.joined(separator: ", ")). Click to edit details."

        let attachment = NSTextAttachment()
        attachment.image = image
        attachment.bounds = NSRect(origin: .zero, size: size)

        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        paragraph.paragraphSpacingBefore = isFirst ? 0 : fontSize * 1.2
        paragraph.paragraphSpacing = fontSize * 0.9
        let heading = NSMutableAttributedString(attachment: attachment)
        heading.addAttribute(.paragraphStyle, value: paragraph, range: NSRange(location: 0, length: heading.length))
        return heading
    }
}

/// Keeps the scene-details popover alive while it's shown.
@MainActor
private final class PopoverHolder {
    private var popover: NSPopover?

    func show<Content: View>(_ content: Content, relativeTo rect: NSRect, of view: NSView) {
        close()
        let popover = NSPopover()
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(rootView: content)
        popover.show(relativeTo: rect, of: view, preferredEdge: .maxY)
        self.popover = popover
    }

    func close() {
        popover?.close()
        popover = nil
    }
}

/// Chapter eyebrow and editable title above the first scene.
private struct ChapterPageHeader: View {
    let session: ProjectSession
    let chapter: Chapter
    let numeral: String
    let settings: AppSettings

    private var title: Binding<String> {
        Binding(
            get: { chapter.title },
            set: { newValue in
                chapter.title = newValue
                chapter.updatedAt = .now
                session.markDirty()
            }
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ManuscriptLabel("Chapter \(numeral)", size: 10, color: .secondary)
            TextField("Untitled Chapter", text: title)
                .textFieldStyle(.plain)
                .font(.custom("Quattrocento-Bold", size: (CGFloat(settings.editorFontSize) * 1.9).rounded()))
                .accessibilityLabel("Chapter title")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// Re-lays out the text view whenever the header's size changes.
private final class ChapterHeaderHostingView<Content: View>: NSHostingView<Content> {
    override func invalidateIntrinsicContentSize() {
        super.invalidateIntrinsicContentSize()
        (superview as? FictioneerTextView)?.layoutPageHeader()
    }
}

/// Popover content for the toolbar's notes button: note titles that
/// navigate on click.
private struct NotesInChapterList: View {
    let notes: [Note]
    let onSelect: (Note) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            ManuscriptLabel("Notes in this chapter")
                .padding(.bottom, 4)
            ForEach(notes, id: \.id) { note in
                Button {
                    onSelect(note)
                } label: {
                    Text(note.title)
                        .font(.custom("Quattrocento-Bold", size: 13))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .padding(.vertical, 3)
            }
        }
        .padding(12)
        .frame(minWidth: 220, alignment: .leading)
    }
}
