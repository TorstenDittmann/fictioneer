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

    var body: some View {
        ManuscriptPage(header: pageHeader, isChromeless: session.isFocusMode) {
            if !session.isFocusMode {
                headControls
            }
        } content: {
            VStack(spacing: 0) {
                editorSurface
                if !session.isFocusMode {
                    Divider()
                    AnalysisPanelView(
                        analysis: analysis,
                        scene: scene,
                        aiReady: appModel.license.isReadyForSuggestions
                    )
                }
            }
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
                    analysis.attach(editorController: editorController, settings: settings, noteCandidates: noteCandidates)
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
                analysis.contentDidChange(content.string, noteCandidates: noteCandidates)
            }
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
            .accessibilityLabel("Rephrase selection")
            .accessibilityHint("Five AI alternatives")

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
            .accessibilityLabel("AI Prompt")
            .accessibilityHint("Generate and insert at the caret")

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
            .accessibilityLabel("Prose highlights")
            .accessibilityHint("Flag adverbs, passive voice, clichés and more")
            .accessibilityValue(analysis.highlightsEnabled ? "On" : "Off")

            if !matchingNotes.isEmpty {
                toolbarDivider
                Button {
                    showingNotesPopover = true
                } label: {
                    HStack(spacing: 3) {
                        Image(systemName: "note.text")
                        Text("\(matchingNotes.count)")
                            .font(.caption2)
                            .monospacedDigit()
                    }
                    .frame(height: 18)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.borderless)
                .hoverTip("Notes mentioned in this scene")
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
        .accessibilityLabel("Paragraph style")
    }

    /// Splits a hover-tip string of the form "Label — Hint" (used throughout
    /// the toolbar) into VoiceOver's separate label/hint pair, so the
    /// keyboard-shortcut suffix reads as a hint rather than part of the name.
    private func accessibilityParts(for tip: String) -> (label: String, hint: String?) {
        guard let range = tip.range(of: " — ") else { return (tip, nil) }
        return (String(tip[..<range.lowerBound]), String(tip[range.upperBound...]))
    }

    @ViewBuilder
    private func formatButton(_ icon: String, _ tip: String, action: @escaping () -> Void) -> some View {
        let parts = accessibilityParts(for: tip)
        let button = Button(action: action) {
            Image(systemName: icon)
                .frame(width: 20, height: 18)
                .contentShape(Rectangle())
        }
        .buttonStyle(.borderless)
        .hoverTip(tip)
        .accessibilityLabel(parts.label)

        if let hint = parts.hint {
            button.accessibilityHint(hint)
        } else {
            button
        }
    }

}

/// Popover content for the running head's "notes in this scene" indicator —
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
