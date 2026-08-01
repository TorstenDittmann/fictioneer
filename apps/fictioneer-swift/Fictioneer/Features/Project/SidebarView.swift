import SwiftUI

struct SidebarView: View {
    let session: ProjectSession

    @State private var renamingChapter: Chapter?
    @State private var renamingScene: Scene?
    @State private var renameText = ""
    @State private var chapterPendingDeletion: Chapter?
    @State private var scenePendingDeletion: Scene?

    private var project: Project { session.project }

    var body: some View {
        VStack(spacing: 0) {
            List {
                overviewRow
                chaptersSection
                notesSection
            }
            .listStyle(.sidebar)
            Divider()
            footer
        }
        .navigationTitle(project.title)
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

    private var overviewRow: some View {
        Button {
            session.selectedSceneID = nil
            session.selectedNoteID = nil
        } label: {
            Label("Overview", systemImage: "house")
        }
        .buttonStyle(.plain)
    }

    private var chaptersSection: some View {
        Section {
            ForEach(project.chapters, id: \.id) { chapter in
                chapterGroup(chapter)
            }
            Button {
                addChapter()
            } label: {
                Label("Add Chapter", systemImage: "plus")
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        } header: {
            Text("Manuscript")
        }
    }

    private func chapterGroup(_ chapter: Chapter) -> some View {
        @Bindable var chapter = chapter
        return DisclosureGroup(isExpanded: $chapter.isExpanded) {
            ForEach(chapter.scenes, id: \.id) { scene in
                sceneRow(scene)
            }
            Button {
                addScene(to: chapter)
            } label: {
                Label("Add Scene", systemImage: "plus")
                    .font(.callout)
                    .foregroundStyle(.tertiary)
            }
            .buttonStyle(.plain)
        } label: {
            HStack {
                Text(chapter.title)
                    .font(.callout.weight(.semibold))
                    .lineLimit(1)
                Spacer()
                Text("\(chapter.scenes.count)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
            .contextMenu {
                Button("Rename…") { beginRename(chapter) }
                Button("Add Scene") { addScene(to: chapter) }
                Divider()
                Button("Delete Chapter…", role: .destructive) { chapterPendingDeletion = chapter }
            }
        }
    }

    private func sceneRow(_ scene: Scene) -> some View {
        let isSelected = session.selectedNoteID == nil && session.selectedSceneID == scene.id
        return Button {
            session.selectedNoteID = nil
            session.selectedSceneID = scene.id
        } label: {
            HStack {
                Image(systemName: "doc.text")
                    .foregroundStyle(isSelected ? Color.accentColor : Color.secondary)
                Text(scene.title)
                    .lineLimit(1)
                Spacer()
                if scene.wordCount > 0 {
                    Text("\(scene.wordCount)")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .monospacedDigit()
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .listRowBackground(
            isSelected
                ? RoundedRectangle(cornerRadius: 6).fill(Color.accentColor.opacity(0.16))
                : nil
        )
        .contextMenu {
            Button("Rename…") { beginRename(scene) }
            Divider()
            Button("Delete Scene…", role: .destructive) { scenePendingDeletion = scene }
        }
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
        } header: {
            Text("Notes")
        }
    }

    private func noteRow(_ note: Note) -> some View {
        let isSelected = session.selectedNoteID == note.id
        return Button {
            session.selectedNoteID = note.id
        } label: {
            HStack {
                Image(systemName: "note.text")
                    .foregroundStyle(isSelected ? Color.accentColor : Color.secondary)
                Text(note.title)
                    .lineLimit(1)
                Spacer()
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .listRowBackground(
            isSelected
                ? RoundedRectangle(cornerRadius: 6).fill(Color.accentColor.opacity(0.16))
                : nil
        )
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

    private var footer: some View {
        HStack {
            Text("\(project.totalWordCount) words")
                .monospacedDigit()
            Spacer()
            saveStateLabel
        }
        .font(.caption)
        .foregroundStyle(.secondary)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    @ViewBuilder
    private var saveStateLabel: some View {
        switch session.saveState {
        case .saved:
            Label("Saved", systemImage: "checkmark.circle")
                .labelStyle(.titleAndIcon)
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
        let chapter = project.addChapter()
        chapter.isExpanded = true
        session.markDirty()
    }

    private func addScene(to chapter: Chapter) {
        let scene = project.addScene(to: chapter)
        chapter.isExpanded = true
        session.selectedNoteID = nil
        session.selectedSceneID = scene.id
        session.markDirty(sceneID: scene.id)
    }

    private func addNote() {
        let note = project.addNote()
        session.selectedNoteID = note.id
        session.markDirty(noteID: note.id)
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
