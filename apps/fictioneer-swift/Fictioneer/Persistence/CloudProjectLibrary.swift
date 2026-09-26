import Foundation
import os

/// iCloud Drive ▸ Fictioneer: resolves the app's ubiquity container, keeps a
/// live list of the projects in it, and is where new projects are created.
/// Everything degrades to "unavailable" when iCloud is off or signed out —
/// projects are then created locally via a save panel.
@Observable
final class CloudProjectLibrary {
    enum Availability: Equatable {
        case checking
        case available(documentsURL: URL)
        case unavailable
    }

    struct Item: Identifiable, Equatable {
        let url: URL
        var id: URL { url }
        var title: String { url.deletingPathExtension().lastPathComponent }
        var modified: Date?
        var isDownloaded: Bool
        var hasConflicts: Bool
    }

    private(set) var availability: Availability = .checking
    private(set) var projects: [Item] = []

    @ObservationIgnored private var query: NSMetadataQuery?
    @ObservationIgnored private var observers: [NSObjectProtocol] = []
    @ObservationIgnored private let containerIdentifier: String
    private static let logger = Logger(subsystem: "app.fictioneer", category: "CloudProjectLibrary")

    init(containerIdentifier: String = AppConfig.iCloudContainerIdentifier) {
        self.containerIdentifier = containerIdentifier
    }

    var documentsURL: URL? {
        if case .available(let url) = availability { return url }
        return nil
    }

    /// Resolves the container (which can block while iCloud sets it up, so
    /// off the main thread) and re-resolves when the iCloud account changes.
    func start() {
        guard observers.isEmpty else { return }
        observers.append(NotificationCenter.default.addObserver(
            forName: .NSUbiquityIdentityDidChange,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.resolveContainer() }
        })
        resolveContainer()
    }

    private func resolveContainer() {
        let identifier = containerIdentifier
        Task {
            let documentsURL = await Task.detached { () -> URL? in
                guard FileManager.default.ubiquityIdentityToken != nil,
                      let container = FileManager.default.url(forUbiquityContainerIdentifier: identifier)
                else { return nil }
                let documents = container.appendingPathComponent("Documents", isDirectory: true)
                do {
                    try FileManager.default.createDirectory(at: documents, withIntermediateDirectories: true)
                    return documents
                } catch {
                    return nil
                }
            }.value
            apply(documentsURL)
        }
    }

    private func apply(_ documentsURL: URL?) {
        guard let documentsURL else {
            Self.logger.info("iCloud Drive unavailable; projects are created locally")
            availability = .unavailable
            stopQuery()
            projects = []
            return
        }
        availability = .available(documentsURL: documentsURL)
        startQuery()
    }

    // MARK: - Listing

    private func startQuery() {
        stopQuery()
        let query = NSMetadataQuery()
        query.searchScopes = [NSMetadataQueryUbiquitousDocumentsScope]
        query.predicate = NSPredicate(
            format: "%K LIKE %@",
            NSMetadataItemFSNameKey,
            "*.\(AppConfig.projectFileExtension)"
        )
        query.sortDescriptors = [NSSortDescriptor(key: NSMetadataItemFSContentChangeDateKey, ascending: false)]
        query.operationQueue = .main
        for name in [Notification.Name.NSMetadataQueryDidFinishGathering, .NSMetadataQueryDidUpdate] {
            observers.append(NotificationCenter.default.addObserver(
                forName: name,
                object: query,
                queue: .main
            ) { [weak self] _ in
                MainActor.assumeIsolated { self?.refreshFromQuery() }
            })
        }
        self.query = query
        query.start()
    }

    private func stopQuery() {
        query?.stop()
        query = nil
    }

    private func refreshFromQuery() {
        guard let query else { return }
        query.disableUpdates()
        defer { query.enableUpdates() }
        projects = query.results.compactMap { result in
            guard let item = result as? NSMetadataItem,
                  let url = item.value(forAttribute: NSMetadataItemURLKey) as? URL else { return nil }
            let status = item.value(forAttribute: NSMetadataUbiquitousItemDownloadingStatusKey) as? String
            return Item(
                url: url,
                modified: item.value(forAttribute: NSMetadataItemFSContentChangeDateKey) as? Date,
                isDownloaded: status == NSMetadataUbiquitousItemDownloadingStatusCurrent,
                hasConflicts: item.value(forAttribute: NSMetadataUbiquitousItemHasUnresolvedConflictsKey) as? Bool ?? false
            )
        }
    }

    // MARK: - Creating

    /// Writes a new project into iCloud Drive ▸ Fictioneer (coordinated, so
    /// the sync daemon never sees a half-written package) and returns its URL.
    func createProject(_ project: Project, named name: String) throws -> URL {
        guard let documentsURL else { throw CocoaError(.ubiquitousFileUnavailable) }
        let url = Self.uniqueURL(for: name, in: documentsURL) {
            FileManager.default.fileExists(atPath: $0.path)
        }
        var coordinationError: NSError?
        var writeError: Error?
        NSFileCoordinator().coordinate(writingItemAt: url, options: .forReplacing, error: &coordinationError) { target in
            do {
                try ProjectPackage.write(project, to: target)
            } catch {
                writeError = error
            }
        }
        if let error = coordinationError ?? writeError {
            throw error
        }
        return url
    }

    /// "Title.fictioneer", then "Title 2.fictioneer", … — never overwrites.
    nonisolated static func uniqueURL(for name: String, in directory: URL, exists: (URL) -> Bool) -> URL {
        let base = sanitizedFilename(name)
        let ext = AppConfig.projectFileExtension
        var candidate = directory.appendingPathComponent("\(base).\(ext)", isDirectory: true)
        var counter = 2
        while exists(candidate) {
            candidate = directory.appendingPathComponent("\(base) \(counter).\(ext)", isDirectory: true)
            counter += 1
        }
        return candidate
    }

    /// Titles can contain characters that aren't valid in a filename.
    nonisolated static func sanitizedFilename(_ name: String) -> String {
        let cleaned = name
            .components(separatedBy: CharacterSet(charactersIn: "/:\\"))
            .joined(separator: "-")
            .trimmingCharacters(in: .whitespacesAndNewlines.union(CharacterSet(charactersIn: ".")))
        return cleaned.isEmpty ? "Untitled" : cleaned
    }
}
