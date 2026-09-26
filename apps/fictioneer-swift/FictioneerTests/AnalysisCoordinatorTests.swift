import Foundation
import Testing
@testable import Fictioneer

@MainActor
struct AnalysisCoordinatorTests {
    /// An older (slower) analysis that finishes after a newer one must not
    /// clobber the published result / isAnalyzing / lastAnalyzedHash.
    @Test func overlappingRunsPublishTheNewestResult() async {
        let coordinator = AnalysisCoordinator()
        let paragraph = "The detective walked slowly through the very dark corridor. "
            + "He was followed by shadows that seemed to whisper. "
        let slowText = String(repeating: paragraph, count: 400) // ~7k words
        let fastText = "The cat sat."
        let fastHash = TextAnalysisEngine.contentHash(fastText)

        coordinator.contentDidChange(slowText)
        // Let the debounce elapse so the slow analysis actually starts…
        try? await Task.sleep(for: .milliseconds(400))
        // …then supersede it while it is still computing.
        coordinator.contentDidChange(fastText)

        var sawFastResult = false
        for _ in 0..<1000 {
            if coordinator.result?.contentHash == fastHash, !coordinator.isAnalyzing {
                sawFastResult = true
                break
            }
            try? await Task.sleep(for: .milliseconds(10))
        }
        #expect(sawFastResult)

        // Give the superseded slow run ample time to finish and (with the
        // bug) publish over the newer result.
        try? await Task.sleep(for: .seconds(3))
        #expect(coordinator.result?.contentHash == fastHash)
        #expect(!coordinator.isAnalyzing)
    }
}
