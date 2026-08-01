import SwiftUI

struct NoteEditorView: View {
    let session: ProjectSession
    let note: Note

    var body: some View {
        VStack(spacing: 8) {
            Text(note.title)
                .font(.title2.weight(.semibold))
            Text("The note editor arrives with the settings milestone.")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
