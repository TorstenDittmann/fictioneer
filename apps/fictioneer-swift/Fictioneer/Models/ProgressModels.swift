import Foundation

nonisolated struct ProgressGoals: Codable, Sendable, Equatable {
    var dailyWordTarget: Int
    var projectWordTarget: Int?
    var createdAt: Date
    var updatedAt: Date

    static let defaultDailyTarget = 500
    static let maxDailyTarget = 10_000
    static let maxProjectTarget = 1_000_000
}

nonisolated struct DailyProgress: Codable, Sendable, Equatable {
    /// Local calendar day key "yyyy-MM-dd".
    var date: String
    var wordsWritten: Int
    var goalMet: Bool
    var sessionsCount: Int
    var updatedAt: Date
}

nonisolated struct ProgressStats: Sendable, Equatable {
    var currentStreak: Int
    var longestStreak: Int
    var totalDaysActive: Int
    var averageDailyWords: Int
    var estimatedCompletionDate: Date?
}

nonisolated struct ProjectEpubMetadata: Codable, Sendable, Equatable {
    var author: String = ""
    var publisher: String = ""
    var language: String = "en"
    var rights: String = ""
    var subjects: [String] = []
}
