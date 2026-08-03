import SwiftUI

/// The project's title page: centered title, epigraph, and a small-caps stat
/// line on a manuscript sheet, followed by the progress dashboard.
struct ProjectOverviewView: View {
    let session: ProjectSession
    @State private var showingExportSheet = false

    private var project: Project { session.project }

    var body: some View {
        ManuscriptPage(header: ManuscriptPageHeader(project: project.title, title: "Overview")) {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    titlePage

                    HStack(spacing: 12) {
                        StatTile(value: project.chapters.count, label: "Chapters")
                        StatTile(value: project.allScenes.count, label: "Scenes")
                        StatTile(value: project.totalWordCount, label: "Words")
                        StatTile(value: project.notes.count, label: "Notes")
                    }

                    ProgressDashboardView(session: session)

                    VStack(alignment: .leading, spacing: 8) {
                        ManuscriptLabel("Export")
                        HStack {
                            Text("Compile the manuscript as RTF, EPUB, or plain text.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Button("Export Project…") {
                                showingExportSheet = true
                            }
                            .controlSize(.small)
                        }
                        .padding(12)
                        .overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(.separator))
                    }
                    .sheet(isPresented: $showingExportSheet) {
                        ExportSheet(session: session)
                    }

                    if let scene = mostRecentScene {
                        VStack(alignment: .leading, spacing: 8) {
                            ManuscriptLabel("Pick up where you left off")
                            ContinueWritingCard(session: session, scene: scene)
                        }
                    }
                    Spacer()
                }
                .padding(.horizontal, 48)
                .padding(.bottom, 32)
                .frame(maxWidth: 720, alignment: .leading)
                .frame(maxWidth: .infinity)
            }
            .background(Color(nsColor: EditorTheme.paperBackground))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(VisualEffectView().ignoresSafeArea())
        .navigationTitle("Overview")
        .navigationSubtitle(project.title)
    }

    private var titlePage: some View {
        VStack(spacing: 12) {
            Text(project.title)
                .font(.custom("Quattrocento-Bold", size: 34))
                .multilineTextAlignment(.center)
            if !project.details.isEmpty {
                Text(project.details)
                    .font(.system(size: 15, design: .serif).italic())
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 460)
            }
            ManuscriptLabel(statLine, color: Color(nsColor: .tertiaryLabelColor))
                .monospacedDigit()
                .padding(.top, 4)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 44)
        .padding(.bottom, 12)
    }

    private var statLine: String {
        let chapters = project.chapters.count
        let scenes = project.allScenes.count
        return "\(chapters) chapter\(chapters == 1 ? "" : "s")"
            + " · \(scenes) scene\(scenes == 1 ? "" : "s")"
            + " · \(project.totalWordCount.formatted()) words"
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
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "arrow.right")
                    .foregroundStyle(Color.manuscriptIndigo)
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isHovered ? AnyShapeStyle(.quaternary) : AnyShapeStyle(.clear))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 6)
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
            Text(value.formatted())
                .font(.title2.weight(.semibold))
                .monospacedDigit()
            ManuscriptLabel(label, size: 9, color: Color(nsColor: .tertiaryLabelColor))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .strokeBorder(.separator)
        )
    }
}
