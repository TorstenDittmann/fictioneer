import Foundation

nonisolated enum WordCounter {
    static func counts(for string: String) -> (words: Int, characters: Int) {
        var words = 0
        string.enumerateSubstrings(
            in: string.startIndex..<string.endIndex,
            options: [.byWords, .substringNotRequired]
        ) { _, _, _, _ in
            words += 1
        }
        return (words, string.count)
    }
}
