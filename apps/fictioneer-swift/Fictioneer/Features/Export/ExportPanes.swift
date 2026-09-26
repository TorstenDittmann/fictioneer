import SwiftUI
import UniformTypeIdentifiers

// MARK: - Details

struct DetailsPane: View {
    let model: ExportModel

    var body: some View {
        @Bindable var project = model.project
        Form {
            Section {
                TextField("Title", text: $project.title)
                TextField("Subtitle", text: $project.book.subtitle, prompt: Text("Optional"))
                TextField("Author", text: $project.book.author, prompt: Text("Your name or pen name"))
            } header: {
                ManuscriptLabel("Book", size: 10)
            }

            Section {
                TextField("Series", text: $project.book.series, prompt: Text("Optional"))
                TextField("Number in series", text: $project.book.seriesNumber, prompt: Text("1"))
            } header: {
                ManuscriptLabel("Series", size: 10)
            }

            Section {
                TextField("Publisher", text: $project.book.publisher, prompt: Text("Optional"))
                TextField("ISBN", text: $project.book.isbn, prompt: Text("Optional"))
                LanguageField(language: $project.book.language)
                TextField("Copyright", text: $project.book.rights, prompt: Text(model.book.copyrightLine), axis: .vertical)
                    .lineLimit(1...3)
            } header: {
                ManuscriptLabel("Publishing", size: 10)
            } footer: {
                Text("Leave Copyright empty to use the line shown. The ISBN is optional for eBooks.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section {
                TextField("Description", text: $project.details, prompt: Text("The blurb readers see in their library"), axis: .vertical)
                    .lineLimit(3...8)
                SubjectsField(subjects: $project.book.subjects)
            } header: {
                ManuscriptLabel("Store Listing", size: 10)
            }
        }
        .formStyle(.grouped)
    }
}

private struct LanguageField: View {
    @Binding var language: String

    private static let common: [(code: String, name: String)] = [
        ("en", "English"), ("en-GB", "English (UK)"), ("de", "German"), ("fr", "French"),
        ("es", "Spanish"), ("it", "Italian"), ("pt", "Portuguese"), ("nl", "Dutch"),
        ("sv", "Swedish"), ("da", "Danish"), ("nb", "Norwegian"), ("fi", "Finnish"), ("pl", "Polish"),
    ]

    var body: some View {
        LabeledContent("Language") {
            HStack(spacing: 4) {
                TextField("Language", text: $language, prompt: Text("en"))
                    .labelsHidden()
                    .frame(maxWidth: 90)
                Menu {
                    ForEach(Self.common, id: \.code) { entry in
                        Button("\(entry.name) (\(entry.code))") { language = entry.code }
                    }
                } label: {
                    Text(Locale.current.localizedString(forIdentifier: language) ?? "Choose")
                }
                .menuStyle(.borderlessButton)
                .fixedSize()
            }
        }
    }
}

private struct SubjectsField: View {
    @Binding var subjects: [String]
    @State private var text = ""

    var body: some View {
        TextField("Subjects", text: $text, prompt: Text("Fantasy, Adventure"))
            .onAppear { text = subjects.joined(separator: ", ") }
            .onChange(of: text) {
                let parsed = text.split(separator: ",")
                    .map { $0.trimmingCharacters(in: .whitespaces) }
                    .filter { !$0.isEmpty }
                if parsed != subjects { subjects = parsed }
            }
    }
}

// MARK: - Cover

struct CoverPane: View {
    let model: ExportModel
    @State private var isDropTargeted = false

