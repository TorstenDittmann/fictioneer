import SwiftUI

struct ProjectOverviewView: View {
    let session: ProjectSession

    private var project: Project { session.project }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(project.title)
                        .font(.system(size: 30, weight: .bold, design: .serif))
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
                            .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 10))
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
                Spacer()
            }
            .padding(.horizontal, 48)
            .frame(maxWidth: 720, alignment: .leading)
            .frame(maxWidth: .infinity)
        }
    }

    private var mostRecentScene: Scene? {
        project.allScenes.max { $0.updatedAt < $1.updatedAt }
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
        .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 10))
    }
}
