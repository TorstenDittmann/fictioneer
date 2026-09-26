import Sparkle
import SwiftUI

@main
struct FictioneerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    private let appModel = AppModel.shared
    private let updaterController = SPUStandardUpdaterController(
        startingUpdater: true,
        updaterDelegate: nil,
        userDriverDelegate: nil
    )

    // Project windows belong to ProjectDocument (NSDocument) and the welcome
    // window to AppModel; SwiftUI only owns Settings and the menu commands.
    // `SwiftUI.Scene` is spelled out because the writing domain has its own `Scene` model.
    var body: some SwiftUI.Scene {
        Settings {
            SettingsView()
                .environment(appModel)
        }
        .commands {
            SidebarCommands()
            AppCommands(appModel: appModel)
            FormatCommands(appModel: appModel)
            CommandGroup(after: .appInfo) {
                Button("Check for Updates…") {
                    updaterController.checkForUpdates(nil)
                }
            }
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSDocumentController.shared.autosavingDelay = AppConfig.autosaveDelay
        let appModel = AppModel.shared
        appModel.migrateLegacyRecents()
        appModel.cloud.start()
        appModel.verifyLicenseIfNeeded()
        // Restored or Finder-opened documents arrive after launch finishes.
        DispatchQueue.main.async {
                if NSDocumentController.shared.documents.isEmpty {
                appModel.showWelcome()
            }
        }
    }

    /// The welcome window stands in for an untitled document.
    func applicationShouldOpenUntitledFile(_ sender: NSApplication) -> Bool {
        false
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag {
            AppModel.shared.showWelcome()
        }
        return false
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
            .disabled(appModel.activeSession == nil)

            Button("New Chapter") {
                newChapter()
            }
            .keyboardShortcut("n", modifiers: [.command, .shift])
            .disabled(appModel.activeSession == nil)

            Button("Split Scene at Cursor") {
                appModel.activeSession?.activeEditor?.onSplitScene?()
            }
            .keyboardShortcut(.return, modifiers: .command)
            .disabled(appModel.activeSession?.activeEditor == nil)

            Divider()

            Button("Open Project…") {
                appModel.openProjectViaPanel()
            }
            .keyboardShortcut("o", modifiers: .command)

            Menu("Open Recent") {
                ForEach(appModel.recentProjects) { project in
                    Button(project.title) {
                        appModel.openProject(at: project.url)
                    }
                }
                if !appModel.recentProjects.isEmpty {
                    Divider()
                }
                Button("Clear Menu") {
                    appModel.clearRecents()
                }
                .disabled(appModel.recentProjects.isEmpty)
            }
        }
        CommandGroup(after: .toolbar) {
            Button("Command Palette") {
                appModel.activeSession?.isCommandPaletteVisible.toggle()
            }
            .keyboardShortcut("k", modifiers: .command)
            .disabled(appModel.activeSession == nil)

            Button(appModel.activeSession?.isFocusMode == true ? "Exit Focus Mode" : "Enter Focus Mode") {
                appModel.activeSession?.isFocusMode.toggle()
            }
            .keyboardShortcut("f", modifiers: .command)
            .disabled(appModel.activeSession == nil)
        }
        CommandGroup(replacing: .saveItem) {
            Button("Close") {
                NSApp.keyWindow?.performClose(nil)
            }
            .keyboardShortcut("w", modifiers: .command)

            Button("Save") {
                sendToDocument("saveDocument:")
            }
            .keyboardShortcut("s", modifiers: .command)
            .disabled(appModel.activeSession == nil)

            Button("Duplicate") {
                sendToDocument("duplicateDocument:")
            }
            .keyboardShortcut("s", modifiers: [.command, .shift])
            .disabled(appModel.activeSession == nil)

            Button("Rename…") {
                sendToDocument("renameDocument:")
            }
            .disabled(appModel.activeSession == nil)

            Button("Move To…") {
                sendToDocument("moveDocument:")
            }
            .disabled(appModel.activeSession == nil)

            Menu("Revert To") {
                Button("Last Saved Version") {
                    sendToDocument("revertDocumentToSaved:")
                }
                Button("Browse All Versions…") {
                    sendToDocument("browseDocumentVersions:")
                }
            }
            .disabled(appModel.activeSession == nil)

            Divider()

            Button("Export…") {
                appModel.activeSession?.isExportSheetRequested = true
            }
            .keyboardShortcut("e", modifiers: [.command, .shift])
            .disabled(appModel.activeSession == nil)
        }
        // Replaces SwiftUI's default Help group: its "Fictioneer Help" opens a
        // help book the app doesn't ship, and a duplicate "Toggle Sidebar"
        // lands there (View ▸ Show/Hide Sidebar is the real one).
        CommandGroup(replacing: .help) {
            Button("Send Feedback…") {
                if let url = URL(string: "mailto:support@fictioneer.app") {
                    NSWorkspace.shared.open(url)
                }
            }
        }
    }

    private func newScene() {
        appModel.activeSession?.createSceneInCurrentChapter()
    }

    private func newChapter() {
        appModel.activeSession?.createChapter()
    }

    /// NSDocument's standard actions, routed through the responder chain to
    /// the key window's document.
    private func sendToDocument(_ action: String) {
        NSApp.sendAction(Selector(action), to: nil, from: nil)
    }
}

