import Foundation

nonisolated enum AppConfig {
    // Debug builds talk to a local intelligence server; release builds ship
    // pointed at production. Either can be overridden per-user in Settings.
    static let productionIntelligenceBaseURL = "https://intelligence.fictioneer.app"
    static let debugIntelligenceBaseURL = "http://localhost:3001"

    #if DEBUG
    static let defaultIntelligenceBaseURL = debugIntelligenceBaseURL
    #else
    static let defaultIntelligenceBaseURL = productionIntelligenceBaseURL
    #endif

    static let projectFileExtension = "fictioneer"
    static let formatVersion = 1

    static let autosaveDebounce: TimeInterval = 3.0
    static let autosaveThrottle: TimeInterval = 5.0
    static let maxRecentProjects = 10

    static let ghostTextWordCount = 36
    static let ghostTextContextWindow = 2000
    static let ghostTextMinContextLength = 10
}
