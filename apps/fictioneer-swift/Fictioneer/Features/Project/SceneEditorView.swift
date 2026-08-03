import SwiftUI

struct SceneEditorView: View {
    @Environment(AppModel.self) private var appModel
    let session: ProjectSession
    let scene: Scene

    @State private var controller = EditorController()
    @State private var analysis = AnalysisCoordinator()
    @State private var rephrasePayload: RephrasePayload?
    @State private var showingPromptSheet = false

    var body: some View {
        ManuscriptPage(header: pageHeader) {
            if !session.isFocusMode {
                headControls
            }
        } content: {
            editorSurface
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(VisualEffectView().ignoresSafeArea())
        .overlay(alignment: .bottom) {
            if session.progress.showGoalToast {
                GoalToast()
                    .task {
                        try? await Task.sleep(for: .seconds(3))
                        session.progress.showGoalToast = false
                    }
            }
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

    private var pageHeader: ManuscriptPageHeader {
        let chapter = session.project.chapter(containing: scene.id)
        let numeral = chapter
            .flatMap { chapter in session.project.chapters.firstIndex { $0.id == chapter.id } }
            .map { RomanNumeral.format($0 + 1) }
        return ManuscriptPageHeader(
            project: session.project.title,
            section: numeral,
            title: scene.title
        )
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
                    analysis.attach(editorController: editorController, settings: settings)
                    textView.onEscape = { [weak session] in
                        guard let session, session.isFocusMode else { return false }
                        session.isFocusMode = false
                        return true
                    }

                    // Selection action bar: "✦ Rephrase" appears above a
                    // stabilized selection when AI is available.
                    let payloadBinding = $rephrasePayload
                    textView.selectionBarIsEnabled = { license.isReadyForSuggestions }
                    textView.onSelectionBarAction = { [weak editorController] in
                        guard let context = editorController?.selectionContext() else { return }
                        payloadBinding.wrappedValue = RephrasePayload(
                            selected: context.selected,
                            before: context.before,
                            after: context.after
                        )
                    }
                    editorController.selectionChangeObservers.append { [weak textView] in
                        textView?.scheduleSelectionBarUpdate()
                    }
                    editorController.documentEditObservers.append { [weak textView] in
                        textView?.dismissSelectionBar()
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
                analysis.contentDidChange(content.string)
            }
        .overlay(alignment: .bottomTrailing) {
            if !session.isFocusMode {
                AnalysisPanelView(
                    analysis: analysis,
                    scene: scene,
                    aiReady: appModel.license.isReadyForSuggestions
                )
            }
        }
    }

    /// The running head doubles as the toolbar: chromeless icons at its
    /// trailing edge — no floating box over the prose.
    private var headControls: some View {
        HStack(spacing: 1) {
            formatButton("arrow.uturn.backward", "Undo — ⌘Z") { controller.undo() }
            formatButton("arrow.uturn.forward", "Redo — ⇧⌘Z") { controller.redo() }
            toolbarDivider
            blockStyleMenu
                .menuStyle(.borderlessButton)
            toolbarDivider
            formatButton("bold", "Bold — ⌘B") { controller.toggleBold() }
                .keyboardShortcut("b", modifiers: .command)
            formatButton("italic", "Italic — ⌘I") { controller.toggleItalic() }
                .keyboardShortcut("i", modifiers: .command)
            formatButton("underline", "Underline — ⌘U") { controller.toggleUnderline() }
                .keyboardShortcut("u", modifiers: .command)
            formatButton("strikethrough", "Strikethrough — ⇧⌘X") { controller.toggleStrikethrough() }
                .keyboardShortcut("x", modifiers: [.command, .shift])
            toolbarDivider
            Button {
                if let context = controller.selectionContext() {
                    rephrasePayload = RephrasePayload(
                        selected: context.selected,
                        before: context.before,
                        after: context.after
                    )
                }
            } label: {
                Image(systemName: "arrow.2.squarepath")
                    .frame(width: 20, height: 18)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.borderless)
            .disabled(!controller.hasSelection || !appModel.license.isReadyForSuggestions)
            .hoverTip("Rephrase selection — five AI alternatives")

            Button {
                showingPromptSheet = true
            } label: {
                Image(systemName: "sparkles")
                    .frame(width: 20, height: 18)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.borderless)
            .disabled(!appModel.license.isReadyForSuggestions)
            .hoverTip("AI Prompt — generate and insert at the caret")

            Button {
                analysis.setHighlightsEnabled(!analysis.highlightsEnabled)
            } label: {
                Image(systemName: "textformat.abc.dottedunderline")
                    .frame(width: 20, height: 18)
                    .contentShape(Rectangle())
                    .foregroundStyle(analysis.highlightsEnabled ? Color.accentColor : Color.secondary)
            }
            .buttonStyle(.borderless)
            .hoverTip("Prose highlights — flag adverbs, passive voice, clichés and more")
        }
        .imageScale(.small)
        .foregroundStyle(.secondary)
    }

    private var toolbarDivider: some View {
        Divider()
            .frame(height: 12)
            .padding(.horizontal, 3)
    }

    private var blockStyleMenu: some View {
        Menu {
            Button("Body Text") { controller.applyBlockStyle(.body) }
            Divider()
            Button("Heading 1") { controller.applyBlockStyle(.heading(1)) }
            Divider()
            Button("Heading 2") { controller.applyBlockStyle(.heading(2)) }
            Button("Heading 3") { controller.applyBlockStyle(.heading(3)) }
            Divider()
            Button("Blockquote") { controller.applyBlockStyle(.blockquote) }
        } label: {
            Image(systemName: "paragraphsign")
                .frame(width: 20, height: 18)
                .contentShape(Rectangle())
        }
        .menuIndicator(.hidden)
        .fixedSize()
        .hoverTip("Paragraph style")
    }

    private func formatButton(_ icon: String, _ tip: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .frame(width: 20, height: 18)
                .contentShape(Rectangle())
        }
        .buttonStyle(.borderless)
        .hoverTip(tip)
    }

}
