import Foundation
import Testing
@testable import Fictioneer

@MainActor
struct CloudProjectLibraryTests {
    private let directory = URL(fileURLWithPath: "/tmp/cloud-docs", isDirectory: true)

    @Test func uniqueURLUsesTitleWhenFree() {
        let url = CloudProjectLibrary.uniqueURL(for: "My Novel", in: directory) { _ in false }
        #expect(url.lastPathComponent == "My Novel.fictioneer")
    }

    @Test func uniqueURLNumbersCollisionsAndNeverOverwrites() {
        let taken: Set<String> = ["My Novel.fictioneer", "My Novel 2.fictioneer"]
        let url = CloudProjectLibrary.uniqueURL(for: "My Novel", in: directory) {
            taken.contains($0.lastPathComponent)
        }
        #expect(url.lastPathComponent == "My Novel 3.fictioneer")
    }

    @Test func filenameStripsPathSeparatorsAndLeadingDots() {
        #expect(CloudProjectLibrary.sanitizedFilename("Act I/II: Rise") == "Act I-II- Rise")
        #expect(CloudProjectLibrary.sanitizedFilename("..hidden") == "hidden")
    }

    @Test func emptyOrWhitespaceTitleFallsBackToUntitled() {
        #expect(CloudProjectLibrary.sanitizedFilename("   ") == "Untitled")
        #expect(CloudProjectLibrary.sanitizedFilename("") == "Untitled")
    }

    /// Unsigned test builds (and signed-out Macs) have no container: the
    /// library must settle on unavailable rather than hang in .checking.
    @Test func missingContainerResolvesToUnavailable() async {
        let library = CloudProjectLibrary(containerIdentifier: "iCloud.app.fictioneer.nonexistent")
        library.start()
        for _ in 0..<200 where library.availability == .checking {
            try? await Task.sleep(for: .milliseconds(10))
        }
        #expect(library.availability == .unavailable)
        #expect(library.documentsURL == nil)
        #expect(library.projects.isEmpty)
    }

    @Test func createProjectRefusesWhenUnavailable() {
        let library = CloudProjectLibrary(containerIdentifier: "iCloud.app.fictioneer.nonexistent")
        #expect(throws: CocoaError.self) {
            _ = try library.createProject(Project.makeNew(title: "T"), named: "T")
        }
    }
}
