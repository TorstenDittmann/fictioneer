import SwiftUI

struct WelcomeView: View {
    @Environment(AppModel.self) private var appModel
    @Environment(\.openSettings) private var openSettings
    @State private var showingNewProjectSheet = false

    var body: some View {
        HStack(spacing: 0) {
            heroPane
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            Divider()
            recentsPane
                .frame(width: 300)
                .background(.quinary)
        }
        .background(VisualEffectView().ignoresSafeArea())
        .navigationTitle("")
        .sheet(isPresented: $showingNewProjectSheet) {
            NewProjectSheet()
        }
        .alert(
            "Could Not Open Project",
            isPresented: Binding(
                get: { appModel.openError != nil },
                set: { if !$0 { appModel.openError = nil } }
            )
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(appModel.openError ?? "")
        }
    }

    private var heroPane: some View {
        VStack(spacing: 8) {
            Spacer()
            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .frame(width: 96, height: 96)
                .padding(.bottom, 4)
            Text("Fictioneer")
                .font(.custom("Quattrocento-Bold", size: 34))
            Text("A focused home for your novel.")
                .font(.system(size: 15, design: .serif).italic())
                .foregroundStyle(.secondary)
                .padding(.bottom, 28)

            VStack(spacing: 12) {
                Button {
                    showingNewProjectSheet = true
                } label: {
                    Label("Create New Project", systemImage: "plus")
                        .frame(minWidth: 180)
                }
                .controlSize(.large)
                .buttonStyle(.borderedProminent)
                .keyboardShortcut("n", modifiers: [.command, .shift])

                Button("Open Existing Project…") {
                    appModel.openProjectViaPanel()
                }
                .buttonStyle(.borderless)

                Button("Try the example project") {
                    appModel.createExampleProject()
                }
                .buttonStyle(.link)
                .font(.callout)
            }
            Spacer()

            if showsLicenseUpsell {
                licenseUpsellCard
                    .padding(.bottom, 8)
            }
        }
        .padding(40)
    }

    private var showsLicenseUpsell: Bool {
        appModel.settings.licenseKey.isEmpty && !appModel.settings.upsellDismissed
    }

    private var licenseUpsellCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            ManuscriptLabel("AI, in Pencil", size: 10, color: .manuscriptIndigo)
            Text("Suggestions and quiet continuations stay optional, always in pencil, never on autopilot. A license unlocks them — the words stay yours.")
                .font(.system(size: 12, design: .serif))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: 360, alignment: .leading)
            HStack(spacing: 10) {
                Button("Get a license") {
                    NSWorkspace.shared.open(AppConfig.checkoutURL)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)

                Button("Enter key") {
                    openSettings()
                }
                .buttonStyle(.borderless)
                .controlSize(.small)

                Spacer()

                Button("Maybe later") {
                    appModel.settings.upsellDismissed = true
                }
                .buttonStyle(.borderless)
                .controlSize(.small)
                .foregroundStyle(.tertiary)
            }
            .frame(maxWidth: 360)
        }
        .padding(14)
        .background(.quinary, in: RoundedRectangle(cornerRadius: 8))
        .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(.separator))
    }

    /// Recents minus projects already listed under iCloud Drive.
    private var localRecents: [RecentProject] {
        let cloudPaths = Set(appModel.cloud.projects.map { $0.url.standardizedFileURL.path })
        return appModel.recentProjects.filter { !cloudPaths.contains($0.url.standardizedFileURL.path) }
    }

    private var recentsPane: some View {
        VStack(alignment: .leading, spacing: 0) {
            if appModel.cloud.projects.isEmpty && localRecents.isEmpty {
                Spacer()
                Text("Projects you open will appear here.")
                    .font(.callout)
                    .foregroundStyle(.tertiary)
                    .frame(maxWidth: .infinity)
                Spacer()
            } else {
                List {
                    if !appModel.cloud.projects.isEmpty {
                        Section {
                            ForEach(appModel.cloud.projects) { item in
                                ProjectRow(
                                    title: item.title,
                                    url: item.url,
                                    modified: item.modified,
                                    status: item.hasConflicts ? .conflict : item.isDownloaded ? nil : .notDownloaded
                                )
                                .listRowSeparator(.hidden)
                            }
                        } header: {
                            ManuscriptLabel("iCloud Drive", size: 10)
                        }
                    }
                    if !localRecents.isEmpty {
                        Section {
                            ForEach(localRecents) { project in
                                ProjectRow(
                                    title: project.title,
                                    url: project.url,
                                    modified: project.modified,
                                    onRemove: { appModel.removeFromRecents(project) }
                                )
                                .listRowSeparator(.hidden)
                            }
                        } header: {
                            HStack {
                                ManuscriptLabel("Recent Projects", size: 10)
                                Spacer()
                                Button("Clear") {
                                    appModel.clearRecents()
                                }
                                .buttonStyle(.plain)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }

            if appModel.cloud.availability == .unavailable {
                Text("iCloud Drive is off. New projects are saved on this Mac.")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .padding(16)
            }
        }
        .padding(.top, 8)
    }
}

private struct ProjectRow: View {
    enum Status {
        case notDownloaded
        case conflict
    }

    @Environment(AppModel.self) private var appModel
    let title: String
    let url: URL
    let modified: Date?
    var status: Status?
    var onRemove: (() -> Void)?
    @State private var isHovered = false

    var body: some View {
        Button {
            appModel.openProject(at: url)
        } label: {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(title)
                    .font(.body.weight(.medium))
                    .lineLimit(1)
                    .layoutPriority(1)
                LeaderDots()
                    .frame(height: 13)
                statusIcon
                if let modified {
                    Text(modified, format: .relative(presentation: .named))
                        .font(.caption)
                        .monospacedDigit()
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 8)
            .help(url.path)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isHovered ? AnyShapeStyle(.quaternary) : AnyShapeStyle(.clear))
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
        .contextMenu {
            Button("Show in Finder") {
                NSWorkspace.shared.activateFileViewerSelecting([url])
            }
            if let onRemove {
                Button("Remove from Recents", action: onRemove)
            }
        }
    }

    @ViewBuilder
    private var statusIcon: some View {
        switch status {
        case .notDownloaded:
            Image(systemName: "icloud.and.arrow.down")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .help("Not downloaded yet. Opening it downloads it.")
                .accessibilityLabel("Not downloaded")
        case .conflict:
            Image(systemName: "exclamationmark.triangle")
                .font(.caption)
                .foregroundStyle(.orange)
                .help("Edited on two devices. Open it to choose which version to keep.")
                .accessibilityLabel("Has conflicting versions")
        case nil:
            EmptyView()
        }
    }
}
