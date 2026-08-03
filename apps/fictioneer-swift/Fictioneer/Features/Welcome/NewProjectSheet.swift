import SwiftUI

struct NewProjectSheet: View {
    @Environment(AppModel.self) private var appModel
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var details = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("New Project")
                .font(.custom("Quattrocento-Bold", size: 22))

            VStack(alignment: .leading, spacing: 6) {
                ManuscriptLabel("Title", size: 10)
                TextField("My Great Novel", text: $title)
                    .textFieldStyle(.roundedBorder)
            }

            VStack(alignment: .leading, spacing: 6) {
                ManuscriptLabel("Description", size: 10)
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
