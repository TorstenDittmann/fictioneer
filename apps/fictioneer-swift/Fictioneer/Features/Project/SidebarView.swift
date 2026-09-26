import SwiftUI

struct SidebarView: View {
    let session: ProjectSession

    @State private var renamingChapter: Chapter?
    @State private var renamingScene: Scene?
    @State private var renameText = ""
    @State private var chapterPendingDeletion: Chapter?
    @State private var scenePendingDeletion: Scene?
    @State private var showingProjectSettings = false
    @State private var hoveredChapterID: UUID?

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

    private static let numeralSpacing: CGFloat = 6
    private static let numeralFontName = "Quattrocento-Bold"
    private static let numeralFontSize: CGFloat = 12

    /// Fits the numeral column to the widest numeral in the project, so
    /// chapter titles align without a fixed column leaving a gap after "I".
    private static func numeralColumnWidth(_ numerals: some Sequence<String>) -> CGFloat {
        let font = NSFont(name: numeralFontName, size: numeralFontSize) ?? .boldSystemFont(ofSize: numeralFontSize)
        let widths = numerals.map { NSAttributedString(string: $0, attributes: [.font: font]).size().width }
        return ceil(widths.max() ?? 0)
    }

    private var chaptersSection: some View {
        let rows = SidebarOutline.rows(for: project)
        let numerals = Dictionary(
            uniqueKeysWithValues: project.chapters.enumerated().map { ($1.id, RomanNumeral.format($0 + 1)) }
        )
        let numeralWidth = Self.numeralColumnWidth(numerals.values)
        let sceneIndent = numeralWidth + Self.numeralSpacing
        return Section {
            ForEach(rows) { row in
                Group {
                    switch row {
                    case .chapter(let chapter):
                        chapterRow(chapter, numeral: numerals[chapter.id] ?? "", numeralWidth: numeralWidth)
                    case .scene(let scene, let chapter):
                        sceneRow(scene, in: chapter, indent: sceneIndent)
                    case .addScene(let chapter):
                        emptyChapterRow(chapter, indent: sceneIndent)
                    }
                }
                .moveDisabled(!row.isMovable)
            }
            .onMove { source, destination in
                if SidebarOutline.move(in: project, rows: rows, fromOffsets: source, toOffset: destination) {
                    session.markDirty()
                }
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

    /// Unselectable (no .tag()); clicking anywhere on it toggles the chapter.
    /// The trailing edge shows the scene count only while collapsed (expanded,
    /// the scenes are right there) and an Add Scene button on hover.
    private func chapterRow(_ chapter: Chapter, numeral: String, numeralWidth: CGFloat) -> some View {
        let isHovered = hoveredChapterID == chapter.id
        return HStack(alignment: .firstTextBaseline, spacing: Self.numeralSpacing) {
            Text(numeral)
                .font(.custom(Self.numeralFontName, size: Self.numeralFontSize))
                .foregroundStyle(.secondary)
                .fixedSize()
                .frame(minWidth: numeralWidth, alignment: .leading)
            Text(ManuscriptTitle.strippingNumbering(chapter.title))
                .font(.custom("Quattrocento-Bold", size: 13))
                .lineLimit(1)
            Spacer(minLength: 4)
            if isHovered {
                Button {
                    addScene(to: chapter)
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.borderless)
                .help("Add scene")
                .accessibilityLabel("Add scene to \(chapter.title)")
            } else if !chapter.isExpanded {
                Text("\(chapter.scenes.count)")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .monospacedDigit()
                    .fixedSize()
                    .help("\(chapter.scenes.count) scene\(chapter.scenes.count == 1 ? "" : "s")")
            }
            Image(systemName: "chevron.right")
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(.tertiary)
                .rotationEffect(.degrees(chapter.isExpanded ? 90 : 0))
                .frame(width: 10)
                .accessibilityHidden(true)
        }
        .contentShape(Rectangle())
        .onTapGesture { toggle(chapter) }
        .onHover { hovering in
            if hovering {
                hoveredChapterID = chapter.id
            } else if hoveredChapterID == chapter.id {
                hoveredChapterID = nil
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityAddTraits(.isButton)
        .accessibilityValue(chapter.isExpanded ? "Expanded" : "Collapsed")
        .accessibilityAction { toggle(chapter) }
        .contextMenu {
            Button(chapter.isExpanded ? "Collapse" : "Expand") { toggle(chapter) }
            Divider()
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

    /// Placeholder under an expanded chapter with no scenes, aligned with
    /// where scene titles would start.
    private func emptyChapterRow(_ chapter: Chapter, indent: CGFloat) -> some View {
        Button {
            addScene(to: chapter)
        } label: {
            Text("Add Scene")
                .font(.system(size: 13))
                .foregroundStyle(.tertiary)
        }
        .buttonStyle(.plain)
        .padding(.leading, indent)
        .selectionDisabled()
    }

    private func toggle(_ chapter: Chapter) {
        withAnimation(.easeInOut(duration: 0.15)) {
            chapter.isExpanded.toggle()
        }
    }

    private func sceneRow(_ scene: Scene, in chapter: Chapter, indent: CGFloat) -> some View {
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
                    .fixedSize()
                    .layoutPriority(1)
            } else {
                Spacer(minLength: 0)
            }
        }
        .padding(.leading, indent)
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
                .layoutPriority(1)
            Spacer(minLength: 0)
            if !note.tags.isEmpty {
                Text("\(note.tags.count)")
                    .font(.system(size: 11))
                    .foregroundStyle(.tertiary)
                    .monospacedDigit()
                    .fixedSize()
                    .help(note.tags.joined(separator: ", "))
            }
        }
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
            .accessibilityLabel("Project settings")
        }
        .padding(.horizontal, 16)
        .padding(.top, 4)
        .padding(.bottom, 10)
        .sheet(isPresented: $showingProjectSettings) {
            ProjectSettingsSheet(session: session)
        }
    }

    /// Word count, plus a warning only when saving failed. Unsaved changes
    /// show as the dot in the close button, and shortcuts live in the menus.
    private var footer: some View {
        HStack {
            ManuscriptLabel("\(project.totalWordCount.formatted()) words", size: 10, color: .secondary)
                .monospacedDigit()
            Spacer()
            if let message = session.saveFailureMessage {
                Label("Save failed", systemImage: "exclamationmark.triangle")
                    .font(.caption)
                    .foregroundStyle(.red)
                    .help(message)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.bar)
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
