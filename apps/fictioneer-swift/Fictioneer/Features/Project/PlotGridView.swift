import SwiftUI

extension PlotLine.Tint {
    var color: Color {
        switch self {
        case .amber: Color(red: 0xD9 / 255, green: 0xA4 / 255, blue: 0x5B / 255)
        case .rose: Color(red: 0xD9 / 255, green: 0x7A / 255, blue: 0xA3 / 255)
        case .teal: Color(red: 0x4F / 255, green: 0xAE / 255, blue: 0x9E / 255)
        case .indigo: .manuscriptIndigo
        case .green: Color(red: 0x6C / 255, green: 0xB0 / 255, blue: 0x5A / 255)
        case .slate: Color(red: 0x8A / 255, green: 0x93 / 255, blue: 0xA6 / 255)
        }
    }

    var name: String { rawValue.capitalized }
}

/// Scenes down the side in manuscript order, plot lines across the top;
/// each cell holds what that scene does for that thread (Dabble's plot
/// grid). Cards mode shows the same scenes as a corkboard.
struct PlotGridView: View {
    enum Mode: String, CaseIterable, Identifiable {
        case grid = "Grid"
        case cards = "Cards"
        var id: String { rawValue }
    }

    let session: ProjectSession
    @State private var mode: Mode = .grid
    @State private var dismissedGap: PlotGap?

    static let sceneColumnWidth: CGFloat = 240
    static let lineColumnWidth: CGFloat = 210

    private var project: Project { session.project }

    var body: some View {
        ManuscriptPage {
            switch mode {
            case .grid: gridView
            case .cards: cardsView
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Picker("View", selection: $mode) {
                    ForEach(Mode.allCases) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)
                .help("Show the plot grid or scene cards")
                Button {
                    project.addPlotLine()
                    session.markDirty()
                } label: {
                    Label("Add Plot Line", systemImage: "plus")
                }
                .help("Add a plot line (a column in the grid)")
            }
        }
        .navigationTitle("Plot Grid")
        .navigationSubtitle("\(project.allScenes.count) scenes · \(project.plotLines.count) plot lines")
    }

    // MARK: - Grid

    private var gaps: [PlotGap] {
        PlotGridAnalysis.gaps(
            sceneIDs: project.allScenes.map(\.id),
            plotLines: project.plotLines,
            beats: project.beats
        )
    }

    private var gridView: some View {
        let gaps = gaps
        let gapCells = Set(gaps.flatMap { gap in gap.sceneIDs.map { BeatKey(sceneID: $0, plotLineID: gap.plotLineID) } })
        return ScrollView([.horizontal, .vertical]) {
            VStack(alignment: .leading, spacing: 0) {
                headerRow
                ForEach(Array(project.chapters.enumerated()), id: \.element.id) { index, chapter in
                    chapterRow(chapter, numeral: RomanNumeral.format(index + 1))
                    ForEach(chapter.scenes, id: \.id) { scene in
                        sceneRow(scene, gapCells: gapCells)
                    }
                }
                if project.plotLines.isEmpty {
                    emptyState
                }
            }
            .padding(.horizontal, 28)
            .padding(.vertical, 20)
        }
        .overlay(alignment: .bottomTrailing) {
            if let gap = gaps.first, gap != dismissedGap {
                gapHint(gap)
                    .padding(20)
            }
        }
    }

    private var headerRow: some View {
        HStack(alignment: .center, spacing: 0) {
            ManuscriptLabel("Scene", size: 10, color: .secondary)
                .frame(width: Self.sceneColumnWidth, alignment: .leading)
                .padding(.horizontal, 8)
            ForEach(project.plotLines) { line in
                PlotLineHeader(session: session, line: line)
                    .frame(width: Self.lineColumnWidth, alignment: .leading)
                    .padding(.horizontal, 8)
            }
        }
        .padding(.vertical, 10)
        .overlay(alignment: .bottom) { Divider() }
    }

