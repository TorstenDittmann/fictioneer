import Foundation

/// Recent projects persisted as security-scoped bookmarks so sandboxed
/// re-opens work across launches without re-prompting the user.
@Observable
final class RecentProjectsStore {
    struct Entry: Codable, Identifiable, Equatable {
        var bookmark: Data
        var title: String
        var path: String
        var lastOpened: Date

        var id: String { path }
        var filename: String { (path as NSString).lastPathComponent }
    }

    private static let defaultsKey = "fictioneer.recentProjects"
    private let defaults: UserDefaults

    private(set) var entries: [Entry] = []

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        load()
    }

    func noteOpened(url: URL, title: String) {
        guard let bookmark = try? url.bookmarkData(
            options: .withSecurityScope,
            includingResourceValuesForKeys: nil,
            relativeTo: nil
        ) else { return }
        entries.removeAll { $0.path == url.path }
        entries.insert(Entry(bookmark: bookmark, title: title, path: url.path, lastOpened: .now), at: 0)
        if entries.count > AppConfig.maxRecentProjects {
            entries.removeLast(entries.count - AppConfig.maxRecentProjects)
        }
        persist()
    }

    /// Resolves the entry's bookmark and starts security-scoped access.
    /// The caller owns the scope and must call `stopAccessingSecurityScopedResource()`.
    /// Returns nil (and drops the entry) when the bookmark is dead.
    func beginAccess(to entry: Entry) -> URL? {
        var isStale = false
        guard
            let url = try? URL(
                resolvingBookmarkData: entry.bookmark,
                options: .withSecurityScope,
                relativeTo: nil,
                bookmarkDataIsStale: &isStale
            ),
            url.startAccessingSecurityScopedResource()
        else {
            remove(entry)
            return nil
        }
        if isStale, let refreshed = try? url.bookmarkData(
            options: .withSecurityScope,
            includingResourceValuesForKeys: nil,
            relativeTo: nil
        ), let index = entries.firstIndex(where: { $0.id == entry.id }) {
            entries[index].bookmark = refreshed
            entries[index].path = url.path
            persist()
        }
        return url
    }

    func remove(_ entry: Entry) {
        entries.removeAll { $0.id == entry.id }
        persist()
    }

    func clear() {
        entries = []
        persist()
    }

    private func load() {
        guard let data = defaults.data(forKey: Self.defaultsKey) else { return }
        entries = (try? JSONDecoder().decode([Entry].self, from: data)) ?? []
    }

    private func persist() {
        defaults.set(try? JSONEncoder().encode(entries), forKey: Self.defaultsKey)
    }
}
