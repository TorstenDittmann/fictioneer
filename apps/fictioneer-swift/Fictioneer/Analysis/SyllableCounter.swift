import Foundation

/// Port of text_analysis/syllable_counter.ts. All positions are UTF-16 offsets.
nonisolated enum SyllableCounter {
    static let wordRegex = try! NSRegularExpression(
        pattern: "[a-zA-Z]+(?:'[a-zA-Z]+)?(?:-[a-zA-Z]+)*"
    )
    private static let vowelGroupRegex = try! NSRegularExpression(
        pattern: "[aeiouy]+", options: [.caseInsensitive]
    )

    /// 94 overrides from the Tauri source, looked up before cleaning.
    static let overrides: [String: Int] = [
        "awe": 1, "eye": 1, "oye": 1,
        "don't": 1, "won't": 1, "can't": 1, "didn't": 2, "wouldn't": 2, "couldn't": 2,
        "shouldn't": 2, "aren't": 1, "isn't": 2, "wasn't": 2, "weren't": 1, "haven't": 2,
        "hasn't": 2, "hadn't": 2, "they're": 1, "we're": 1, "you're": 1, "i'm": 1,
        "he's": 1, "she's": 1, "it's": 1, "that's": 1, "what's": 1, "there's": 1,
        "here's": 1, "where's": 1, "let's": 1, "who's": 1, "i'll": 1, "you'll": 1,
        "he'll": 1, "she'll": 1, "we'll": 1, "they'll": 1, "i've": 1, "you've": 1,
        "we've": 1, "they've": 1, "i'd": 1, "you'd": 1, "he'd": 1, "she'd": 1,
        "we'd": 1, "they'd": 1,
        "business": 2, "every": 2, "evening": 2, "different": 2, "chocolate": 2,
        "comfortable": 3, "interesting": 3, "vegetable": 3, "camera": 2, "separate": 3,
        "temperature": 3, "literature": 3, "actually": 3, "naturally": 3, "family": 2,
        "really": 2, "usually": 3, "finally": 2, "probably": 3, "basically": 3,
        "definitely": 4, "especially": 4, "particularly": 5, "simultaneously": 5,
        "fire": 1, "hour": 1, "our": 1, "area": 3, "idea": 3, "real": 1, "being": 2,
        "seeing": 2, "doing": 2, "going": 2, "poem": 2, "poet": 2, "poetry": 3,
        "quiet": 2, "science": 2, "diet": 2, "lion": 2, "riot": 2, "violent": 2,
        "create": 2, "created": 3, "creating": 3, "creature": 2,
    ]

    static func extractWords(_ text: String) -> [String] {
        let ns = text as NSString
        return wordRegex.matches(in: text, range: NSRange(location: 0, length: ns.length))
            .map { ns.substring(with: $0.range) }
    }

    static func countSyllables(_ word: String) -> Int {
        let normalized = word.lowercased().trimmingCharacters(in: .whitespaces)
        if normalized.isEmpty { return 0 }
        if let override = overrides[normalized] { return override }
        let cleaned = normalized.filter { ($0 >= "a" && $0 <= "z") || $0 == "'" }
        if cleaned.isEmpty { return 0 }
        if cleaned.count == 1 { return 1 }

        var count = vowelGroupCount(cleaned)
        count = adjustForSuffixes(cleaned, count)
        count = adjustForSilentE(cleaned, count)
        return max(1, count)
    }

    static func countTotalSyllables(_ text: String) -> Int {
        extractWords(text).reduce(0) { $0 + countSyllables($1) }
    }

    private static func vowelGroupCount(_ word: String) -> Int {
        let ns = word as NSString
        return vowelGroupRegex.numberOfMatches(in: word, range: NSRange(location: 0, length: ns.length))
    }

    private static func adjustForSuffixes(_ word: String, _ count: Int) -> Int {
        var adjusted = count
        // Each of these suffixes contains one vowel group; the source's net
        // effect is exactly +1 for the first match.
        let addingSuffixes = ["ious", "eous", "uous", "ial", "ual", "ian", "ium"]
        for suffix in addingSuffixes where word.hasSuffix(suffix) {
            adjusted += 1
            break
        }
        let chars = Array(word)
        if word.hasSuffix("ed"), chars.count > 2 {
            let beforeEd = chars[chars.count - 3]
            if !"aeiouytd".contains(beforeEd) {
                adjusted -= 1
            }
        }
        if word.hasSuffix("es"), chars.count > 2 {
            let beforeEs = chars[chars.count - 3]
            if !"sxz".contains(beforeEs), !word.hasSuffix("ches"), !word.hasSuffix("shes") {
                if !"aeiou".contains(beforeEs) {
                    adjusted -= 1
                }
            }
        }
        if word.hasSuffix("tion") || word.hasSuffix("sion") {
            adjusted -= 1
        }
        return adjusted
    }

    private static func adjustForSilentE(_ word: String, _ count: Int) -> Int {
        var adjusted = count
        let chars = Array(word)
        if word.hasSuffix("e"), chars.count > 2 {
            let beforeE = chars[chars.count - 2]
            if !"aeiou".contains(beforeE), !word.hasSuffix("le") {
                adjusted -= 1
            }
        }
        if word.hasSuffix("es"), chars.count > 3 {
            let thirdFromEnd = chars[chars.count - 3]
            if "sxzh".contains(thirdFromEnd) || word.hasSuffix("ches") || word.hasSuffix("shes") {
                adjusted += 1
            }
        }
        return adjusted
    }
}
