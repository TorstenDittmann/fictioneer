import SwiftUI

/// Project basics. Fields write through to the model on every change;
/// autosave picks them up via markDirty. Book details, cover and design
/// live in the export window.
struct ProjectSettingsSheet: View {
    let session: ProjectSession
    @Environment(\.dismiss) private var dismiss

    @State private var title: String
    @State private var details: String
    @State private var quoteStyle: QuoteStyle

    init(session: ProjectSession) {
        self.session = session
        let project = session.project
        _title = State(initialValue: project.title)
        _details = State(initialValue: project.details)
        _quoteStyle = State(initialValue: project.effectiveQuoteStyle)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Project Settings")
                .font(.custom("Quattrocento-Bold", size: 20))
                .padding(.bottom, 12)

            Form {
                Section {
                    TextField("Title", text: $title)
                    TextField("Description", text: $details, axis: .vertical)
                        .lineLimit(3, reservesSpace: true)
                } header: {
                    ManuscriptLabel("Basic Information", size: 10)
                }
                Section {
                    Picker("Quotation marks", selection: $quoteStyle) {
                        ForEach(QuoteStyle.allCases) { style in
                            Text(style.displayName).tag(style)
                        }
                    }
                } header: {
                    ManuscriptLabel("Writing", size: 10)
                } footer: {
                    Text("Used as you type. Format ▸ Convert Quotes updates existing text in a scene.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Section {
                    Text("Author, cover, design and the rest of the book’s details are set when you export.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                } header: {
                    ManuscriptLabel("Book", size: 10)
                }
            }
            .formStyle(.grouped)
            .onChange(of: title) { save() }
            .onChange(of: details) { save() }
            .onChange(of: quoteStyle) { save() }

            HStack {
                let stats = session.project
                Text("\(stats.chapters.count) chapters · \(stats.allScenes.count) scenes · \(stats.totalWordCount) words")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
                Spacer()
                Button("Done") { dismiss() }
                    .buttonStyle(.borderedProminent)
            }
            .padding(.top, 12)
        }
        .padding(20)
        .frame(width: 460, height: 440)
    }

    private func save() {
        let project = session.project
        project.title = title.trimmingCharacters(in: .whitespaces).isEmpty
            ? "Untitled Project"
            : title.trimmingCharacters(in: .whitespaces)
        project.details = details.trimmingCharacters(in: .whitespacesAndNewlines)
        project.quoteStyle = quoteStyle
        project.touch()
        session.markDirty()
    }
}