    var body: some View {
        @Bindable var project = model.project
        Form {
            Section {
                Picker("Cover", selection: $project.book.cover) {
                    ForEach(CoverSource.allCases) { source in
                        Text(source.label).tag(source)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()

                coverPreview
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
            }

            switch project.book.cover {
            case .generated:
                Section {
                    HStack(spacing: 10) {
                        ForEach(CoverDesign.allCases) { design in
                            DesignThumbnail(model: model, design: design, isSelected: project.book.coverDesign == design) {
                                project.book.coverDesign = design
                            }
                        }
                    }
                    LabeledContent("Colors") {
                        HStack(spacing: 8) {
                            ForEach(CoverPalette.allCases) { palette in
                                PaletteSwatch(palette: palette, isSelected: project.book.coverPalette == palette) {
                                    project.book.coverPalette = palette
                                }
                            }
                        }
                    }
                } header: {
                    ManuscriptLabel("Design", size: 10)
                } footer: {
                    Text("Designed from the title, subtitle, author and series. Change those in Details.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            case .image:
                Section {
                    HStack {
                        Button("Choose Image…") { model.chooseCoverImage() }
                        if project.coverImage != nil {
                            Button("Remove", role: .destructive) { model.removeCoverImage() }
                        }
                    }
                } footer: {
                    Text("JPEG or PNG at 1600 × 2560 pixels (1 : 1.6) or larger. You can also drop an image on the cover.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            case .none:
                Section {
                    Text("The book opens on its title page, and libraries show a generic cover.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .formStyle(.grouped)
    }

    @ViewBuilder
    private var coverPreview: some View {
        let width: CGFloat = 170
        ZStack {
            if let data = model.coverData, let image = NSImage(data: data) {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.primary.opacity(0.05))
                    .overlay {
                        VStack(spacing: 6) {
                            Image(systemName: model.project.book.cover == .image ? "photo.badge.plus" : "book.closed")
                                .font(.system(size: 26))
                            Text(model.project.book.cover == .image ? "Drop an image" : "No cover")
                                .font(.caption)
                        }
                        .foregroundStyle(.secondary)
                    }
            }
        }
        .frame(width: width, height: width * 1.6)
        .clipShape(RoundedRectangle(cornerRadius: 3))
        .overlay(RoundedRectangle(cornerRadius: 3).strokeBorder(isDropTargeted ? Color.accentColor : Color.primary.opacity(0.12), lineWidth: isDropTargeted ? 2 : 1))
        .shadow(color: .black.opacity(0.18), radius: 8, y: 4)
        .dropDestination(for: URL.self) { urls, _ in
            guard let url = urls.first else { return false }
            return model.setCoverImage(from: url)
        } isTargeted: { isDropTargeted = $0 }
        .accessibilityLabel(model.coverData == nil ? "No cover" : "Cover preview")
    }
}

private struct DesignThumbnail: View {
    let model: ExportModel
    let design: CoverDesign
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Group {
                    if let image = thumbnail {
                        Image(nsImage: image).resizable()
                    } else {
                        Color.primary.opacity(0.05)
                    }
                }
                .frame(width: 64, height: 102)
                .clipShape(RoundedRectangle(cornerRadius: 2))
                .overlay(
                    RoundedRectangle(cornerRadius: 3)
                        .strokeBorder(isSelected ? Color.accentColor : Color.primary.opacity(0.12), lineWidth: isSelected ? 2 : 1)
                        .padding(-2)
                )
                Text(design.label)
                    .font(.caption)
                    .foregroundStyle(isSelected ? .primary : .secondary)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(design.label) cover design")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private var thumbnail: NSImage? {
        var input = CoverRenderer.input(for: model.book)
        input.design = design
        guard let image = CoverRenderer.render(input, size: CGSize(width: 192, height: 307)) else { return nil }
        return NSImage(cgImage: image, size: CGSize(width: 64, height: 102))
    }
}

private struct PaletteSwatch: View {
    let palette: CoverPalette
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        let swatch = CoverRenderer.swatch(for: palette)
        Button(action: action) {
            Circle()
                .fill(Color(cgColor: swatch.background))
                .overlay(
                    Circle()
                        .fill(Color(cgColor: swatch.accent))
                        .frame(width: 7, height: 7)
                )
                .overlay(Circle().strokeBorder(Color.primary.opacity(0.2), lineWidth: 1))
                .overlay(
                    Circle().strokeBorder(Color.accentColor, lineWidth: 2)
                        .padding(-3)
                        .opacity(isSelected ? 1 : 0)
                )
                .frame(width: 20, height: 20)
        }
        .buttonStyle(.plain)
        .help(palette.label)
        .accessibilityLabel("\(palette.label) colors")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// MARK: - Design

struct DesignPane: View {
    let model: ExportModel

    var body: some View {
        @Bindable var project = model.project
        Form {
            Section {
                VStack(spacing: 6) {
                    ForEach(EpubTemplate.allCases) { template in
                        TemplateRow(template: template, isSelected: project.book.template == template) {
                            project.book.template = template
                        }
                    }
                }
            } header: {
                ManuscriptLabel("Template", size: 10)
            }

            Section {
                Picker("Headings", selection: $project.book.chapterHeading) {
                    ForEach(ChapterHeadingStyle.allCases) { style in
                        Text(style.label).tag(style)
                    }
                }
                Picker("First line", selection: $project.book.chapterOpening) {
                    ForEach(ChapterOpeningStyle.allCases) { style in
                        Text(style.label).tag(style)
                    }
                }
                Toggle("Show scene titles", isOn: $project.book.showsSceneTitles)
            } header: {
                ManuscriptLabel("Chapters", size: 10)
            }

            Section {
                Picker("Between scenes", selection: $project.book.sceneBreak) {
                    ForEach(SceneBreakStyle.allCases) { style in
                        Text(style.label).tag(style)
                    }
                }
                if project.book.sceneBreak == .custom {
                    TextField("Custom break", text: $project.book.customSceneBreak, prompt: Text("~"))
                }
            } header: {
                ManuscriptLabel("Scene Breaks", size: 10)
            }

            Section {
                Picker("Body font", selection: $project.book.bodyFont) {
                    ForEach(BookFont.allCases) { font in
                        Text(font.label).tag(font)
                    }
                }
            } header: {
                ManuscriptLabel("Typography", size: 10)
            } footer: {
                Text("Most readers let people pick their own font; this is the book’s default.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
    }
}

private struct TemplateRow: View {
    let template: EpubTemplate
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Text("Aa")
                    .font(sampleFont)
                    .frame(width: 44, height: 44)
                    .background(RoundedRectangle(cornerRadius: 6).fill(Color.primary.opacity(0.05)))
                VStack(alignment: .leading, spacing: 2) {
                    Text(template.label)
                        .font(.system(size: 13, weight: .semibold))
                    Text(template.blurb)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? Color.accentColor : Color.secondary.opacity(0.5))
            }
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.accentColor.opacity(0.08) : .clear)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(template.label) template. \(template.blurb)")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private var sampleFont: Font {
        switch template {
        case .genericNovel: .custom("Georgia", size: 20)
        case .modernCompact: .system(size: 20, weight: .bold)
        case .classicBook: .custom("Palatino", size: 20).italic()
        }
    }
}

// MARK: - Front and back matter

struct PagesPane: View {
    let model: ExportModel

    var body: some View {
        @Bindable var project = model.project
        Form {
            Section {
                Toggle("Title page", isOn: $project.book.includesTitlePage)
                Toggle("Copyright page", isOn: $project.book.includesCopyrightPage)
                Toggle("Table of contents", isOn: $project.book.includesTableOfContents)
            } header: {
                ManuscriptLabel("Front Matter", size: 10)
            }

            Section {
                MatterEditor(title: "Dedication", text: $project.book.dedication, placeholder: "For …")
                MatterEditor(title: "Epigraph", text: $project.book.epigraph, placeholder: "A quotation that sets the tone")
                if !project.book.epigraph.isEmpty {
                    TextField("Attribution", text: $project.book.epigraphAttribution, prompt: Text("Who said it"))
                }
            }

            Section {
                MatterEditor(title: "Acknowledgements", text: $project.book.acknowledgements, placeholder: "Thanks to …")
                MatterEditor(title: "About the Author", text: $project.book.aboutAuthor, placeholder: "A short biography")
                MatterEditor(title: "Also By", text: $project.book.alsoBy, placeholder: "One title per line")
            } header: {
                ManuscriptLabel("Back Matter", size: 10)
            } footer: {
                Text("Empty pages are left out of the book.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
    }
}

private struct MatterEditor: View {
    let title: String
    @Binding var text: String
    let placeholder: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
            TextEditor(text: $text)
                .font(.body)
                .scrollContentBackground(.hidden)
                .frame(minHeight: 54, maxHeight: 110)
                .padding(4)
                .background(RoundedRectangle(cornerRadius: 5).fill(Color.primary.opacity(0.04)))
                .overlay(alignment: .topLeading) {
                    if text.isEmpty {
                        Text(placeholder)
                            .foregroundStyle(.tertiary)
                            .padding(.horizontal, 9)
                            .padding(.vertical, 4)
                            .allowsHitTesting(false)
                    }
                }
                .accessibilityLabel(title)
        }
    }
}

// MARK: - Contents

struct ContentsPane: View {
    let model: ExportModel

    var body: some View {
        @Bindable var project = model.project
        VStack(spacing: 0) {
            HStack {
                Text("\(model.book.chapters.count) chapters · \(model.book.wordCount.formatted()) words")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
                Spacer()
                Menu("Select") {
                    Button("Everything") {
                        project.book.excludedChapterIDs = []
                        project.book.excludedSceneIDs = []
                    }
                    Button("Only Revised and Done Scenes") {
                        project.book.excludedChapterIDs = []
                        project.book.excludedSceneIDs = Set(
                            project.allScenes.filter { $0.status == .idea || $0.status == .draft }.map(\.id)
                        )
                    }
                }
                .menuStyle(.borderlessButton)
                .fixedSize()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            Divider()
            List {
                ForEach(project.chapters, id: \.id) { chapter in
                    ChapterInclusionRow(project: project, chapter: chapter)
                }
            }
            .listStyle(.sidebar)
        }
    }
}

private struct ChapterInclusionRow: View {
    @Bindable var project: Project
    let chapter: Chapter

    var body: some View {
        let chapterIncluded = project.book.includes(chapter: chapter.id)
        DisclosureGroup {
            ForEach(chapter.scenes, id: \.id) { scene in
                Toggle(isOn: sceneBinding(scene)) {
                    HStack(spacing: 6) {
                        StatusDot(status: scene.status, size: 6)
                        Text(scene.title)
                            .lineLimit(1)
                        Spacer()
                        Text(scene.wordCount.formatted())
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                            .monospacedDigit()
                    }
                }
                .disabled(!chapterIncluded)
            }
        } label: {
            Toggle(isOn: chapterBinding) {
                HStack {
                    Text(chapter.title)
                        .fontWeight(.medium)
                        .lineLimit(1)
                    Spacer()
                    Text(chapter.scenes.reduce(0) { $0 + $1.wordCount }.formatted())
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }
            }
        }
    }

    private var chapterBinding: Binding<Bool> {
        Binding {
            project.book.includes(chapter: chapter.id)
        } set: { included in
            if included {
                project.book.excludedChapterIDs.remove(chapter.id)
            } else {
                project.book.excludedChapterIDs.insert(chapter.id)
            }
        }
    }

    private func sceneBinding(_ scene: Scene) -> Binding<Bool> {
        Binding {
            project.book.includes(scene: scene.id)
        } set: { included in
            if included {
                project.book.excludedSceneIDs.remove(scene.id)
            } else {
                project.book.excludedSceneIDs.insert(scene.id)
            }
        }
    }
}

// MARK: - Manuscript formats

struct ManuscriptPane: View {
    @Bindable var model: ExportModel

    var body: some View {
        VStack(spacing: 0) {
            Form {
                Section {
                    Toggle("Title and author", isOn: $model.options.includeTitle)
                    Toggle("Chapter titles", isOn: $model.options.includeChapterTitles)
                    Toggle("Scene titles", isOn: $model.options.includeSceneTitles)
                    Toggle("Word count per scene", isOn: $model.options.includeWordCount)
                } header: {
                    ManuscriptLabel("Include", size: 10)
                } footer: {
                    Text(model.options.format == .rtf
                        ? "Opens in Word, Pages and most editors, with bold, italics and headings kept."
                        : "Plain text without any formatting.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .formStyle(.grouped)
            .frame(height: 250)
            Divider()
            ContentsPane(model: model)
        }
    }
}
