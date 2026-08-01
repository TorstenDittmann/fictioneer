import SwiftUI

struct ProjectOverviewView: View {
    let session: ProjectSession

    private var project: Project { session.project }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(project.title)
                        .font(.custom("Quattrocento-Bold", size: 30))
                    if !project.details.isEmpty {
                        Text(project.details)
                            .font(.title3)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.top, 32)

                HStack(spacing: 12) {
                    StatTile(value: project.chapters.count, label: "Chapters")
                    StatTile(value: project.allScenes.count, label: "Scenes")
                    StatTile(value: project.totalWordCount, label: "Words")
                    StatTile(value: project.notes.count, label: "Notes")
                }

                if let scene = mostRecentScene {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Pick up where you left off")
                            .font(.headline)
                        ContinueWritingCard(session: session, scene: scene)
                    }
                }
                Spacer()
            }
            .padding(.horizontal, 48)
            .frame(maxWidth: 720, alignment: .leading)
            .frame(maxWidth: .infinity)
        }
        .navigationTitle("Overview")
        .navigationSubtitle(project.title)
    }

    private var mostRecentScene: Scene? {
        project.allScenes.max { $0.updatedAt < $1.updatedAt }
    }
}

private struct ContinueWritingCard: View {
    let session: ProjectSession
    let scene: Scene
    @State private var isHovered = false

    var body: some View {
        Button {
            session.selectedNoteID = nil
            session.selectedSceneID = scene.id
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text(scene.title)
                        .font(.body.weight(.medium))
                    Text("\(scene.wordCount) words · updated \(scene.updatedAt, format: .relative(presentation: .named))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "arrow.right")
                    .foregroundStyle(Color.accentColor)
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isHovered ? AnyShapeStyle(.quaternary) : AnyShapeStyle(.clear))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(.separator)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
    }
}

private struct StatTile: View {
    let value: Int
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            Text("\(value)")
                .font(.title2.weight(.semibold))
                .monospacedDigit()
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(.separator)
        )
    }
}