    private func chapterRow(_ chapter: Chapter, numeral: String) -> some View {
        ManuscriptLabel("\(numeral) · \(ManuscriptTitle.strippingNumbering(chapter.title))", size: 10, color: .secondary)
            .padding(.horizontal, 8)
            .padding(.vertical, 7)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.primary.opacity(0.03))
            .overlay(alignment: .bottom) { Divider() }
    }

    private func sceneRow(_ scene: Scene, gapCells: Set<BeatKey>) -> some View {
        HStack(alignment: .top, spacing: 0) {
            SceneSummaryButton(session: session, scene: scene)
                .frame(width: Self.sceneColumnWidth, alignment: .leading)
                .padding(8)
            ForEach(project.plotLines) { line in
                BeatCell(
                    session: session,
                    scene: scene,
                    line: line,
                    isGap: gapCells.contains(BeatKey(sceneID: scene.id, plotLineID: line.id))
                )
                .frame(width: Self.lineColumnWidth + 16, alignment: .topLeading)
            }
        }
        .overlay(alignment: .bottom) { Divider() }
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Add your first plot line")
                .font(.custom("Quattrocento-Bold", size: 16))
            Text("A plot line is a thread through the book: the main plot, a subplot, a character's arc. Each gets a column, and each cell holds what that scene does for it. Stretches without beats show where a thread goes quiet.")
                .font(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            Button("Add Plot Line") {
                project.addPlotLine()
                session.markDirty()
            }
            .padding(.top, 4)
        }
        .frame(maxWidth: 420, alignment: .leading)
        .padding(.top, 24)
    }

    private func gapHint(_ gap: PlotGap) -> some View {
        let line = project.plotLines.first { $0.id == gap.plotLineID }
        let first = gap.sceneIDs.first.flatMap(project.scene(withID:))?.title ?? ""
        let last = gap.sceneIDs.last.flatMap(project.scene(withID:))?.title ?? ""
        return HStack(alignment: .top, spacing: 10) {
            Circle()
                .fill(line?.tint.color ?? .secondary)
                .frame(width: 8, height: 8)
                .padding(.top, 5)
            VStack(alignment: .leading, spacing: 3) {
                Text("\(line?.title ?? "A plot line") goes quiet for \(gap.sceneIDs.count) scenes")
                    .font(.callout.weight(.semibold))
                Text("No beats from “\(first)” to “\(last)”. Worth reminding the reader what's at stake?")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Button {
                dismissedGap = gap
            } label: {
                Image(systemName: "xmark")
                    .font(.caption.weight(.semibold))
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
            .accessibilityLabel("Dismiss")
        }
        .padding(12)
        .frame(maxWidth: 340, alignment: .leading)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(Color(nsColor: .separatorColor)))
        .shadow(color: .black.opacity(0.15), radius: 10, y: 4)
    }

    // MARK: - Cards

    private var cardsView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                ForEach(Array(project.chapters.enumerated()), id: \.element.id) { index, chapter in
                    VStack(alignment: .leading, spacing: 10) {
                        ManuscriptLabel(
                            "\(RomanNumeral.format(index + 1)) · \(ManuscriptTitle.strippingNumbering(chapter.title))",
                            size: 10,
                            color: .secondary
                        )
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 220, maximum: 300), spacing: 12, alignment: .top)], alignment: .leading, spacing: 12) {
                            ForEach(chapter.scenes, id: \.id) { scene in
                                SceneCard(session: session, scene: scene)
                            }
                        }
                    }
                }
            }
            .padding(28)
        }
    }
}

// MARK: - Cells

private struct PlotLineHeader: View {
    let session: ProjectSession
    let line: PlotLine
    @State private var confirmingDelete = false

    private var project: Project { session.project }

    private var title: Binding<String> {
        Binding(
            get: { project.plotLines.first { $0.id == line.id }?.title ?? line.title },
            set: { newValue in
                guard let index = project.plotLines.firstIndex(where: { $0.id == line.id }) else { return }
                project.plotLines[index].title = newValue
                project.touch()
                session.markDirty()
            }
        )
    }

    var body: some View {
        HStack(spacing: 7) {
            RoundedRectangle(cornerRadius: 2)
                .fill(line.tint.color)
                .frame(width: 9, height: 9)
            TextField("Plot line", text: title)
                .textFieldStyle(.plain)
                .font(.custom("Quattrocento-Bold", size: 13))
        }
        .contextMenu {
            Picker("Color", selection: tintBinding) {
                ForEach(PlotLine.Tint.allCases, id: \.self) { tint in
                    Text(tint.name).tag(tint)
                }
            }
            Divider()
            Button("Delete Plot Line…", role: .destructive) { confirmingDelete = true }
        }
        .confirmationDialog(
            "Delete “\(line.title)” and its beats?",
            isPresented: $confirmingDelete,
            titleVisibility: .visible
        ) {
            Button("Delete Plot Line", role: .destructive) {
                project.deletePlotLine(line)
                session.markDirty()
            }
        }
    }

