import Foundation
import Testing
@testable import Fictioneer

struct PlotGridTests {
    private let ids = (0..<8).map { _ in UUID() }

    private func beats(_ line: PlotLine, at indices: [Int]) -> [BeatKey: String] {
        Dictionary(uniqueKeysWithValues: indices.map { (BeatKey(sceneID: ids[$0], plotLineID: line.id), "beat \($0)") })
    }

    @Test func gapInsideALineIsReported() {
        let line = PlotLine(title: "The Prince's Marriage", tint: .indigo)
        let gaps = PlotGridAnalysis.gaps(sceneIDs: ids, plotLines: [line], beats: beats(line, at: [1, 2, 6]))
        #expect(gaps == [PlotGap(plotLineID: line.id, sceneIDs: Array(ids[3...5]))])
    }

    @Test func shortPausesAndOpenEndsAreNotGaps() {
        let line = PlotLine(title: "Violet", tint: .rose)
        // Two-scene pause, and nothing before the first or after the last beat.
        let gaps = PlotGridAnalysis.gaps(sceneIDs: ids, plotLines: [line], beats: beats(line, at: [2, 5]))
        #expect(gaps.isEmpty)
    }

    @Test func whitespaceBeatsCountAsEmpty() {
        let line = PlotLine(title: "Photo", tint: .amber)
        var map = beats(line, at: [0, 4])
        map[BeatKey(sceneID: ids[2], plotLineID: line.id)] = "   "
        let gaps = PlotGridAnalysis.gaps(sceneIDs: ids, plotLines: [line], beats: map)
        #expect(gaps.first?.sceneIDs == Array(ids[1...3]))
    }

    @Test func linesWithoutBeatsHaveNoGaps() {
        let line = PlotLine(title: "Empty", tint: .slate)
        #expect(PlotGridAnalysis.gaps(sceneIDs: ids, plotLines: [line], beats: [:]).isEmpty)
    }

    @Test func addPlotLinePicksUnusedTints() {
        let project = Project.makeNew(title: "T")
        let first = project.addPlotLine()
        let second = project.addPlotLine()
        #expect(first.tint != second.tint)
        #expect(second.title == "Plot Line 2")
    }

    @Test func plotLinesAndBeatsRoundTripAndDeletedOnesAreDropped() throws {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("grid-\(UUID().uuidString).fictioneer")
        defer { try? FileManager.default.removeItem(at: url) }

        let kept = Scene(title: "The Fire Alarm")
        let removed = Scene(title: "Cut scene")
        let project = Project(title: "T", chapters: [Chapter(title: "II", scenes: [kept, removed])])
        let photo = project.addPlotLine(titled: "The Photograph")
        let prince = project.addPlotLine(titled: "The Prince")
        project.setBeat("False fire reveals the hiding place", scene: kept, line: photo)
        project.setBeat("Gone with the scene", scene: removed, line: photo)
        project.setBeat("Gone with the line", scene: kept, line: prince)
        project.deleteScene(removed)
        project.deletePlotLine(prince)

        try ProjectPackage.write(project, to: url)
        let restored = try ProjectPackage.read(from: url)
        #expect(restored.plotLines.map(\.title) == ["The Photograph"])
        #expect(restored.plotLines.first?.tint == photo.tint)
        #expect(restored.beats.count == 1)
        #expect(restored.beats[BeatKey(sceneID: kept.id, plotLineID: photo.id)] == "False fire reveals the hiding place")
    }

    @Test func clearingABeatRemovesIt() {
        let scene = Scene(title: "S")
        let project = Project(title: "T", chapters: [Chapter(title: "C", scenes: [scene])])
        let line = project.addPlotLine()
        project.setBeat("x", scene: scene, line: line)
        project.setBeat("", scene: scene, line: line)
        #expect(project.beats.isEmpty)
    }
}
