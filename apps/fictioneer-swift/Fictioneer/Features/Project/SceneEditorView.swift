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
        .background(VisualEffectView().ignoresSafeArea())
        .overlay(alignment: .bottomTrailing) {
            if !session.isFocusMode {
                AnalysisPanelView(
                    analysis: analysis,
                    scene: scene,
                    aiReady: appModel.license.isReadyForSuggestions
                )
            }
        }
        .overlay(alignment: .top) {
            if !session.isFocusMode {
                floatingToolbar
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
        .navigationTitle(scene.title)
        .navigationSubtitle(session.project.chapter(containing: scene.id)?.title ?? "")
        .sheet(item: $rephrasePayload) { payload in
            RephraseSheet(payload: payload, controller: controller)
        }
        .sheet(isPresented: $showingPromptSheet) {
            PromptSheet(controller: controller)
        }
    }

    /// Floating format bar over the writing surface — layout borrowed from the
    /// Tauri app's editor pill, rendered with native materials.
    private var floatingToolbar: some View {
        HStack(spacing: 2) {
            formatButton("arrow.uturn.backward", "Undo — ⌘Z") { controller.undo() }
            formatButton("arrow.uturn.forward", "Redo — ⇧⌘Z") { controller.redo() }
            toolbarDivider
            blockStyleMenu
                .menuStyle(.borderlessButton)
                .fixedSize()
                .hoverTip("Paragraph style")
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
                    .frame(width: 24, height: 22)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.borderless)
            .disabled(!controller.hasSelection || !appModel.license.isReadyForSuggestions)
            .hoverTip("Rephrase selection — five AI alternatives")

            Button {
                showingPromptSheet = true
            } label: {
                Image(systemName: "sparkles")
                    .frame(width: 24, height: 22)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.borderless)
            .disabled(!appModel.license.isReadyForSuggestions)
            .hoverTip("AI Prompt — generate and insert at the caret")

            Button {
                analysis.setHighlightsEnabled(!analysis.highlightsEnabled)
            } label: {
                Image(systemName: "textformat.abc.dottedunderline")
                    .frame(width: 24, height: 22)
                    .contentShape(Rectangle())
                    .foregroundStyle(analysis.highlightsEnabled ? Color.accentColor : Color.primary)
            }
            .buttonStyle(.borderless)
            .hoverTip("Prose highlights — flag adverbs, passive voice, clichés and more")
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(.separator)
        )
        .shadow(color: .black.opacity(0.12), radius: 8, y: 2)
        .padding(.top, 10)
        // The NSTextView beneath owns an I-beam cursor rect for this whole
        // region; keep forcing the arrow while the pointer is over the pill.
        .onContinuousHover { phase in
            if case .active = phase {
                NSCursor.arrow.set()
            }
        }
    }

    private var toolbarDivider: some View {
        Divider()
            .frame(height: 16)
            .padding(.horizontal, 4)
    }

    private var blockStyleMenu: some View {
        Menu {
            Button("Body Text") { controller.applyBlockStyle(.body) }
            Divider()
            Button("Heading 1") { controller.applyBlockStyle(.heading(1)) }
            Button("Heading 2") { controller.applyBlockStyle(.heading(2)) }
            Button("Heading 3") { controller.applyBlockStyle(.heading(3)) }
            Divider()
            Button("Blockquote") { controller.applyBlockStyle(.blockquote) }
        } label: {
            Label("Paragraph Style", systemImage: "paragraphsign")
        }
    }

    private func formatButton(_ icon: String, _ tip: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .frame(width: 24, height: 22)
                .contentShape(Rectangle())
        }
        .buttonStyle(.borderless)
        .hoverTip(tip)
    }

}
