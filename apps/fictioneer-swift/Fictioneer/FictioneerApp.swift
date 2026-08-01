import SwiftUI

@main
struct FictioneerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @State private var appModel = AppModel()

    // `SwiftUI.Scene` is spelled out because the writing domain has its own `Scene` model.
    var body: some SwiftUI.Scene {
        WindowGroup {
            RootView()
                .environment(appModel)
                .onAppear {
                    appDelegate.appModel = appModel
                }
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 1100, height: 720)
        .commands {
            AppCommands(appModel: appModel)
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    var appModel: AppModel?

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }

    func applicationWillTerminate(_ notification: Notification) {
        appModel?.session?.close()
    }
}

struct RootView: View {
    @Environment(AppModel.self) private var appModel

    var body: some View {
        if let session = appModel.session {
            ProjectWindowView(session: session)
                .id(session.url)
        } else {
            WelcomeView()
                .frame(minWidth: 800, minHeight: 540)
        }
    }
}

struct AppCommands: Commands {
    let appModel: AppModel

    var body: some Commands {
        CommandGroup(replacing: .newItem) {
            Button("New Scene") {
                newScene()
            }
            .keyboardShortcut("n", modifiers: .command)
            .disabled(appModel.session == nil)

            Button("New Chapter") {
                newChapter()
            }
            .keyboardShortcut("n", modifiers: [.command, .shift])
            .disabled(appModel.session == nil)

            Divider()

            Button("Open Project…") {
                appModel.openProjectViaPanel()
            }
            .keyboardShortcut("o", modifiers: .command)
        }
        CommandGroup(replacing: .saveItem) {
            Button("Save") {
                appModel.session?.saveNow()
            }
            .keyboardShortcut("s", modifiers: .command)
            .disabled(appModel.session == nil)

            Button("Close Project") {
                appModel.closeProject()
            }
            .keyboardShortcut("w", modifiers: .command)
            .disabled(appModel.session == nil)
        }
    }

    private func newScene() {
        guard let session = appModel.session else { return }
        let project = session.project
        let chapter: Chapter?
        if let selected = session.selectedSceneID, let current = project.chapter(containing: selected) {
            chapter = current
        } else {
            chapter = project.chapters.last
        }
        guard let chapter else { return }
        let scene = project.addScene(to: chapter)
        chapter.isExpanded = true
        session.selectedNoteID = nil
        session.selectedSceneID = scene.id
        session.markDirty(sceneID: scene.id)
    }

    private func newChapter() {
        guard let session = appModel.session else { return }
        session.project.addChapter()
        session.markDirty()
    }
}
