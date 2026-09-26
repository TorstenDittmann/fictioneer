import Foundation

/// A thread through the book (main plot, subplot, character arc): a column
/// in the plot grid.
nonisolated struct PlotLine: Codable, Identifiable, Hashable, Sendable {
    enum Tint: String, Codable, CaseIterable, Sendable {
        case amber, rose, teal, indigo, green, slate
    }

    var id: UUID = UUID()
    var title: String
    var tint: Tint
}

/// What one scene does for one plot line: a cell in the plot grid.
nonisolated struct PlotBeat: Codable, Hashable, Sendable {
    var sceneID: UUID
    var plotLineID: UUID
    var text: String
}

nonisolated struct BeatKey: Hashable, Sendable {
    let sceneID: UUID
    let plotLineID: UUID
}

/// A stretch where a plot line goes quiet: consecutive scenes, inside the
/// line's first and last beat, with no beat for it.
nonisolated struct PlotGap: Equatable, Sendable {
    let plotLineID: UUID
    let sceneIDs: [UUID]
}

nonisolated enum PlotGridAnalysis {
    /// Gaps of at least `minimumLength` scenes. Scenes before a line's first
    /// beat or after its last don't count: the thread hasn't started or has
    /// ended there.
    static func gaps(
        sceneIDs: [UUID],
        plotLines: [PlotLine],
        beats: [BeatKey: String],
        minimumLength: Int = 3
    ) -> [PlotGap] {
        var result: [PlotGap] = []
        for line in plotLines {
            let hasBeat = sceneIDs.map { id in
                !(beats[BeatKey(sceneID: id, plotLineID: line.id)] ?? "")
                    .trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            }
            guard let first = hasBeat.firstIndex(of: true),
                  let last = hasBeat.lastIndex(of: true) else { continue }
            var run: [UUID] = []
            for index in first...last {
                if hasBeat[index] {
                    if run.count >= minimumLength {
                        result.append(PlotGap(plotLineID: line.id, sceneIDs: run))
                    }
                    run = []
                } else {
                    run.append(sceneIDs[index])
                }
            }
        }
        return result
    }
}
