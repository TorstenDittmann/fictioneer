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
    var openError: String?

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
        session?.close()
        session = ProjectSession(url: url, project: project, ownsSecurityScope: ownsSecurityScope)
        recents.noteOpened(url: url, title: project.title)
        NSDocumentController.shared.noteNewRecentDocumentURL(url)
    }

    func closeProject() {
        session?.close()
        session = nil
    }
}