    private var tintBinding: Binding<PlotLine.Tint> {
        Binding(
            get: { line.tint },
            set: { tint in
                guard let index = project.plotLines.firstIndex(where: { $0.id == line.id }) else { return }
                project.plotLines[index].tint = tint
                project.touch()
                session.markDirty()
            }
        )
    }
}

private struct BeatCell: View {
    let session: ProjectSession
    let scene: Scene
    let line: PlotLine
    let isGap: Bool

    private var text: Binding<String> {
        Binding(
            get: { session.project.beat(scene: scene, line: line) },
            set: { newValue in
                session.project.setBeat(newValue, scene: scene, line: line)
                session.markDirty()
            }
        )
    }

    var body: some View {
        let hasBeat = !text.wrappedValue.isEmpty
        HStack(alignment: .top, spacing: 7) {
            RoundedRectangle(cornerRadius: 1.5)
                .fill(hasBeat ? line.tint.color : Color.clear)
                .frame(width: 3)
            TextField("", text: text, prompt: Text(isGap ? "No beat" : "").foregroundStyle(.quaternary), axis: .vertical)
                .textFieldStyle(.plain)
                .font(.callout)
                .foregroundStyle(.secondary)
                .lineLimit(1...5)
                .accessibilityLabel("\(line.title) in \(scene.title)")
        }
        .padding(8)
        .frame(maxWidth: .infinity, minHeight: 58, alignment: .topLeading)
        // Cells inside a quiet stretch of the line get a faint wash of its color.
        .background(isGap ? line.tint.color.opacity(0.07) : Color.clear)
    }
}

/// Status, title, words and point of view; opens the scene.
private struct SceneSummaryButton: View {
    let session: ProjectSession
    let scene: Scene

    var body: some View {
        Button {
            session.selectedItem = .scene(scene.id)
        } label: {
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    StatusDot(status: scene.status)
                    Text(scene.title)
                        .font(.custom("Quattrocento-Bold", size: 13))
                        .lineLimit(1)
                }
                Text(caption)
                    .font(.caption)
                    .monospacedDigit()
                    .foregroundStyle(.tertiary)
                if !scene.synopsis.isEmpty {
                    Text(scene.synopsis)
                        .font(.custom("Quattrocento", size: 12).italic())
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help("Open “\(scene.title)”")
    }

    private var caption: String {
        var parts = ["\(scene.wordCount.formatted()) words"]
        if let id = scene.povNoteID, let note = session.project.note(withID: id) {
            parts.append(note.title)
        }
        return parts.joined(separator: " · ")
    }
}

private struct SceneCard: View {
    let session: ProjectSession
    let scene: Scene
    @State private var isHovered = false

    private var threads: [PlotLine] {
        session.project.plotLines.filter { !session.project.beat(scene: scene, line: $0).isEmpty }
    }

    var body: some View {
        Button {
            session.selectedItem = .scene(scene.id)
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    StatusDot(status: scene.status)
                    Text(scene.title)
                        .font(.custom("Quattrocento-Bold", size: 14))
                        .lineLimit(2)
                }
                Text(scene.synopsis.isEmpty ? "No synopsis yet" : scene.synopsis)
                    .font(.custom("Quattrocento", size: 13).italic())
                    .foregroundStyle(scene.synopsis.isEmpty ? .tertiary : .secondary)
                    .lineLimit(4)
                    .frame(maxWidth: .infinity, minHeight: 50, alignment: .topLeading)
                HStack(spacing: 6) {
                    ForEach(threads) { line in
                        Circle().fill(line.tint.color).frame(width: 7, height: 7)
                            .help(line.title)
                    }
                    Spacer()
                    Text("\(scene.wordCount.formatted()) words")
                        .font(.caption)
                        .monospacedDigit()
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(12)
            .background(Color.primary.opacity(isHovered ? 0.06 : 0.035), in: RoundedRectangle(cornerRadius: 8))
            .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(Color(nsColor: .separatorColor).opacity(0.6)))
            .contentShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
    }
}
