import SwiftUI

struct NoteEditorView: View {
    @Environment(AppModel.self) private var appModel
    let session: ProjectSession
    let note: Note

    @State private var controller = EditorController()
    @State private var title: String
    @State private var tagsText: String

    init(session: ProjectSession, note: Note) {
        self.session = session
        self.note = note
        _title = State(initialValue: note.title)
        _tagsText = State(initialValue: note.tags.joined(separator: ", "))
    }

    var body: some View {
        ManuscriptPage(header: ManuscriptPageHeader(
            project: session.project.title,
            section: "Notes",
            title: note.title
        )) {
            noteSurface
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(VisualEffectView().ignoresSafeArea())
        .navigationTitle(note.title)
        .navigationSubtitle("Notes")
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                ControlGroup {
                    Button {
                        controller.toggleBold()
                    } label: {
                        Label("Bold", systemImage: "bold")
                    }
                    .keyboardShortcut("b", modifiers: .command)
                    Button {
                        controller.toggleItalic()
                    } label: {
                        Label("Italic", systemImage: "italic")
                    }
                    .keyboardShortcut("i", modifiers: .command)
                }
            }
        }
    }

    /// Distinct tags used elsewhere in the project, minus tags already on
    /// this note, filtered to the fragment currently being typed.
    private var tagSuggestions: [String] {
        TagSuggestions.suggestions(
            allTags: session.project.notes.flatMap(\.tags),
            appliedTags: note.tags,
            fragment: TagSuggestions.currentFragment(in: tagsText)
        )
    }

    private var tagSuggestionRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(tagSuggestions, id: \.self) { tag in
                    Button {
                        tagsText = TagSuggestions.applying(tag, to: tagsText)
                    } label: {
                        Text(tag)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(.quaternary.opacity(0.4), in: Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var noteSurface: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 8) {
                TextField("Note title", text: $title)
                    .textFieldStyle(.plain)
                    .font(.custom("Quattrocento-Bold", size: 24))
                    .onChange(of: title) {
                        note.title = title
                        note.updatedAt = .now
                        session.markDirty()
                    }
                TextField("Tags (comma separated, e.g. character, pov)", text: $tagsText)
                    .textFieldStyle(.plain)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .onChange(of: tagsText) {
                        note.tags = tagsText
                            .split(separator: ",")
                            .map { $0.trimmingCharacters(in: .whitespaces) }
                            .filter { !$0.isEmpty }
                        note.updatedAt = .now
                        session.markDirty(noteID: note.id)
                    }
                if !tagSuggestions.isEmpty {
                    tagSuggestionRow
                }
            }
            .padding(.horizontal, 32)
            .padding(.top, 24)
            .padding(.bottom, 12)
            Divider()
            RichTextEditor(
                initialContent: note.body,
                settings: appModel.settings,
                controller: controller
            ) { content in
                note.body = content
                note.updatedAt = .now
                session.markDirty(noteID: note.id)
            }
        }
    }
}
