import SwiftUI

extension SceneStatus {
    /// Static colors, never the dynamic accent provider (see ProgressBar).
    var color: Color {
        switch self {
        case .idea: Color(nsColor: .tertiaryLabelColor)
        case .draft: Color(red: 0xE0 / 255, green: 0xA6 / 255, blue: 0x5A / 255)
        case .revised: .manuscriptIndigo
        case .done: Color(red: 0x3F / 255, green: 0xB0 / 255, blue: 0x7C / 255)
        }
    }
}

/// Hollow for Idea, filled for every later stage.
struct StatusDot: View {
    let status: SceneStatus
    var size: CGFloat = 7

    var body: some View {
        Group {
            if status == .idea {
                Circle().strokeBorder(status.color, lineWidth: 1.2)
            } else {
                Circle().fill(status.color)
            }
        }
        .frame(width: size, height: size)
        .accessibilityLabel(status.title)
    }
}

/// Lays children out left to right, wrapping onto new lines (label chips).
struct FlowLayout: Layout {
    var spacing: CGFloat = 6
    var lineSpacing: CGFloat = 6

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = arrange(width: proposal.width ?? .infinity, subviews: subviews)
        let width = rows.map(\.width).max() ?? 0
        let height = rows.map(\.height).reduce(0, +) + lineSpacing * CGFloat(max(rows.count - 1, 0))
        return CGSize(width: width, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var y = bounds.minY
        for row in arrange(width: bounds.width, subviews: subviews) {
            var x = bounds.minX
            for index in row.indices {
                let size = subviews[index].sizeThatFits(.unspecified)
                subviews[index].place(
                    at: CGPoint(x: x, y: y + (row.height - size.height) / 2),
                    proposal: ProposedViewSize(size)
                )
                x += size.width + spacing
            }
            y += row.height + lineSpacing
        }
    }

    private struct Row {
        var indices: [Int] = []
        var width: CGFloat = 0
        var height: CGFloat = 0
    }

    private func arrange(width: CGFloat, subviews: Subviews) -> [Row] {
        var rows: [Row] = [Row()]
        for index in subviews.indices {
            let size = subviews[index].sizeThatFits(.unspecified)
            let extra = rows[rows.count - 1].indices.isEmpty ? size.width : size.width + spacing
            if rows[rows.count - 1].width + extra > width, !rows[rows.count - 1].indices.isEmpty {
                rows.append(Row())
            }
            let isFirst = rows[rows.count - 1].indices.isEmpty
            rows[rows.count - 1].indices.append(index)
            rows[rows.count - 1].width += isFirst ? size.width : size.width + spacing
            rows[rows.count - 1].height = max(rows[rows.count - 1].height, size.height)
        }
        return rows.filter { !$0.indices.isEmpty }
    }
}

/// Editor for a scene's synopsis, status, point of view, labels and target.
/// Every change writes through and marks the project edited.
struct SceneDetailsEditor: View {
    let session: ProjectSession
    let scene: Scene
    /// Shown when the editor is the only place to rename the scene (the
    /// continuous chapter's heading popover).
    var showsTitle = false

    @State private var newLabel = ""

    private var project: Project { session.project }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            if showsTitle {
                field("Title") {
                    TextField("Untitled Scene", text: binding(\.title))
                        .textFieldStyle(.roundedBorder)
                }
            }
            field("Synopsis") {
                TextField("What happens in this scene?", text: binding(\.synopsis), axis: .vertical)
                    .lineLimit(3...6)
                    .textFieldStyle(.roundedBorder)
            }
            field("Status") {
                Picker("Status", selection: binding(\.status)) {
                    ForEach(SceneStatus.allCases) { status in
                        Text(status.title).tag(status)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
            }
            field("Point of view") {
                Picker("Point of view", selection: binding(\.povNoteID)) {
                    Text("None").tag(UUID?.none)
                    if !project.notes.isEmpty {
                        Divider()
                    }
                    ForEach(project.notes, id: \.id) { note in
                        Text(note.title).tag(UUID?.some(note.id))
                    }
                }
                .labelsHidden()
                .help("Characters come from your notes")
            }
            field("Labels") {
                VStack(alignment: .leading, spacing: 8) {
                    if !scene.labels.isEmpty {
                        FlowLayout {
                            ForEach(scene.labels, id: \.self) { label in
                                LabelChip(label: label) { remove(label) }
                            }
                        }
                    }
                    TextField("Add a label", text: $newLabel)
                        .textFieldStyle(.roundedBorder)
                        .onSubmit(addLabel)
                }
            }
            field("Target") {
                HStack {
                    TextField("No target", value: binding(\.targetWords), format: .number)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 100)
                    Text("words")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(16)
        .frame(width: 320, alignment: .leading)
    }

    private func field<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            ManuscriptLabel(title, size: 10)
            content()
        }
    }

    private func binding<Value>(_ keyPath: ReferenceWritableKeyPath<Scene, Value>) -> Binding<Value> {
        Binding(
            get: { scene[keyPath: keyPath] },
            set: { newValue in
                scene[keyPath: keyPath] = newValue
                touch()
            }
        )
    }

    private func addLabel() {
        let label = newLabel.trimmingCharacters(in: .whitespacesAndNewlines)
        newLabel = ""
        guard !label.isEmpty, !scene.labels.contains(where: { $0.caseInsensitiveCompare(label) == .orderedSame }) else {
            return
        }
        scene.labels.append(label)
        touch()
    }

    private func remove(_ label: String) {
        scene.labels.removeAll { $0 == label }
        touch()
    }

    private func touch() {
        scene.updatedAt = .now
        session.markDirty()
    }
}

private struct LabelChip: View {
    let label: String
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 4) {
            Text(label)
            Button(action: onRemove) {
                Image(systemName: "xmark")
                    .font(.system(size: 8, weight: .bold))
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
            .accessibilityLabel("Remove \(label)")
        }
        .font(.caption)
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(.quaternary.opacity(0.5), in: Capsule())
    }
}
