import Foundation

nonisolated struct ChartPoint: Sendable, Equatable {
    var date: String
    var wordsWritten: Int
    var goalTarget: Int
    var goalMet: Bool
    var isToday: Bool
}

/// Pure progress computations over local calendar days.
/// (Deliberate deviation from Tauri, which keyed days in UTC.)
nonisolated enum ProgressMath {
    static func dayKey(for date: Date, calendar: Calendar) -> String {
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", components.year!, components.month!, components.day!)
    }

    static func date(fromKey key: String, calendar: Calendar) -> Date? {
        let parts = key.split(separator: "-").compactMap { Int($0) }
        guard parts.count == 3 else { return nil }
        return calendar.date(from: DateComponents(year: parts[0], month: parts[1], day: parts[2]))
    }

    /// One entry per day. Manifest data is unvalidated: sync-conflict copies
    /// can leave several entries for a date, and the last one in manifest
    /// order wins. The result is sorted oldest first.
    static func deduplicated(_ progress: [DailyProgress]) -> [DailyProgress] {
        let byDate = Dictionary(progress.map { ($0.date, $0) }, uniquingKeysWith: { _, latest in latest })
        return byDate.values.sorted { $0.date < $1.date }
    }

    /// Streaks are runs of consecutive calendar days with the goal met.
    /// - `current`: ends today, or yesterday while today's goal is still
    ///   open, so a streak doesn't read as lost until the day is over.
    /// - `longest`: the longest such run anywhere in the history.
    static func streaks(
        progress: [DailyProgress],
        today: Date,
        calendar: Calendar
    ) -> (current: Int, longest: Int) {
        let days = deduplicated(progress)
        guard !days.isEmpty else { return (0, 0) }

        var longest = 0
        var run = 0
        var previousDay: Date?
        for entry in days {
            guard entry.goalMet, let day = date(fromKey: entry.date, calendar: calendar) else {
                run = 0
                previousDay = nil
                continue
            }
            let isNextDay = previousDay.flatMap { calendar.date(byAdding: .day, value: 1, to: $0) }
                .map { calendar.isDate($0, inSameDayAs: day) } ?? false
            run = isNextDay ? run + 1 : 1
            longest = max(longest, run)
            previousDay = day
        }

        let metDays = Set(days.filter(\.goalMet).map(\.date))
        var cursor = today
        if !metDays.contains(dayKey(for: today, calendar: calendar)),
           let yesterday = calendar.date(byAdding: .day, value: -1, to: today) {
            cursor = yesterday
        }
        var current = 0
        while metDays.contains(dayKey(for: cursor, calendar: calendar)) {
            current += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = previous
        }
        return (current, longest)
    }

    static func stats(
        progress: [DailyProgress],
        goals: ProgressGoals?,
        totalProjectWords: Int,
        today: Date,
        calendar: Calendar
    ) -> ProgressStats {
        guard !progress.isEmpty else {
            return ProgressStats(
                currentStreak: 0, longestStreak: 0, totalDaysActive: 0,
                averageDailyWords: 0, estimatedCompletionDate: nil
            )
        }
        let (current, longest) = streaks(progress: progress, today: today, calendar: calendar)
        let activeDays = deduplicated(progress).filter { $0.wordsWritten > 0 }
        let average = activeDays.isEmpty
            ? 0
            : Int((Double(activeDays.reduce(0) { $0 + $1.wordsWritten }) / Double(activeDays.count)).rounded())

        var estimated: Date?
        if let target = goals?.projectWordTarget, average > 0 {
            let remaining = target - totalProjectWords
            if remaining > 0 {
                let days = Int(ceil(Double(remaining) / Double(average)))
                estimated = calendar.date(byAdding: .day, value: days, to: today)
            }
        }
        return ProgressStats(
            currentStreak: current,
            longestStreak: longest,
            totalDaysActive: activeDays.count,
            averageDailyWords: average,
            estimatedCompletionDate: estimated
        )
    }

    /// Dense series for the chart: one point per day, oldest first.
    static func chartPoints(
        progress: [DailyProgress],
        goals: ProgressGoals?,
        days: Int,
        today: Date,
        calendar: Calendar
    ) -> [ChartPoint] {
        let byDate = Dictionary(deduplicated(progress).map { ($0.date, $0) }, uniquingKeysWith: { $1 })
        let goal = goals?.dailyWordTarget ?? ProgressGoals.defaultDailyTarget
        let todayKey = dayKey(for: today, calendar: calendar)
        var points: [ChartPoint] = []
        for offset in stride(from: days - 1, through: 0, by: -1) {
            guard let date = calendar.date(byAdding: .day, value: -offset, to: today) else { continue }
            let key = dayKey(for: date, calendar: calendar)
            let entry = byDate[key]
            points.append(ChartPoint(
                date: key,
                wordsWritten: entry?.wordsWritten ?? 0,
                goalTarget: goal,
                goalMet: entry?.goalMet ?? false,
                isToday: key == todayKey
            ))
        }
        return points
    }
}
