import AppKit
import SwiftUI

/// Holds the document's current session. A reload (Revert To, a newer version
/// arriving from iCloud) swaps in a fresh session; the window observes this
/// and rebuilds its content.
@Observable
final class ProjectDocumentState {
    var session: ProjectSession?
}

/// A `.fictioneer` package as an NSDocument: autosave in place, version
/// history, file coordination, and (with iCloud) remote-change reloads come
/// from AppKit. Saving is incremental — see `ProjectPackage.fileWrapper`.
///
/// NSDocument's overrides are nonisolated in the SDK. Reading and writing run
/// on the main thread here (no concurrent reading, no asynchronous writing —
/// the defaults), so each override asserts main-actor isolation.
@objc(ProjectDocument)
final class ProjectDocument: NSDocument {
    let state = ProjectDocumentState()

    /// The tree last read or successfully written; unchanged archives are
    /// reused from it so only edited scenes/notes are rewritten.
    private var packageWrapper: FileWrapper?
    /// The in-flight save: what it captured and the tree it produced.
    private var pendingSave: (snapshot: ProjectSession.SaveSnapshot, wrapper: FileWrapper)?

    var session: ProjectSession? { state.session }

    nonisolated override class var autosavesInPlace: Bool { true }

    // MARK: - Reading

    nonisolated override func read(from fileWrapper: FileWrapper, ofType typeName: String) throws {
        nonisolated(unsafe) let fileWrapper = fileWrapper
        try MainActor.assumeIsolated {
            let project = try ProjectPackage.read(from: fileWrapper)
            packageWrapper = fileWrapper
            let session = ProjectSession(project: project)
            if let previous = state.session {
                session.adoptNavigation(from: previous)
            }
            attach(session)
        }
    }

    /// For documents created in code (new project, example project).
    convenience init(project: Project) {
        self.init()
        attach(ProjectSession(project: project))
    }

    private func attach(_ session: ProjectSession) {
        session.onChange = { [weak self] in
            self?.updateChangeCount(.changeDone)
        }
        session.onSaveRequest = { [weak self] in
            self?.autosave(withImplicitCancellability: false) { _ in }
        }
        state.session = session
    }

    // MARK: - Writing

    nonisolated override func fileWrapper(ofType typeName: String) throws -> FileWrapper {
        // FileWrapper isn't Sendable, so it can't be returned out of
        // assumeIsolated; it never leaves the main thread either way.
        nonisolated(unsafe) var result: Result<FileWrapper, Error>?
        MainActor.assumeIsolated {
            result = Result { try makePackageWrapper() }
        }
        return try result!.get()
    }

    private func makePackageWrapper() throws -> FileWrapper {
        guard let session else { throw CocoaError(.fileWriteUnknown) }
        let snapshot = session.beginSave()
        do {
            let wrapper = try ProjectPackage.fileWrapper(
                for: session.project,
                reusing: packageWrapper,
                dirtySceneIDs: snapshot.sceneIDs,
                dirtyNoteIDs: snapshot.noteIDs
            )
            pendingSave = (snapshot, wrapper)
            return wrapper
        } catch {
            session.endSave(snapshot, error: error)
            throw error
        }
    }

    /// The completion is the only reliable success signal: a safe save can
    /// still fail after the data was written (the final swap into place), and
    /// pending changes must then stay pending.
    nonisolated override func save(
        to url: URL,
        ofType typeName: String,
        for saveOperation: NSDocument.SaveOperationType,
        completionHandler: @escaping (Error?) -> Void
    ) {
        // AppKit calls the completion on the main thread; neither value
        // crosses threads.
        nonisolated(unsafe) let completionHandler = completionHandler
        nonisolated(unsafe) let document = self
        let handler: @Sendable (Error?) -> Void = { error in
            MainActor.assumeIsolated {
                document.finishSave(error: error)
            }
            completionHandler(error)
        }
        super.save(to: url, ofType: typeName, for: saveOperation, completionHandler: handler)
    }

    private func finishSave(error: Error?) {
        guard let pending = pendingSave else { return }
        pendingSave = nil
        if error == nil {
            packageWrapper = pending.wrapper
        }
        session?.endSave(pending.snapshot, error: error)
    }

    /// Edits the session tracks outside the undo manager (renames, reorders,
    /// settings) must still count as unsaved.
    nonisolated override var isDocumentEdited: Bool {
        super.isDocumentEdited || MainActor.assumeIsolated { session?.hasPendingChanges ?? false }
    }

    nonisolated override var hasUnautosavedChanges: Bool {
        super.hasUnautosavedChanges || MainActor.assumeIsolated { session?.hasPendingChanges ?? false }
    }

    // MARK: - Remote changes

    /// The document is a package: iCloud delivers a newer version from
    /// another Mac as changes to files *inside* it, which NSDocument reports
    /// here rather than as a change to the package itself. Route them to the
    /// standard handling — reload when unedited, prompt on conflict.
    nonisolated override func presentedSubitemDidChange(at url: URL) {
        super.presentedSubitemDidChange(at: url)
        presentedItemDidChange()
    }

    // MARK: - Windows

    override func makeWindowControllers() {
        addWindowController(ProjectWindowController(document: self))
    }

    /// Every open path (panel, Finder, Open Recent, restoration) ends here.
    override func showWindows() {
        super.showWindows()
        AppModel.shared.documentDidOpen(self)
    }

    /// Only documents that were on screen affect the app (active document,
    /// welcome window) — not ones opened without windows, e.g. in tests.
    override func close() {
        let wasShown = !windowControllers.isEmpty
        super.close()
        if wasShown {
            AppModel.shared.documentDidClose(self)
        }
    }
}

/// Hosts the SwiftUI project window for a document.
final class ProjectWindowController: NSWindowController {
    init(document: ProjectDocument) {
        let root = ProjectDocumentRootView(state: document.state)
            .environment(AppModel.shared)
        let hosting = NSHostingController(rootView: root)
        hosting.sizingOptions = [.minSize]
        hosting.sceneBridgingOptions = .all

        // The hosting controller must be attached to an existing window:
        // `NSWindow(contentViewController:)` skips SwiftUI's toolbar bridging,
        // losing the sidebar toggle, titles and toolbar items.
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 1100, height: 720),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: true
        )
        window.contentViewController = hosting
        window.toolbarStyle = .unified
        window.setContentSize(NSSize(width: 1100, height: 720))
        window.tabbingMode = .preferred
        super.init(window: window)
        shouldCascadeWindows = true

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(windowDidBecomeKey),
            name: NSWindow.didBecomeKeyNotification,
            object: window
        )
    }

    /// The title belongs to SwiftUI (scene title + chapter subtitle); only
    /// the proxy icon follows the document.
    override func synchronizeWindowTitleWithDocumentName() {
        window?.representedURL = document?.fileURL
    }

    @objc private func windowDidBecomeKey(_ notification: Notification) {
        AppModel.shared.activeDocument = document as? ProjectDocument
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }
}

private struct ProjectDocumentRootView: View {
    @Environment(AppModel.self) private var appModel
    let state: ProjectDocumentState

    var body: some View {
        Group {
            if let session = state.session {
                ProjectWindowView(session: session)
                    .id(ObjectIdentifier(session))
            }
        }
        .preferredColorScheme(appModel.settings.theme.colorScheme)
    }
}
