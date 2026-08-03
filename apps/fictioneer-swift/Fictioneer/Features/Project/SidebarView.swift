import SwiftUI

struct SidebarView: View {
    let session: ProjectSession

    @State private var renamingChapter: Chapter?
    @State private var renamingScene: Scene?
    @State private var renameText = ""
    @State private var chapterPendingDeletion: Chapter?
    @State private var scenePendingDeletion: Scene?
    @State private var showingProjectSettings = false

    private var project: Project { session.project }

    var body: some View {
        @Bindable var session = session
        List(selection: $session.selectedItem) {
            Label("Overview", systemImage: "house")
                .tag(SidebarItem.overview)
            Label("Search", systemImage: "magnifyingglass")
                .tag(SidebarItem.search)
            chaptersSection
            notesSection
        }
        .listStyle(.sidebar)
        .safeAreaInset(edge: .top, spacing: 0) {
            header
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            footer
        }
        .alert("Rename Chapter", isPresented: chapterRenameShown) {
            TextField("Title", text: $renameText)
            Button("Cancel", role: .cancel) { renamingChapter = nil }
            Button("Rename") { commitChapterRename() }
        }
        .alert("Rename Scene", isPresented: sceneRenameShown) {
            TextField("Title", text: $renameText)
            Button("Cancel", role: .cancel) { renamingScene = nil }
            Button("Rename") { commitSceneRename() }
        }
        .confirmationDialog(
            "Delete “\(chapterPendingDeletion?.title ?? "")” and all of its scenes?",
            isPresented: chapterDeleteShown,
            titleVisibility: .visible
        ) {
            Button("Delete Chapter", role: .destructive) { commitChapterDeletion() }
        }
        .confirmationDialog(
            "Delete “\(scenePendingDeletion?.title ?? "")”?",
            isPresented: sceneDeleteShown,
            titleVisibility: .visible
        ) {
            Button("Delete Scene", role: .destructive) { commitSceneDeletion() }
        }
    }

    // MARK: - Sections

