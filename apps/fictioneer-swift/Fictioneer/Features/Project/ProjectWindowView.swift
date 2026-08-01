import SwiftUI

struct ProjectWindowView: View {
    let session: ProjectSession

    var body: some View {
        VStack(spacing: 12) {
            Text(session.project.title)
                .font(.title.weight(.semibold))
            Text("Project window — sidebar and editor arrive in the next milestones.")
                .foregroundStyle(.secondary)
            saveStatus
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var saveStatus: some View {
        Group {
            switch session.saveState {
            case .saved(let date):
                Text("Saved \(date, format: .dateTime.hour().minute().second())")
            case .dirty:
                Text("Unsaved changes…")
            case .saving:
                Text("Saving…")
            case .failed(let message):
                Text("Save failed: \(message)").foregroundStyle(.red)
            }
        }
        .font(.caption)
        .foregroundStyle(.secondary)
    }
}
