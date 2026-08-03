import SwiftUI

struct WelcomeView: View {
    @Environment(AppModel.self) private var appModel
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
        }
        .padding(40)
    }

    private var recentsPane: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                ManuscriptLabel("Recent Projects", size: 10)
                Spacer()
                if !appModel.recents.entries.isEmpty {
                    Button("Clear") {
                        appModel.recents.clear()
                    }
                    .buttonStyle(.plain)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)

            if appModel.recents.entries.isEmpty {
                Spacer()
                Text("Projects you open will appear here.")
                    .font(.callout)
                    .foregroundStyle(.tertiary)
                    .frame(maxWidth: .infinity)
                Spacer()
            } else {
                List(appModel.recents.entries) { entry in
                    RecentProjectRow(entry: entry)
                        .listRowSeparator(.hidden)
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
        }
    }
}

private struct RecentProjectRow: View {
    @Environment(AppModel.self) private var appModel
    let entry: RecentProjectsStore.Entry
    @State private var isHovered = false

    var body: some View {
        Button {
            appModel.openRecent(entry)
        } label: {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(entry.title)
                    .font(.body.weight(.medium))
                    .lineLimit(1)
                    .layoutPriority(1)
                LeaderDots()
                    .frame(height: 13)
                Text(entry.lastOpened, format: .relative(presentation: .named))
                    .font(.caption)
                    .monospacedDigit()
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 8)
            .help(entry.filename)
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
            Button("Remove from Recents") {
                appModel.recents.remove(entry)
            }
        }
    }
}
