import SwiftUI

/// Project details + eBook metadata. Fields write through to the model on
/// every change (Tauri parity); autosave picks them up via markDirty.
struct ProjectSettingsSheet: View {
    let session: ProjectSession
    @Environment(\.dismiss) private var dismiss

    @State private var title: String
    @State private var details: String
    @State private var author: String
    @State private var publisher: String
    @State private var language: String
    @State private var rights: String
    @State private var subjectsText: String

    init(session: ProjectSession) {
        self.session = session
        let project = session.project
        _title = State(initialValue: project.title)
        _details = State(initialValue: project.details)
        let metadata = project.epubMetadata ?? ProjectEpubMetadata()
        _author = State(initialValue: metadata.author)
        _publisher = State(initialValue: metadata.publisher)
        _language = State(initialValue: metadata.language)
        _rights = State(initialValue: metadata.rights)
        _subjectsText = State(initialValue: metadata.subjects.joined(separator: ", "))
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
                    TextField("Author", text: $author)
                    TextField("Publisher", text: $publisher)
                    TextField("Language", text: $language, prompt: Text("en"))
                    TextField("Rights", text: $rights, prompt: Text("Copyright statement"))
                    TextField("Subjects", text: $subjectsText, prompt: Text("Fantasy, Adventure, Drama"))
                } header: {
                    ManuscriptLabel("eBook Metadata", size: 10)
                } footer: {
                    Text("Used as defaults when exporting EPUB files. Separate subjects with commas.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .formStyle(.grouped)
            .onChange(of: title) { save() }
            .onChange(of: details) { save() }
            .onChange(of: author) { save() }
            .onChange(of: publisher) { save() }
            .onChange(of: language) { save() }
            .onChange(of: rights) { save() }
            .onChange(of: subjectsText) { save() }

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
        .frame(width: 460, height: 480)
    }

    private func save() {
        let project = session.project
        project.title = title.trimmingCharacters(in: .whitespaces).isEmpty
            ? "Untitled Project"
            : title.trimmingCharacters(in: .whitespaces)
        project.details = details.trimmingCharacters(in: .whitespacesAndNewlines)
        project.epubMetadata = ProjectEpubMetadata(
            author: author.trimmingCharacters(in: .whitespaces),
            publisher: publisher.trimmingCharacters(in: .whitespaces),
            language: language.trimmingCharacters(in: .whitespaces).isEmpty
                ? "en"
                : language.trimmingCharacters(in: .whitespaces),
            rights: rights.trimmingCharacters(in: .whitespaces),
            subjects: subjectsText
                .split(separator: ",")
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty }
        )
        project.touch()
        session.markDirty()
    }
}
