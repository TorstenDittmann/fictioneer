import Foundation

/// An open project: the model, its on-disk location, dirty tracking, and
/// autosave (3s debounce after the last change, at most one save per 5s —
/// matching the Tauri app's cadence).
@Observable
final class ProjectSession {
    enum SaveState: Equatable {
        case saved(Date)
        case dirty
        case saving
        case failed(String)
    }

    let url: URL
    let project: Project
    private(set) var saveState: SaveState = .saved(.now)

    /// Sidebar/editor navigation state.
    var selectedSceneID: UUID?
    var selectedNoteID: UUID?

    private var dirtySceneIDs: Set<UUID> = []
    private var dirtyNoteIDs: Set<UUID> = []
    private var autosaveTask: Task<Void, Never>?
    private var lastSaveDate: Date?
    private let ownsSecurityScope: Bool

    init(url: URL, project: Project, ownsSecurityScope: Bool) {
        self.url = url
        self.project = project
        self.ownsSecurityScope = ownsSecurityScope
        self.selectedSceneID = project.lastOpenedSceneID ?? project.allScenes.first?.id
    }

    var hasPendingChanges: Bool {
        if case .dirty = saveState { return true }
        return !dirtySceneIDs.isEmpty || !dirtyNoteIDs.isEmpty
    }

    func markDirty(sceneID: UUID? = nil, noteID: UUID? = nil) {
        if let sceneID { dirtySceneIDs.insert(sceneID) }
        if let noteID { dirtyNoteIDs.insert(noteID) }
        saveState = .dirty
        scheduleAutosave()
    }

    func saveNow() {
        autosaveTask?.cancel()
        autosaveTask = nil
        performSave()
    }

    /// Flushes pending changes and releases the security scope. Call exactly once.
    func close() {
        autosaveTask?.cancel()
        autosaveTask = nil
        project.lastOpenedSceneID = selectedSceneID
        performSave(force: true)
        if ownsSecurityScope {
            url.stopAccessingSecurityScopedResource()
        }
    }

    private func scheduleAutosave() {
        autosaveTask?.cancel()
        var delay = AppConfig.autosaveDebounce
        if let lastSaveDate {
            let earliestNextSave = lastSaveDate.addingTimeInterval(AppConfig.autosaveThrottle)
            delay = max(delay, earliestNextSave.timeIntervalSince(.now))
        }
        autosaveTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(delay))
            guard !Task.isCancelled else { return }
            self?.performSave()
        }
    }

    private func performSave(force: Bool = false) {
        guard force || hasPendingChanges else { return }
        saveState = .saving
        do {
            try ProjectPackage.save(project, to: url, dirtySceneIDs: dirtySceneIDs, dirtyNoteIDs: dirtyNoteIDs)
            dirtySceneIDs = []
            dirtyNoteIDs = []
            lastSaveDate = .now
            saveState = .saved(.now)
        } catch {
            saveState = .failed(error.localizedDescription)
        }
    }
}
