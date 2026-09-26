import Foundation
import Testing
@testable import Fictioneer

struct RecentProjectsStoreTests {
    private func makeDefaults() -> UserDefaults {
        let suite = "fictioneer-tests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)
        return defaults
    }

    private func makeProjectDirectory() throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("recents-\(UUID().uuidString).fictioneer")
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    @Test func noteOpenedAddsEntryAndResolves() throws {
        let defaults = makeDefaults()
        let store = RecentProjectsStore(defaults: defaults)
        let url = try makeProjectDirectory()
        defer { try? FileManager.default.removeItem(at: url) }

        store.noteOpened(url: url, title: "My Novel")
        #expect(store.entries.count == 1)
        #expect(store.entries[0].title == "My Novel")

        let resolved = store.beginAccess(to: store.entries[0])
        #expect(resolved?.path == url.path)
        resolved?.stopAccessingSecurityScopedResource()

        // Reload from the same defaults — persistence round-trip.
        let reloaded = RecentProjectsStore(defaults: defaults)
        #expect(reloaded.entries.count == 1)
    }

    @Test func reopeningMovesEntryToFrontAndDeduplicates() throws {
        let store = RecentProjectsStore(defaults: makeDefaults())
        let first = try makeProjectDirectory()
        let second = try makeProjectDirectory()
        defer {
            try? FileManager.default.removeItem(at: first)
            try? FileManager.default.removeItem(at: second)
        }

        store.noteOpened(url: first, title: "First")
        store.noteOpened(url: second, title: "Second")
        store.noteOpened(url: first, title: "First")
        #expect(store.entries.count == 2)
        #expect(store.entries[0].title == "First")
    }

    @Test func deadBookmarkIsDropped() throws {
        let store = RecentProjectsStore(defaults: makeDefaults())
        let url = try makeProjectDirectory()
        store.noteOpened(url: url, title: "Doomed")
        try FileManager.default.removeItem(at: url)

        let resolved = store.beginAccess(to: store.entries[0])
        #expect(resolved == nil)
        #expect(store.entries.isEmpty)
    }

    @Test func entriesAreCappedAtMaximum() throws {
        let store = RecentProjectsStore(defaults: makeDefaults())
        var urls: [URL] = []
        for index in 0..<(AppConfig.maxRecentProjects + 3) {
            let url = try makeProjectDirectory()
            urls.append(url)
            store.noteOpened(url: url, title: "P\(index)")
        }
        defer { urls.forEach { try? FileManager.default.removeItem(at: $0) } }
        #expect(store.entries.count == AppConfig.maxRecentProjects)
        #expect(store.entries[0].title == "P\(AppConfig.maxRecentProjects + 2)")
    }
}
