import SwiftUI

struct SceneEditorView: View {
    @Environment(AppModel.self) private var appModel
    let session: ProjectSession
    let scene: Scene

    @State private var controller = EditorController()
    @State private var analysis = AnalysisCoordinator()
    @State private var rephrasePayload: RephrasePayload?
    @State private var showingPromptSheet = false
    @State private var showingNotesPopover = false
    @State private var isTyping = false
    @State private var typingGeneration = 0

    var body: some View {
        ManuscriptPage {
            editorSurface
        }
        .overlay(alignment: .bottomTrailing) {
            if !session.isFocusMode {
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
                sceneToolbar
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
        .onAppear { session.activeEditor = controller }
        .onDisappear {
            if session.activeEditor === controller { session.activeEditor = nil }
        }
        .navigationTitle(scene.title)
        .navigationSubtitle(session.project.chapter(containing: scene.id)?.title ?? "")
        .sheet(item: $rephrasePayload) { payload in
            RephraseSheet(payload: payload, controller: controller)
        }
        .sheet(isPresented: $showingPromptSheet) {
            PromptSheet(controller: controller)
        }
    }

    private var editorSurface: some View {
        RichTextEditor(
                initialContent: scene.content,
                settings: appModel.settings,
                controller: controller,
                configureGhost: { textView, editorController in
                    let settings = appModel.settings
                    let license = appModel.license
                    let ghostController = GhostTextController { content, context in
                        IntelligenceClient(
                            baseURL: settings.intelligenceBaseURL,
                            licenseKey: settings.licenseKey
                        )
                        .continueWriting(content: content, context: context)
                    }
                    editorController.ghostPresenter = GhostTextPresenter(
                        textView: textView,
                        editorController: editorController,
                        controller: ghostController,
                        isEnabled: { license.isReadyForSuggestions },
                        contextInfo: { [weak scene, weak session] in
                            (scene?.title, session?.project.details.isEmpty == false ? session?.project.details : nil)
                        }
                    )
                    analysis.attach(editorController: editorController, settings: settings, noteCandidates: noteCandidates)
                    textView.quoteStyle = { [weak session] in session?.project.effectiveQuoteStyle }
                    textView.dimsInactiveParagraphs = dimsParagraphs
                    textView.pageHeaderView = PageHeaderHostingView(
                        rootView: ScenePageHeader(
                            session: session,
                            scene: scene,
                            settings: settings,
                            onSubmit: { [weak textView] in
                                textView?.window?.makeFirstResponder(textView)
                            }
                        )
                    )
                    textView.onEscape = { [weak session] in
                        guard let session, session.isFocusMode else { return false }
                        session.isFocusMode = false
                        return true
                    }

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
                }
            ) { content in
                let previousWords = scene.wordCount
                let previousCharacters = scene.characterCount
                scene.updateContent(content)
                session.progress.recordEdit(
                    totalWords: session.project.totalWordCount,
                    wordDelta: abs(scene.wordCount - previousWords),
                    characterDelta: abs(scene.characterCount - previousCharacters)
                )
                session.markDirty(sceneID: scene.id)
                analysis.contentDidChange(content.string, noteCandidates: noteCandidates)
                isTyping = true
                typingGeneration += 1
            }
    }

    private var dimsParagraphs: Bool {
        session.isFocusMode && appModel.settings.dimsParagraphsInFocusMode
    }

    /// Lightweight (id, tags) view of `session.project.notes` — decouples the
    /// editor's analysis coordinator from the `Note` model/persistence layer.
    private var noteCandidates: [NoteMatcher.Candidate] {
        session.project.notes.map { NoteMatcher.Candidate(id: $0.id, tags: $0.tags) }
    }

    /// The notes matched on the current analysis pass, in project order.
    private var matchingNotes: [Note] {
        guard !analysis.matchingNoteIDs.isEmpty else { return [] }
        let ids = Set(analysis.matchingNoteIDs)
        return session.project.notes.filter { ids.contains($0.id) }
    }

    /// The scene's few persistent actions, in the window toolbar. Character
    /// formatting lives in the Format menu (and its shortcuts); undo/redo in
    /// the Edit menu.
    @ViewBuilder
    private var sceneToolbar: some View {
        blockStyleMenu

        Button {
            analysis.setHighlightsEnabled(!analysis.highlightsEnabled)
        } label: {
            Label("Prose Highlights", systemImage: "textformat.abc.dottedunderline")
        }
        .foregroundStyle(analysis.highlightsEnabled ? Color.accentColor : Color.secondary)
        .help("Prose highlights — flag adverbs, passive voice, clichés and more")
        .accessibilityValue(analysis.highlightsEnabled ? "On" : "Off")

        aiMenu

        if !matchingNotes.isEmpty {
            Button {
                showingNotesPopover = true
            } label: {
                Label("\(matchingNotes.count) Notes", systemImage: "note.text")
                    .labelStyle(.titleAndIcon)
            }
            .help("Notes mentioned in this scene")
            .accessibilityLabel("Notes mentioned in this scene")
            .accessibilityValue("\(matchingNotes.count)")
            .popover(isPresented: $showingNotesPopover, arrowEdge: .bottom) {
                NotesInSceneList(notes: matchingNotes) { note in
                    session.selectedItem = .note(note.id)
                    showingNotesPopover = false
                }
            }
        }
    }

    private var aiMenu: some View {
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
    }

    private var blockStyleMenu: some View {
        Menu {
            ParagraphStyleButtons(controller: controller)
        } label: {
            Label("Paragraph Style", systemImage: "paragraphsign")
        }
        .help("Paragraph style")
    }
}

/// Popover content for the toolbar's "notes in this scene" button —
/// a quiet list of note titles, Manuscript-styled, that navigates on click.
private struct NotesInSceneList: View {
    let notes: [Note]
    let onSelect: (Note) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            ManuscriptLabel("Notes in this scene")
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

/// The scene's heading on the page: chapter eyebrow and the scene title,
/// editable in place. Hosted inside the text view (see `pageHeaderView`) so
/// it scrolls with the prose.
private struct ScenePageHeader: View {
    let session: ProjectSession
    let scene: Scene
    let settings: AppSettings
    let onSubmit: () -> Void

    private var eyebrow: String? {
        let project = session.project
        guard let chapter = project.chapter(containing: scene.id),
              let index = project.chapters.firstIndex(where: { $0.id == chapter.id }) else { return nil }
        return "\(RomanNumeral.format(index + 1)) · \(ManuscriptTitle.strippingNumbering(chapter.title))"
    }

    private var title: Binding<String> {
        Binding(
            get: { scene.title },
            set: { newValue in
                scene.title = newValue
                scene.updatedAt = .now
                session.markDirty()
            }
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let eyebrow {
                ManuscriptLabel(eyebrow, size: 10, color: .secondary)
            }
            TextField("Untitled Scene", text: title)
                .textFieldStyle(.plain)
                .font(.custom("Quattrocento-Bold", size: (CGFloat(settings.editorFontSize) * 1.6).rounded()))
                .onSubmit(onSubmit)
                .accessibilityLabel("Scene title")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// Re-lays out the text view whenever the header's size changes (font size
/// setting, chapter renamed), so the prose always starts below it.
private final class PageHeaderHostingView<Content: View>: NSHostingView<Content> {
    override func invalidateIntrinsicContentSize() {
        super.invalidateIntrinsicContentSize()
        (superview as? FictioneerTextView)?.layoutPageHeader()
    }
}
