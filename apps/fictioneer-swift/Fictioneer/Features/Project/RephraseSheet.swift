import SwiftUI

struct RephrasePayload: Identifiable {
    let id = UUID()
    let selected: String
    let before: String
    let after: String
}

/// Five typed AI alternatives for the selected sentence; picking one replaces
/// the selection as a single undoable edit.
struct RephraseSheet: View {
    @Environment(AppModel.self) private var appModel
    @Environment(\.dismiss) private var dismiss
    let payload: RephrasePayload
    let controller: EditorController

    @State private var alternatives: [IntelligenceClient.RephraseAlternative] = []
    @State private var isLoading = true
    @State private var errorMessage: String?

    private static let typeLabels: [String: String] = [
        "vivid": "Vivid",
        "tighter": "Tighter",
        "show_dont_tell": "Show Don't Tell",
        "change_pov": "Change POV",
        "simplify": "Simplify",
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Rephrase Suggestions")
                .font(.custom("Quattrocento-Bold", size: 20))

            VStack(alignment: .leading, spacing: 4) {
                ManuscriptLabel("Original", size: 10)
                Text(payload.selected)
                    .font(.callout)
                    .padding(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.quaternary.opacity(0.4), in: RoundedRectangle(cornerRadius: 6))
            }

            if isLoading {
                HStack(spacing: 8) {
                    ProgressView().controlSize(.small)
                    Text("Generating rephrases…")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
            } else if let errorMessage {
                Text(errorMessage)
                    .font(.callout)
                    .foregroundStyle(.red)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
            } else if alternatives.isEmpty {
                Text("No rephrases available")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(alternatives, id: \.type) { alternative in
                            VStack(alignment: .leading, spacing: 3) {
                                ManuscriptLabel(
                                    Self.typeLabels[alternative.type] ?? alternative.type,
                                    size: 10,
                                    color: .manuscriptIndigo
                                )
                                Button {
                                    controller.replaceSelection(with: alternative.alternative)
                                    dismiss()
                                } label: {
                                    Text(alternative.alternative)
                                        .font(.callout)
                                        .multilineTextAlignment(.leading)
                                        .padding(8)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(.separator))
                                        .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                .frame(maxHeight: 320)
            }

            HStack {
                Spacer()
                Button("Cancel", role: .cancel) { dismiss() }
            }
        }
        .padding(20)
        .frame(width: 480)
        .task { await fetch() }
    }

    private func fetch() async {
        let settings = appModel.settings
        let client = IntelligenceClient(
            baseURL: settings.intelligenceBaseURL,
            licenseKey: settings.licenseKey
        )
        do {
            let response = try await client.rephrase(
                selectedSentence: payload.selected,
                contextBefore: payload.before,
                contextAfter: payload.after
            )
            alternatives = response.rephrases
        } catch {
            errorMessage = "Failed to get rephrases: \(error.localizedDescription)"
        }
        isLoading = false
    }
}
