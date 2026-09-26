import AppKit
import Foundation
import SwiftUI
import UniformTypeIdentifiers

extension UTType {
    static let fictioneerProject = UTType(exportedAs: "app.fictioneer.project")
}

/// A project in File ▸ Open Recent, as the welcome window lists it.
struct RecentProject: Identifiable, Equatable {
    let url: URL
    var id: URL { url }
    var title: String { url.deletingPathExtension().lastPathComponent }
    var modified: Date? {
        try? url.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate
    }
}

/// App-wide state. Each open project is a ProjectDocument with its own
/// window; `activeDocument` follows the key window so menu commands act on
/// the project in front.
@Observable
final class AppModel {
    static let shared = AppModel()

    let settings = AppSettings()
    let license = LicenseManager()
    let cloud = CloudProjectLibrary()
    var openError: String?
    var activeDocument: ProjectDocument?
    private(set) var recentProjects: [RecentProject] = []

    @ObservationIgnored private lazy var welcomeWindow = WelcomeWindowController()

    var activeSession: ProjectSession? {
        activeDocument?.session
    }

    /// Re-verifies a persisted license key on launch.
    func verifyLicenseIfNeeded() {
        guard license.status == .unknown, !settings.licenseKey.isEmpty else { return }
        license.verify(key: settings.licenseKey, baseURL: settings.intelligenceBaseURL)
    }

    // MARK: - Creating and opening

    /// New projects go to iCloud Drive ▸ Fictioneer when it's available and
    /// the writer didn't opt out; otherwise a save panel picks a local spot.
    func createProject(title: String, details: String, inCloud: Bool = true) {
        let name = title.isEmpty ? "Untitled" : title
        create(Project.makeNew(title: name, details: details), named: name, inCloud: inCloud, panelTitle: "Create Project")
    }

    func createExampleProject() {
        do {
            let project = try ExampleProjectFactory.build()
            create(project, named: project.title, inCloud: true, panelTitle: "Save Example Project")
        } catch {
            openError = error.localizedDescription
        }
    }

    func openProjectViaPanel() {
        NSDocumentController.shared.openDocument(nil)
    }

    func openProject(at url: URL) {
        NSDocumentController.shared.openDocument(withContentsOf: url, display: true) { [weak self] _, _, error in
            guard let error else { return }
            MainActor.assumeIsolated {
                self?.openError = error.localizedDescription
                self?.refreshRecents()
            }
        }
    }

    private func runSavePanel(title: String, filename: String) -> URL? {
        let panel = NSSavePanel()
        panel.title = title
        panel.nameFieldStringValue = filename
        panel.allowedContentTypes = [.fictioneerProject]
        panel.canCreateDirectories = true
        guard panel.runModal() == .OK else { return nil }
        return panel.url
    }

    private func create(_ project: Project, named name: String, inCloud: Bool, panelTitle: String) {
        do {
            if inCloud, cloud.documentsURL != nil {
                openProject(at: try cloud.createProject(project, named: name))
                return
            }
            guard let url = runSavePanel(title: panelTitle, filename: name) else { return }
            try ProjectPackage.write(project, to: url)
            openProject(at: url)
        } catch {
            openError = error.localizedDescription
        }
    }

    // MARK: - Document lifecycle

    func documentDidOpen(_ document: ProjectDocument) {
        activeDocument = document
        welcomeWindow.close()
        refreshRecents()
    }

    func documentDidClose(_ document: ProjectDocument) {
        if activeDocument === document {
            activeDocument = nil
        }
        if NSDocumentController.shared.documents.isEmpty {
            showWelcome()
        }
    }

    func showWelcome() {
        refreshRecents()
        NSApp.activate()
        welcomeWindow.showWindow(nil)
        welcomeWindow.window?.makeKeyAndOrderFront(nil)
    }

    // MARK: - Recents (backed by NSDocumentController, so sandboxed re-opens
    // and File ▸ Open Recent share one list)

    func refreshRecents() {
        recentProjects = NSDocumentController.shared.recentDocumentURLs.map(RecentProject.init)
    }

    func removeFromRecents(_ project: RecentProject) {
        let controller = NSDocumentController.shared
        let remaining = controller.recentDocumentURLs.filter { $0 != project.url }
        controller.clearRecentDocuments(nil)
        // Re-noting oldest first keeps the original order.
        for url in remaining.reversed() {
            controller.noteNewRecentDocumentURL(url)
        }
        refreshRecents()
    }

    func clearRecents() {
        NSDocumentController.shared.clearRecentDocuments(nil)
        refreshRecents()
    }

    /// One-time move of the pre-NSDocument bookmark list into the system
    /// recents, oldest first so the most recent ends up on top.
    func migrateLegacyRecents(defaults: UserDefaults = .standard) {
        let migratedKey = "fictioneer.recentProjectsMigrated"
        guard !defaults.bool(forKey: migratedKey) else { return }
        let legacy = RecentProjectsStore(defaults: defaults)
        for entry in legacy.entries.reversed() {
            guard let url = legacy.beginAccess(to: entry) else { continue }
            NSDocumentController.shared.noteNewRecentDocumentURL(url)
            url.stopAccessingSecurityScopedResource()
        }
        legacy.clear()
        defaults.set(true, forKey: migratedKey)
    }
}

/// The welcome window: shown at launch and whenever no project is open.
final class WelcomeWindowController: NSWindowController {
    init() {
        let hosting = NSHostingController(
            rootView: WelcomeView()
                .environment(AppModel.shared)
                .frame(minWidth: 800, minHeight: 540)
        )
        hosting.sizingOptions = [.minSize]
        let window = NSWindow(contentViewController: hosting)
        window.styleMask = [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView]
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.title = "Welcome to Fictioneer"
        window.setContentSize(NSSize(width: 900, height: 580))
        window.isReleasedWhenClosed = false
        window.center()
        window.setFrameAutosaveName("Welcome")
        super.init(window: window)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }
}
