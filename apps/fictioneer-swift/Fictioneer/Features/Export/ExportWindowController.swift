import AppKit
import SwiftUI

/// The export window: a secondary window of the project's document, closed
/// with it. Settings on the left, a live preview on the right.
final class ExportWindowController: NSWindowController {
    private let model: ExportModel

    init(session: ProjectSession) {
        model = ExportModel(session: session, settings: AppModel.shared.settings)
        let root = ExportView(model: model)
            .environment(AppModel.shared)
        let hosting = NSHostingController(rootView: root)
        hosting.sizingOptions = [.minSize]

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 1240, height: 820),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: true
        )
        window.contentViewController = hosting
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.isRestorable = false
        window.setContentSize(NSSize(width: 1240, height: 820))
        window.center()
        super.init(window: window)
        model.window = window
        window.title = "Export “\(session.project.title)”"

        // The manuscript may have changed in the project window meanwhile.
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(windowDidBecomeKey),
            name: NSWindow.didBecomeKeyNotification,
            object: window
        )
    }

    @objc private func windowDidBecomeKey(_ notification: Notification) {
        model.scheduleRebuild()
    }

    /// Keeps the document's name out of the title; it's set explicitly.
    override func windowTitle(forDocumentDisplayName displayName: String) -> String {
        "Export “\(model.project.title)”"
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }
}
