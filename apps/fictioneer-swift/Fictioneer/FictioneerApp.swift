import Sparkle
import SwiftUI

@main
struct FictioneerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @State private var appModel = AppModel()
    private let updaterController = SPUStandardUpdaterController(
        startingUpdater: true,
        updaterDelegate: nil,
        userDriverDelegate: nil
    )

    // `SwiftUI.Scene` is spelled out because the writing domain has its own `Scene` model.
    var body: some SwiftUI.Scene {
        WindowGroup {
            RootView()
                .environment(appModel)
                .onAppear {
                    appDelegate.appModel = appModel
                }
        }
        .windowToolbarStyle(.unified)
        .defaultSize(width: 1100, height: 720)
        .commands {
            AppCommands(appModel: appModel)
            CommandGroup(after: .appInfo) {
                Button("Check for Updates…") {
                    updaterController.checkForUpdates(nil)
                }
            }
        }

        Settings {
            SettingsView()
                .environment(appModel)
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    var appModel: AppModel?

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }

    /// The final flush happens BEFORE termination proceeds, so a failed save
    /// can stop the quit instead of silently discarding work.
    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        guard let session = appModel?.session else { return .terminateNow }
        while !session.close() {
            let alert = NSAlert()
            alert.alertStyle = .critical
            alert.messageText = "Couldn't save “\(session.project.title)”"
            var informative = "The latest changes could not be written to disk."
            if let reason = session.saveFailureMessage {
                informative += "\n\n\(reason)"
            }
            alert.informativeText = informative
            alert.addButton(withTitle: "Try Again")
            alert.addButton(withTitle: "Quit Anyway")
            alert.addButton(withTitle: "Cancel")
            switch alert.runModal() {
            case .alertFirstButtonReturn:
                continue // Try Again
            case .alertSecondButtonReturn:
                session.closeDiscardingChanges()
                return .terminateNow
            default:
                return .terminateCancel
            }
        }
        appModel?.session = nil
        return .terminateNow
    }
}

struct RootView: View {
    @Environment(AppModel.self) private var appModel

    var body: some View {
        Group {
            if let session = appModel.session {
                ProjectWindowView(session: session)
                    .id(session.url)
            } else {
                WelcomeView()
                    .frame(minWidth: 800, minHeight: 540)
            }
        }
        .preferredColorScheme(appModel.settings.theme.colorScheme)
        .task {
            appModel.verifyLicenseIfNeeded()
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
        CommandGroup(after: .toolbar) {
            Button("Command Palette") {
                appModel.session?.isCommandPaletteVisible.toggle()
            }
            .keyboardShortcut("k", modifiers: .command)
            .disabled(appModel.session == nil)

            Button(appModel.session?.isFocusMode == true ? "Exit Focus Mode" : "Enter Focus Mode") {
                appModel.session?.isFocusMode.toggle()
            }
            .keyboardShortcut("f", modifiers: .command)
            .disabled(appModel.session == nil)
        }
        CommandGroup(replacing: .saveItem) {
            Button("Save") {
                appModel.session?.saveNow()
            }
            .keyboardShortcut("s", modifiers: .command)
            .disabled(appModel.session == nil)

            Button("Export…") {
                appModel.isExportSheetRequested = true
            }
            .keyboardShortcut("e", modifiers: [.command, .shift])
            .disabled(appModel.session == nil)

            Button("Close Project") {
                appModel.closeProject()
            }
            .keyboardShortcut("w", modifiers: .command)
            .disabled(appModel.session == nil)
        }
        CommandGroup(after: .help) {
            Button("Send Feedback…") {
                if let url = URL(string: "mailto:support@fictioneer.app") {
                    NSWorkspace.shared.open(url)
                }
            }
        }
    }

    private func newScene() {
        appModel.session?.createSceneInCurrentChapter()
    }

    private func newChapter() {
        appModel.session?.createChapter()
    }
}
