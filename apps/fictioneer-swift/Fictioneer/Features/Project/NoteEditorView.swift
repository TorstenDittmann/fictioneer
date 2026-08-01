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
}
