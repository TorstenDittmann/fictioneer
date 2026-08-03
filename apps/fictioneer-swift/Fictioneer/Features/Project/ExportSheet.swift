import SwiftUI

struct ExportSheet: View {
    let session: ProjectSession
    @Environment(\.dismiss) private var dismiss

    @State private var options: ExportOptions
    @State private var exportError: String?

    init(session: ProjectSession, format: ExportFormat = .rtf) {
        self.session = session
        var initial = ExportOptions()
        initial.format = format
        initial.epubMetadata = session.project.epubMetadata ?? ProjectEpubMetadata()
        _options = State(initialValue: initial)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Export Project")
                .font(.custom("Quattrocento-Bold", size: 20))
                .padding(.bottom, 12)

            Form {
                Picker("Format", selection: $options.format) {
                    ForEach(ExportFormat.allCases) { format in
                        Text(format.label).tag(format)
                    }
                }
                .pickerStyle(.segmented)

                Section {
                    Toggle("Project title", isOn: $options.includeTitle)
                    Toggle("Chapter titles", isOn: $options.includeChapterTitles)
                    Toggle("Scene titles", isOn: $options.includeSceneTitles)
                    Toggle("Word count per scene", isOn: $options.includeWordCount)
                } header: {
                    ManuscriptLabel("Include in Export", size: 10)
                }

                if options.format == .epub {
                    Section {
                        Picker("Template", selection: $options.epubTemplate) {
                            ForEach(EpubTemplate.allCases) { template in
                                Text(template.label).tag(template)
                            }
                        }
                        Text(options.epubTemplate.blurb)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        TextField("Author", text: $options.epubMetadata.author)
                        TextField("Publisher", text: $options.epubMetadata.publisher)
                        TextField("Language", text: $options.epubMetadata.language, prompt: Text("en"))
                        TextField("Rights", text: $options.epubMetadata.rights)
                    } header: {
                        ManuscriptLabel("EPUB Publishing Details", size: 10)
                    }
                }

                Section {
                    let project = session.project
                    LabeledContent("Chapters", value: "\(project.chapters.count)")
                    LabeledContent("Scenes", value: "\(project.allScenes.count)")
                    LabeledContent("Total words", value: "\(project.totalWordCount)")
                } header: {
                    ManuscriptLabel("Manuscript", size: 10)
                }
            }
            .formStyle(.grouped)

            if let exportError {
                Text(exportError)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .padding(.vertical, 4)
            }

            HStack {
                Spacer()
                Button("Cancel", role: .cancel) { dismiss() }
                Button("Export…") { runExport() }
                    .buttonStyle(.borderedProminent)
            }
            .padding(.top, 10)
        }
        .padding(20)
        .frame(width: 460, height: 540)
    }

    private func runExport() {
        session.saveNow()
        do {
            if try ExportService.exportViaPanel(project: session.project, options: options) {
                dismiss()
            }
        } catch {
            exportError = "Export failed: \(error.localizedDescription)"
        }
    }
}
