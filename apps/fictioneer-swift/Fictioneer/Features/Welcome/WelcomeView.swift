import SwiftUI

struct WelcomeView: View {
    @Environment(AppModel.self) private var appModel
    @State private var showingNewProjectSheet = false

    var body: some View {
        HStack(spacing: 0) {
            heroPane
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(.background)
            Divider()
            recentsPane
                .frame(width: 300)
                .background(.background.secondary)
        }
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
            Image(systemName: "book.pages")
                .font(.system(size: 56, weight: .light))
                .foregroundStyle(Color.accentColor)
                .padding(.bottom, 12)
            Text("Fictioneer")
                .font(.system(size: 34, weight: .bold, design: .serif))
            Text("A focused home for your novel.")
                .font(.title3)
                .foregroundStyle(.secondary)
                .padding(.bottom, 28)

            VStack(spacing: 12) {
                Button {
                    showingNewProjectSheet = true
                } label: {
                    Label("Create New Project", systemImage: "plus")
                        .frame(width: 220)
                }
                .controlSize(.large)
                .buttonStyle(.borderedProminent)
                .keyboardShortcut("n", modifiers: [.command, .shift])

                Button {
                    appModel.openProjectViaPanel()
                } label: {
                    Label("Open Existing Project", systemImage: "folder")
                        .frame(width: 220)
                }
                .controlSize(.large)
            }
            Spacer()
            Text("Hold ⌥ while writing for an AI continuation · ⌘S saves · autosave is always on")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .padding(.bottom, 20)
        }
        .padding(40)
    }

    private var recentsPane: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Recent Projects")
                    .font(.headline)
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
                }
                .listStyle(.sidebar)
                .scrollContentBackground(.hidden)
            }
        }
    }
}

private struct RecentProjectRow: View {
    @Environment(AppModel.self) private var appModel
    let entry: RecentProjectsStore.Entry

    var body: some View {
        Button {
            appModel.openRecent(entry)
        } label: {
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.title)
                    .font(.body.weight(.medium))
                    .lineLimit(1)
                HStack(spacing: 6) {
                    Text(entry.filename)
                        .lineLimit(1)
                    Text(entry.lastOpened, format: .relative(presentation: .named))
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            .padding(.vertical, 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button("Remove from Recents") {
                appModel.recents.remove(entry)
            }
        }
    }
}