    private var chaptersSection: some View {
        Section {
            ForEach(Array(project.chapters.enumerated()), id: \.element.id) { index, chapter in
                chapterGroup(chapter, numeral: RomanNumeral.format(index + 1))
            }
            .onMove { source, destination in
                project.moveChapters(fromOffsets: source, toOffset: destination)
                session.markDirty()
            }
            Button {
                addChapter()
            } label: {
                Label("Add Chapter", systemImage: "plus")
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .selectionDisabled()
        } header: {
            ManuscriptLabel("Manuscript", size: 10, color: Color(nsColor: .tertiaryLabelColor))
        }
    }

    private func chapterGroup(_ chapter: Chapter, numeral: String) -> some View {
        @Bindable var chapter = chapter
        return DisclosureGroup(isExpanded: $chapter.isExpanded) {
            ForEach(chapter.scenes, id: \.id) { scene in
                sceneRow(scene, in: chapter)
            }
            .onMove { source, destination in
                chapter.moveScenes(fromOffsets: source, toOffset: destination)
                session.markDirty()
            }
            Button {
                addScene(to: chapter)
            } label: {
                Label("Add Scene", systemImage: "plus")
                    .font(.callout)
                    .foregroundStyle(.tertiary)
            }
            .buttonStyle(.plain)
            .selectionDisabled()
        } label: {
            HStack(alignment: .firstTextBaseline, spacing: 7) {
                Text(numeral)
                    .font(.custom("Quattrocento-Bold", size: 12))
                    .foregroundStyle(.secondary)
                    .frame(width: 24, alignment: .trailing)
                Text(ManuscriptTitle.strippingNumbering(chapter.title))
                    .font(.custom("Quattrocento-Bold", size: 13))
                    .lineLimit(1)
                Spacer()
                Text("\(chapter.scenes.count)")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .monospacedDigit()
                    .help("\(chapter.scenes.count) scene\(chapter.scenes.count == 1 ? "" : "s")")
            }
            .contextMenu {
                Button("Rename…") { beginRename(chapter) }
                Button("Add Scene") { addScene(to: chapter) }
                Divider()
                Button("Move Up") { moveChapter(chapter, by: -1) }
                    .disabled(project.chapters.first?.id == chapter.id)
                Button("Move Down") { moveChapter(chapter, by: 1) }
                    .disabled(project.chapters.last?.id == chapter.id)
                Divider()
                Button("Delete Chapter…", role: .destructive) { chapterPendingDeletion = chapter }
            }
        }
        // No .selectionDisabled() here: on a DisclosureGroup it propagates to
        // every child row, making the scenes unselectable. The label row is
        // already unselectable because it carries no .tag().
    }

    private func sceneRow(_ scene: Scene, in chapter: Chapter) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            Text(scene.title)
                .font(.system(size: 13))
                .lineLimit(1)
                .layoutPriority(1)
            if scene.wordCount > 0 {
                LeaderDots()
                    .frame(height: 13)
                Text("\(scene.wordCount)")
                    .font(.system(size: 11))
                    .foregroundStyle(.tertiary)
                    .monospacedDigit()
            } else {
                Spacer(minLength: 0)
            }
        }
        .padding(.leading, 31)
        .tag(SidebarItem.scene(scene.id))
        .contextMenu {
            Button("Rename…") { beginRename(scene) }
            Divider()
            Button("Move Up") { moveScene(scene, in: chapter, by: -1) }
                .disabled(chapter.scenes.first?.id == scene.id)
            Button("Move Down") { moveScene(scene, in: chapter, by: 1) }
                .disabled(chapter.scenes.last?.id == scene.id)
            if project.chapters.count > 1 {
                Menu("Move to Chapter") {
                    ForEach(project.chapters.filter { $0.id != chapter.id }, id: \.id) { target in
                        Button(target.title) {
                            project.moveScene(scene, to: target)
                            target.isExpanded = true
                            session.markDirty()
                        }
                    }
                }
            }
            Divider()
            Button("Delete Scene…", role: .destructive) { scenePendingDeletion = scene }
        }
    }

    private func moveChapter(_ chapter: Chapter, by offset: Int) {
        guard let index = project.chapters.firstIndex(where: { $0.id == chapter.id }) else { return }
        let destination = offset < 0 ? index - 1 : index + 2
        guard destination >= 0, destination <= project.chapters.count else { return }
        project.moveChapters(fromOffsets: IndexSet(integer: index), toOffset: destination)
        session.markDirty()
    }

    private func moveScene(_ scene: Scene, in chapter: Chapter, by offset: Int) {
        guard let index = chapter.scenes.firstIndex(where: { $0.id == scene.id }) else { return }
        let destination = offset < 0 ? index - 1 : index + 2
        guard destination >= 0, destination <= chapter.scenes.count else { return }
        chapter.moveScenes(fromOffsets: IndexSet(integer: index), toOffset: destination)
        session.markDirty()
    }

    private var notesSection: some View {
        Section {
            ForEach(project.notes, id: \.id) { note in
                noteRow(note)
            }
            Button {
                addNote()
            } label: {
                Label("Add Note", systemImage: "plus")
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .selectionDisabled()
        } header: {
            ManuscriptLabel("Notes", size: 10, color: Color(nsColor: .tertiaryLabelColor))
        }
    }

    private func noteRow(_ note: Note) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            Text(note.title)
                .font(.custom("Quattrocento-Bold", size: 13))
                .lineLimit(1)
            Spacer(minLength: 0)
            if !note.tags.isEmpty {
                Text("\(note.tags.count)")
                    .font(.system(size: 11))
                    .foregroundStyle(.tertiary)
                    .monospacedDigit()
                    .help(note.tags.joined(separator: ", "))
            }
        }
        .padding(.leading, 4)
        .tag(SidebarItem.note(note.id))
        .contextMenu {
            Button("Delete Note", role: .destructive) {
                if session.selectedNoteID == note.id {
                    session.selectedNoteID = nil
                }
                project.deleteNote(note)
                session.markDirty()
            }
        }
    }

    /// Project header — layout borrowed from the Tauri sidebar: title + gear.
    private var header: some View {
        HStack {
            Text(project.title)
                .font(.headline)
                .lineLimit(1)
            Spacer()
            Button {
                showingProjectSettings = true
            } label: {
                Image(systemName: "gearshape")
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.borderless)
            .help("Project settings and eBook metadata")
        }
        .padding(.horizontal, 16)
        .padding(.top, 4)
        .padding(.bottom, 10)
        .sheet(isPresented: $showingProjectSettings) {
            ProjectSettingsSheet(session: session)
        }
    }

    private var footer: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 5) {
                shortcutRow("New Scene", "⌘N")
                shortcutRow("Command Palette", "⌘K")
                shortcutRow("Focus Mode", "⌘F")
                shortcutRow("AI Suggestion", "hold ⌥")
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            Divider()
            HStack {
                ManuscriptLabel("\(project.totalWordCount.formatted()) words", size: 10, color: .secondary)
                    .monospacedDigit()
                Spacer()
                saveStateLabel
            }
            .font(.caption)
            .foregroundStyle(.secondary)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
        .background(.bar)
    }

    private func shortcutRow(_ label: String, _ keys: String) -> some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(keys)
                .foregroundStyle(.tertiary)
                .monospaced()
        }
        .font(.caption2)
    }

    @ViewBuilder
    private var saveStateLabel: some View {
        switch session.saveState {
        case .saved:
            Label("Saved", systemImage: "checkmark.circle")
        case .dirty:
            Label("Editing…", systemImage: "pencil")
        case .saving:
            Label("Saving…", systemImage: "arrow.triangle.2.circlepath")
        case .failed:
            Label("Save failed", systemImage: "exclamationmark.triangle")
                .foregroundStyle(.red)
        }
    }

    // MARK: - Actions

    private func addChapter() {
        session.createChapter()
    }

    private func addScene(to chapter: Chapter) {
        session.createScene(in: chapter)
    }

    private func addNote() {
        session.createNote()
    }

    private func beginRename(_ chapter: Chapter) {
        renameText = chapter.title
        renamingChapter = chapter
    }

    private func beginRename(_ scene: Scene) {
        renameText = scene.title
        renamingScene = scene
    }

    private func commitChapterRename() {
        let trimmed = renameText.trimmingCharacters(in: .whitespaces)
        if let chapter = renamingChapter, !trimmed.isEmpty {
            chapter.title = trimmed
            chapter.updatedAt = .now
            session.markDirty()
        }
        renamingChapter = nil
    }

    private func commitSceneRename() {
        let trimmed = renameText.trimmingCharacters(in: .whitespaces)
        if let scene = renamingScene, !trimmed.isEmpty {
            scene.title = trimmed
            scene.updatedAt = .now
            session.markDirty()
        }
        renamingScene = nil
    }

    private func commitChapterDeletion() {
        guard let chapter = chapterPendingDeletion else { return }
        if let selected = session.selectedSceneID, chapter.scenes.contains(where: { $0.id == selected }) {
            session.selectedSceneID = nil
        }
        project.deleteChapter(chapter)
        session.markDirty()
        chapterPendingDeletion = nil
    }

    private func commitSceneDeletion() {
        guard let scene = scenePendingDeletion else { return }
        if session.selectedSceneID == scene.id {
            session.selectedSceneID = nil
        }
        project.deleteScene(scene)
        session.markDirty()
        scenePendingDeletion = nil
    }

    // MARK: - Presentation bindings

    private var chapterRenameShown: Binding<Bool> {
        Binding(get: { renamingChapter != nil }, set: { if !$0 { renamingChapter = nil } })
    }

    private var sceneRenameShown: Binding<Bool> {
        Binding(get: { renamingScene != nil }, set: { if !$0 { renamingScene = nil } })
    }

    private var chapterDeleteShown: Binding<Bool> {
        Binding(get: { chapterPendingDeletion != nil }, set: { if !$0 { chapterPendingDeletion = nil } })
    }

    private var sceneDeleteShown: Binding<Bool> {
        Binding(get: { scenePendingDeletion != nil }, set: { if !$0 { scenePendingDeletion = nil } })
    }
}
