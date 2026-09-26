import Foundation

/// Sidebar navigation target. `.note` deliberately preserves the scene
/// selection underneath — ⌘N chapter targeting and `lastOpenedSceneID`
/// restoration read `selectedSceneID` even while a note is open.
enum SidebarItem: Hashable {
    case overview
    case search
    case scene(UUID)
    case note(UUID)
}

/// An open project's model plus per-window UI state and dirty tracking.
/// Persistence (autosave in place, versions, iCloud coordination) belongs to
/// the owning ProjectDocument, which drives `beginSave`/`endSave`.
@Observable
final class ProjectSession {
    enum SaveState: Equatable {
        case saved(Date)
        case dirty
        case saving
        case failed(String)
    }

    let project: Project
    let progress: ProgressTracker
    private(set) var saveState: SaveState = .saved(.now)

    /// Sidebar/editor navigation state.
    var selectedSceneID: UUID?
    var selectedNoteID: UUID?
    var showsSearch = false
    var isCommandPaletteVisible = false
    var isFocusMode = false
    /// Set by File ▸ Export… and the command palette; this window's sheet.
    var isExportSheetRequested = false
    /// The editor currently shown (scene or note), targeted by the Format
    /// menu. Set by the editor views on appear.
    weak var activeEditor: EditorController?

    /// Bridge for the sidebar's native `List(selection:)`.
    var selectedItem: SidebarItem? {
        get {
            if showsSearch { return .search }
            return selectedNoteID.map(SidebarItem.note)
                ?? selectedSceneID.map(SidebarItem.scene)
                ?? .overview
        }
        set {
            switch newValue {
            case .overview:
                showsSearch = false
                selectedNoteID = nil
                selectedSceneID = nil
            case .search:
                // Scene selection is preserved beneath search, like notes.
                showsSearch = true
                selectedNoteID = nil
            case .scene(let id):
                showsSearch = false
                selectedNoteID = nil
                selectedSceneID = id
            case .note(let id):
                showsSearch = false
                selectedNoteID = id
            case nil:
                // List can emit nil transiently (⌘-click deselect, row removal);
                // bouncing to Overview would be surprise navigation.
                break
            }
        }
    }

    // MARK: - Shared creation actions (menu commands, sidebar, ⌘K palette)

    @discardableResult
    func createChapter() -> Chapter {
        let chapter = project.addChapter()
        chapter.isExpanded = true
        markDirty()
        return chapter
    }

    /// Adds a scene to the chapter of the current scene (falling back to the
    /// last chapter) and selects it.
    @discardableResult
    func createSceneInCurrentChapter() -> Scene? {
        let chapter: Chapter?
        if let selected = selectedSceneID, let current = project.chapter(containing: selected) {
            chapter = current
        } else {
            chapter = project.chapters.last
        }
        guard let chapter else { return nil }
        return createScene(in: chapter)
    }

    @discardableResult
    func createScene(in chapter: Chapter) -> Scene {
        let scene = project.addScene(to: chapter)
        chapter.isExpanded = true
        selectedItem = .scene(scene.id)
        markDirty(sceneID: scene.id)
        return scene
    }

    @discardableResult
    func createNote() -> Note {
        let note = project.addNote()
        selectedItem = .note(note.id)
        markDirty(noteID: note.id)
        return note
    }

    /// What a save captured, so edits made while it was in flight stay dirty.
    struct SaveSnapshot {
        let sceneIDs: Set<UUID>
        let noteIDs: Set<UUID>
        let generation: Int
    }

    /// Archives that changed since the last successful save.
    private(set) var dirtySceneIDs: Set<UUID> = []
    private(set) var dirtyNoteIDs: Set<UUID> = []
    /// Bumped on every change; a save only clears what it actually captured.
    private var changeGeneration = 0
    private var savedGeneration = 0

    /// Wired by the document: a change marks it edited (which schedules the
    /// autosave), a save request flushes immediately.
    @ObservationIgnored var onChange: (() -> Void)?
    @ObservationIgnored var onSaveRequest: (() -> Void)?

    init(project: Project) {
        self.project = project
        self.progress = ProgressTracker(project: project)
        self.selectedSceneID = project.lastOpenedSceneID ?? project.allScenes.first?.id
    }

    var hasPendingChanges: Bool {
        changeGeneration != savedGeneration || !dirtySceneIDs.isEmpty || !dirtyNoteIDs.isEmpty
    }

    func markDirty(sceneID: UUID? = nil, noteID: UUID? = nil) {
        if let sceneID { dirtySceneIDs.insert(sceneID) }
        if let noteID { dirtyNoteIDs.insert(noteID) }
        changeGeneration += 1
        saveState = .dirty
        onChange?()
    }

    func saveNow() {
        onSaveRequest?()
    }

    /// The human-readable reason of the last failed save, if any.
    var saveFailureMessage: String? {
        if case .failed(let message) = saveState { return message }
        return nil
    }

    // MARK: - Save protocol (driven by ProjectDocument)

    func beginSave() -> SaveSnapshot {
        project.lastOpenedSceneID = selectedSceneID
        saveState = .saving
        return SaveSnapshot(sceneIDs: dirtySceneIDs, noteIDs: dirtyNoteIDs, generation: changeGeneration)
    }

    func endSave(_ snapshot: SaveSnapshot, error: Error?) {
        if let error {
            saveState = .failed(error.localizedDescription)
            return
        }
        dirtySceneIDs.subtract(snapshot.sceneIDs)
        dirtyNoteIDs.subtract(snapshot.noteIDs)
        savedGeneration = snapshot.generation
        saveState = hasPendingChanges ? .dirty : .saved(.now)
    }

    /// Carries navigation over when the document reloads (revert, a newer
    /// version from iCloud), so the writer stays where they were.
    func adoptNavigation(from other: ProjectSession) {
        if let id = other.selectedSceneID, project.scene(withID: id) != nil {
            selectedSceneID = id
        }
        if let id = other.selectedNoteID, project.note(withID: id) != nil {
            selectedNoteID = id
        }
        showsSearch = other.showsSearch
        isFocusMode = other.isFocusMode
    }
}
