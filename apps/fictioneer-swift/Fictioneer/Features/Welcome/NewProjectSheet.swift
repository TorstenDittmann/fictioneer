import SwiftUI

struct NewProjectSheet: View {
    @Environment(AppModel.self) private var appModel
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var details = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("New Project")
                .font(.title2.weight(.semibold))

            VStack(alignment: .leading, spacing: 6) {
                Text("Title")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
                TextField("My Great Novel", text: $title)
                    .textFieldStyle(.roundedBorder)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Description")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
                TextField("What is this story about? (optional)", text: $details, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(3, reservesSpace: true)
            }

            HStack {
                Spacer()
                Button("Cancel", role: .cancel) {
                    dismiss()
                }
                Button("Create…") {
                    dismiss()
                    appModel.createProject(title: title, details: details)
                }
                .buttonStyle(.borderedProminent)
                .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .padding(24)
        .frame(width: 420)
    }
}
