import AppKit
import Foundation
import UniformTypeIdentifiers

extension UTType {
    static let fictioneerProject = UTType(exportedAs: "app.fictioneer.project")
}

@Observable
final class AppModel {
    var session: ProjectSession?
    let recents = RecentProjectsStore()
    let settings = AppSettings()
    let license = LicenseManager()
    var openError: String?
    /// Set by the File ▸ Export… menu command; consumed by ProjectWindowView.
    var isExportSheetRequested = false

    /// Re-verifies a persisted license key on launch.
    func verifyLicenseIfNeeded() {
        guard license.status == .unknown, !settings.licenseKey.isEmpty else { return }
        license.verify(key: settings.licenseKey, baseURL: settings.intelligenceBaseURL)
    }

    // MARK: - Lifecycle

    func createProject(title: String, details: String) {
        let panel = NSSavePanel()
        panel.title = "Create Project"
        panel.nameFieldStringValue = title.isEmpty ? "Untitled" : title
        panel.allowedContentTypes = [.fictioneerProject]
        panel.canCreateDirectories = true
        guard panel.runModal() == .OK, let url = panel.url else { return }

        let project = Project.makeNew(title: title.isEmpty ? "Untitled" : title, details: details)
        do {
            try ProjectPackage.write(project, to: url)
            openSession(url: url, project: project, ownsSecurityScope: false)
        } catch {
            openError = error.localizedDescription
        }
    }

    func createExampleProject() {
        let panel = NSSavePanel()
        panel.title = "Save Example Project"
        panel.nameFieldStringValue = "The Bohemian Photograph Affair"
        panel.allowedContentTypes = [.fictioneerProject]
        panel.canCreateDirectories = true
        guard panel.runModal() == .OK, let url = panel.url else { return }
        do {
            let project = try ExampleProjectFactory.build()
            try ProjectPackage.write(project, to: url)
            openSession(url: url, project: project, ownsSecurityScope: false)
        } catch {
            openError = error.localizedDescription
        }
    }

    func openProjectViaPanel() {
        let panel = NSOpenPanel()
        panel.title = "Open Project"
        panel.allowedContentTypes = [.fictioneerProject]
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        guard panel.runModal() == .OK, let url = panel.url else { return }
        openProject(at: url, ownsSecurityScope: false)
    }

    func openRecent(_ entry: RecentProjectsStore.Entry) {
        guard let url = recents.beginAccess(to: entry) else {
            openError = "\(entry.title) could not be found. It may have been moved or deleted."
            return
        }
        openProject(at: url, ownsSecurityScope: true)
    }

    private func openProject(at url: URL, ownsSecurityScope: Bool) {
        do {
            let project = try ProjectPackage.read(from: url)
            openSession(url: url, project: project, ownsSecurityScope: ownsSecurityScope)
        } catch {
            if ownsSecurityScope {
                url.stopAccessingSecurityScopedResource()
            }
            openError = error.localizedDescription
        }
    }

    private func openSession(url: URL, project: Project, ownsSecurityScope: Bool) {
        if let existing = session {
            closeReportingFailure(existing)
        }
        session = ProjectSession(url: url, project: project, ownsSecurityScope: ownsSecurityScope)
        recents.noteOpened(url: url, title: project.title)
        NSDocumentController.shared.noteNewRecentDocumentURL(url)
    }

    func closeProject() {
        guard let session else { return }
        closeReportingFailure(session)
        self.session = nil
    }

    /// Closes a session; if the final save fails, the user chooses between
    /// retrying and closing anyway — unsaved work is never dropped silently.
    private func closeReportingFailure(_ session: ProjectSession) {
        while !session.close() {
            if presentSaveFailureAlert(for: session) == .alertFirstButtonReturn {
                continue // Try Again
            }
            session.closeDiscardingChanges()
            return
        }
    }

    private func presentSaveFailureAlert(for session: ProjectSession) -> NSApplication.ModalResponse {
        let alert = NSAlert()
        alert.alertStyle = .critical
        alert.messageText = "Couldn't save “\(session.project.title)”"
        var informative = "The latest changes could not be written to disk."
        if let reason = session.saveFailureMessage {
            informative += "\n\n\(reason)"
        }
        alert.informativeText = informative
        alert.addButton(withTitle: "Try Again")
        alert.addButton(withTitle: "Close Anyway")
        return alert.runModal()
    }
}
