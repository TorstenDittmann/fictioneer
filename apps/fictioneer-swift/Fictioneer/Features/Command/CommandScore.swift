import Foundation

/// Subsequence fuzzy scorer, ported in spirit from bits-ui's
/// computeCommandScore: contiguous matches score highest, word-boundary jumps
/// slightly lower, bare character jumps much lower; skipped characters decay
/// the score. Returns 0 when the query is not a subsequence of the target.
nonisolated enum CommandScore {
    private static let continueMatch = 1.0
    private static let spaceWordJump = 0.9
    private static let nonSpaceWordJump = 0.8
    private static let characterJump = 0.17
    private static let penaltySkipped = 0.999
    private static let penaltyNotComplete = 0.99
    private static let gapCharacters = Set("/_+.#\"@[({&")

    static func score(_ query: String, in target: String) -> Double {
        guard !query.isEmpty else { return penaltyNotComplete }
        let q = Array(normalize(query))
        let t = Array(normalize(target))
        guard !t.isEmpty, q.count <= t.count else { return 0 }
        var memo: [Int: Double] = [:]
        let result = bestScore(q, t, qIndex: 0, tIndex: 0, memo: &memo)
        return result
    }

    private static func normalize(_ string: String) -> String {
        string.lowercased().map { $0 == "-" || $0.isWhitespace ? " " : $0 }
            .reduce(into: "") { $0.append($1) }
    }

    private static func bestScore(
        _ q: [Character], _ t: [Character],
        qIndex: Int, tIndex: Int,
        memo: inout [Int: Double]
    ) -> Double {
        if qIndex == q.count {
            // Bonus when the match consumed the whole target.
            return tIndex == t.count ? continueMatch : penaltyNotComplete
        }
        let key = qIndex * (t.count + 1) + tIndex
        if let cached = memo[key] { return cached }

        var best = 0.0
        var searchIndex = tIndex
        while let found = findNext(q[qIndex], in: t, from: searchIndex) {
            let skipped = found - tIndex
            let jumpScore: Double
            if found == tIndex {
                jumpScore = continueMatch
            } else if t[found - 1] == " " {
                jumpScore = spaceWordJump
            } else if gapCharacters.contains(t[found - 1]) {
                jumpScore = nonSpaceWordJump
            } else if found == 0 {
                jumpScore = continueMatch
            } else {
                jumpScore = characterJump
            }
            let decay = pow(penaltySkipped, Double(skipped))
            let rest = bestScore(q, t, qIndex: qIndex + 1, tIndex: found + 1, memo: &memo)
            let candidate = jumpScore * decay * rest
            best = max(best, candidate)
            searchIndex = found + 1
            // Contiguous match is already optimal for this branch.
            if found == tIndex { break }
        }
        memo[key] = best
        return best
    }

    private static func findNext(_ character: Character, in target: [Character], from index: Int) -> Int? {
        var cursor = index
        while cursor < target.count {
            if target[cursor] == character { return cursor }
            cursor += 1
        }
        return nil
    }
}
