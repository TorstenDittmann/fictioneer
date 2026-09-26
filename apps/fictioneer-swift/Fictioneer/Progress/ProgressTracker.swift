import Foundation

/// Session-scoped progress service: daily baseline snapshots, words-today,
/// session counting, streak stats, and the once-per-day goal toast.
@Observable
final class ProgressTracker {
    private weak var project: Project?
    @ObservationIgnored private let now: () -> Date
    @ObservationIgnored private let calendar: Calendar
    @ObservationIgnored private var celebratedDay: String?

    /// Set for one UI pass when today's goal transitions unmet → met.
    var showGoalToast = false

    init(project: Project, now: @escaping () -> Date = { .now }, calendar: Calendar = .current) {
        self.project = project
        self.now = now
        self.calendar = calendar
        ensureTodayBaseline()
    }

    var todayKey: String {
        ProgressMath.dayKey(for: now(), calendar: calendar)
    }

    var goals: ProgressGoals? {
        project?.progressGoals
    }

    var todaysProgress: DailyProgress? {
        project?.dailyProgress.first { $0.date == todayKey }
    }

    var todaysWordCount: Int {
        todaysProgress?.wordsWritten ?? 0
    }

    var dailyTarget: Int {
        goals?.dailyWordTarget ?? ProgressGoals.defaultDailyTarget
    }

    var todaysPercentage: Int {
        min(100, Int((Double(todaysWordCount) / Double(max(1, dailyTarget)) * 100).rounded()))
    }

    var stats: ProgressStats {
        guard let project else {
            return ProgressStats(currentStreak: 0, longestStreak: 0, totalDaysActive: 0, averageDailyWords: 0, estimatedCompletionDate: nil)
        }
        return ProgressMath.stats(
            progress: project.dailyProgress,
            goals: project.progressGoals,
            totalProjectWords: project.totalWordCount,
            today: now(),
            calendar: calendar
        )
    }

    func chartPoints(days: Int = 30) -> [ChartPoint] {
        guard let project else { return [] }
        return ProgressMath.chartPoints(
            progress: project.dailyProgress,
            goals: project.progressGoals,
            days: days,
            today: now(),
            calendar: calendar
        )
    }

    // MARK: - Mutation

    /// Pins today's baseline to the current project total if absent.
    func ensureTodayBaseline() {
        guard let project else { return }
        if project.dailyWordSnapshots[todayKey] == nil {
            project.dailyWordSnapshots[todayKey] = project.totalWordCount
        }
    }

    /// Called on every meaningful-or-not content change with the new totals.
    func recordEdit(totalWords: Int, wordDelta: Int, characterDelta: Int) {
        guard let project else { return }
        let today = todayKey
        // Day rollover mid-session: pin the fresh baseline from the passed
        // total (the model may include this edit already).
        if project.dailyWordSnapshots[today] == nil {
            project.dailyWordSnapshots[today] = totalWords
        }
        let baseline = project.dailyWordSnapshots[today] ?? totalWords
        let written = max(0, totalWords - baseline)
        let target = dailyTarget

        let existing = project.dailyProgress.first { $0.date == today }
        var sessions = existing?.sessionsCount ?? 0

        // Session counting: a meaningful change (>=5 words or >=25 chars) that
        // arrives more than 5 minutes after the last one starts a new session.
        if wordDelta >= 5 || characterDelta >= 25 {
            let last = project.lastSessionTime ?? .distantPast
            if now().timeIntervalSince(last) > 5 * 60 {
                sessions += 1
            }
            project.lastSessionTime = now()
        }

        let wasMet = existing?.goalMet ?? false
        let entry = DailyProgress(
            date: today,
            wordsWritten: written,
            goalMet: written >= target,
            sessionsCount: max(1, sessions),
            updatedAt: now()
        )
        if let index = project.dailyProgress.firstIndex(where: { $0.date == today }) {
            project.dailyProgress[index] = entry
        } else {
            project.dailyProgress.append(entry)
        }

        if !wasMet, entry.goalMet, celebratedDay != today {
            celebratedDay = today
            showGoalToast = true
        }
    }

    func setGoals(dailyTarget: Int, projectTarget: Int?) {
        guard let project else { return }
        let clampedDaily = max(1, min(ProgressGoals.maxDailyTarget, dailyTarget))
        let clampedProject = projectTarget.map { max(clampedDaily, min(ProgressGoals.maxProjectTarget, $0)) }
        let timestamp = now()
        if var goals = project.progressGoals {
            goals.dailyWordTarget = clampedDaily
            goals.projectWordTarget = clampedProject
            goals.updatedAt = timestamp
            project.progressGoals = goals
        } else {
            project.progressGoals = ProgressGoals(
                dailyWordTarget: clampedDaily,
                projectWordTarget: clampedProject,
                createdAt: timestamp,
                updatedAt: timestamp
            )
        }
        // Re-evaluate today's entry against the new target.
        if let index = project.dailyProgress.firstIndex(where: { $0.date == todayKey }) {
            project.dailyProgress[index].goalMet = project.dailyProgress[index].wordsWritten >= clampedDaily
        }
    }
}
