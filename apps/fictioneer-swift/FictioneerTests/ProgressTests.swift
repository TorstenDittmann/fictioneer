import Foundation
import Testing
@testable import Fictioneer

struct ProgressMathTests {
    private let calendar = Calendar(identifier: .gregorian)

    private func day(_ key: String) -> Date {
        ProgressMath.date(fromKey: key, calendar: calendar)!
    }

    private func entry(_ date: String, words: Int, met: Bool) -> DailyProgress {
        DailyProgress(date: date, wordsWritten: words, goalMet: met, sessionsCount: 1, updatedAt: .now)
    }

    @Test func dayKeyFormatsLocally() {
        let key = ProgressMath.dayKey(for: day("2026-08-01"), calendar: calendar)
        #expect(key == "2026-08-01")
    }

    @Test func currentStreakRequiresTodayMet() {
        let progress = [
            entry("2026-07-30", words: 600, met: true),
            entry("2026-07-31", words: 700, met: true),
        ]
        // Today (08-01) has no entry → current 0, longest 2.
        let streaks = ProgressMath.streaks(progress: progress, today: day("2026-08-01"), calendar: calendar)
        #expect(streaks.current == 0)
        #expect(streaks.longest == 2)
    }

    @Test func consecutiveDaysExtendCurrentStreak() {
        let progress = [
            entry("2026-07-30", words: 600, met: true),
            entry("2026-07-31", words: 700, met: true),
            entry("2026-08-01", words: 550, met: true),
        ]
        let streaks = ProgressMath.streaks(progress: progress, today: day("2026-08-01"), calendar: calendar)
        #expect(streaks.current == 3)
        #expect(streaks.longest == 3)
    }

    @Test func missedCalendarDayBreaksCurrentButNotLongest() {
        let progress = [
            entry("2026-07-28", words: 600, met: true),
            entry("2026-07-29", words: 600, met: true),
            // gap: no entry 07-30
            entry("2026-08-01", words: 800, met: true),
        ]
        let streaks = ProgressMath.streaks(progress: progress, today: day("2026-08-01"), calendar: calendar)
        #expect(streaks.current == 1)
        #expect(streaks.longest == 3) // gaps don't break longest (Tauri parity)
    }

    @Test func unmetDayBreaksBothStreaks() {
        let progress = [
            entry("2026-07-30", words: 600, met: true),
            entry("2026-07-31", words: 100, met: false),
            entry("2026-08-01", words: 700, met: true),
        ]
        let streaks = ProgressMath.streaks(progress: progress, today: day("2026-08-01"), calendar: calendar)
        #expect(streaks.current == 1)
        #expect(streaks.longest == 1)
    }

    @Test func statsAveragesActiveDaysOnly() {
        let progress = [
            entry("2026-07-30", words: 600, met: true),
            entry("2026-07-31", words: 0, met: false),
            entry("2026-08-01", words: 400, met: false),
        ]
        let stats = ProgressMath.stats(
            progress: progress, goals: nil, totalProjectWords: 5000,
            today: day("2026-08-01"), calendar: calendar
        )
        #expect(stats.totalDaysActive == 2)
        #expect(stats.averageDailyWords == 500)
        #expect(stats.estimatedCompletionDate == nil)
    }

    @Test func estimatedCompletionFromVelocity() {
        let goals = ProgressGoals(dailyWordTarget: 500, projectWordTarget: 10_000, createdAt: .now, updatedAt: .now)
        let progress = [entry("2026-08-01", words: 1000, met: true)]
        let stats = ProgressMath.stats(
            progress: progress, goals: goals, totalProjectWords: 6000,
            today: day("2026-08-01"), calendar: calendar
        )
        // remaining 4000 at 1000/day → 4 days
        #expect(stats.estimatedCompletionDate == day("2026-08-05"))
    }

    @Test func duplicateDayEntriesDoNotTrap() {
        // Sync-conflict copies can leave two entries for the same date in the
        // manifest; the dashboard must survive and prefer the latest.
        let goals = ProgressGoals(dailyWordTarget: 500, projectWordTarget: nil, createdAt: .now, updatedAt: .now)
        let progress = [
            entry("2026-08-01", words: 100, met: false),
            entry("2026-08-01", words: 700, met: true),
            entry("2026-07-31", words: 600, met: true),
        ]
        let streaks = ProgressMath.streaks(progress: progress, today: day("2026-08-01"), calendar: calendar)
        #expect(streaks.current == 2)

        let points = ProgressMath.chartPoints(
            progress: progress, goals: goals, days: 3,
            today: day("2026-08-01"), calendar: calendar
        )
        #expect(points.count == 3)
        #expect(points.last?.wordsWritten == 700)
        #expect(points.last?.goalMet == true)
    }

    @Test func chartPointsAreDenseAndOrdered() {
        let goals = ProgressGoals(dailyWordTarget: 500, projectWordTarget: nil, createdAt: .now, updatedAt: .now)
        let progress = [entry("2026-08-01", words: 700, met: true)]
        let points = ProgressMath.chartPoints(
            progress: progress, goals: goals, days: 7,
            today: day("2026-08-01"), calendar: calendar
        )
        #expect(points.count == 7)
        #expect(points.first?.date == "2026-07-26")
        #expect(points.last?.date == "2026-08-01")
        #expect(points.last?.isToday == true)
        #expect(points.last?.wordsWritten == 700)
        #expect(points[0].wordsWritten == 0)
    }
}

@MainActor
struct ProgressTrackerTests {
    private let calendar = Calendar(identifier: .gregorian)

    private func makeTracker(initialWords: Int = 0) -> (ProgressTracker, Project, ClockBox) {
        let project = Project.makeNew(title: "T")
        if initialWords > 0 {
            let text = Array(repeating: "word", count: initialWords).joined(separator: " ")
            project.chapters[0].scenes[0].updateContent(NSAttributedString(string: text))
        }
        let clock = ClockBox(now: ProgressMath.date(fromKey: "2026-08-01", calendar: calendar)!.addingTimeInterval(10 * 3600))
        let tracker = ProgressTracker(project: project, now: { clock.now }, calendar: calendar)
        return (tracker, project, clock)
    }

    final class ClockBox {
        var now: Date
        init(now: Date) { self.now = now }
    }

    @Test func baselineIsPinnedAtSessionStart() {
        let (_, project, _) = makeTracker(initialWords: 100)
        #expect(project.dailyWordSnapshots["2026-08-01"] == 100)
    }

    @Test func wordsTodayIsDeltaFromBaseline() {
        let (tracker, project, _) = makeTracker(initialWords: 100)
        tracker.recordEdit(totalWords: 160, wordDelta: 60, characterDelta: 300)
        #expect(tracker.todaysWordCount == 60)
        // Deleting below baseline clamps at zero.
        tracker.recordEdit(totalWords: 80, wordDelta: 80, characterDelta: 400)
        #expect(tracker.todaysWordCount == 0)
        #expect(project.dailyProgress.count == 1)
    }

    @Test func sessionCountingRespectsGapAndMeaningfulness() {
        let (tracker, project, clock) = makeTracker()
        tracker.recordEdit(totalWords: 10, wordDelta: 10, characterDelta: 50)
        #expect(project.dailyProgress[0].sessionsCount == 1)

        // Tiny change 1 min later: no new session.
        clock.now = clock.now.addingTimeInterval(60)
        tracker.recordEdit(totalWords: 11, wordDelta: 1, characterDelta: 5)
        #expect(project.dailyProgress[0].sessionsCount == 1)

        // Meaningful change 10 min later: new session.
        clock.now = clock.now.addingTimeInterval(10 * 60)
        tracker.recordEdit(totalWords: 30, wordDelta: 19, characterDelta: 90)
        #expect(project.dailyProgress[0].sessionsCount == 2)
    }

    @Test func goalToastFiresOncePerDay() {
        let (tracker, project, _) = makeTracker()
        tracker.setGoals(dailyTarget: 50, projectTarget: nil)
        tracker.recordEdit(totalWords: 60, wordDelta: 60, characterDelta: 300)
        #expect(project.dailyProgress[0].goalMet)
        #expect(tracker.showGoalToast)
        tracker.showGoalToast = false
        tracker.recordEdit(totalWords: 120, wordDelta: 60, characterDelta: 300)
        #expect(!tracker.showGoalToast)
    }

    @Test func goalsAreClamped() {
        let (tracker, project, _) = makeTracker()
        tracker.setGoals(dailyTarget: 50_000, projectTarget: 5_000_000)
        #expect(project.progressGoals?.dailyWordTarget == ProgressGoals.maxDailyTarget)
        #expect(project.progressGoals?.projectWordTarget == ProgressGoals.maxProjectTarget)
    }

    @Test func dayRolloverStartsFreshBaseline() {
        let (tracker, project, clock) = makeTracker(initialWords: 100)
        tracker.recordEdit(totalWords: 200, wordDelta: 100, characterDelta: 500)
        #expect(tracker.todaysWordCount == 100)

        clock.now = clock.now.addingTimeInterval(24 * 3600)
        // First edit after midnight seeds the new day's baseline.
        tracker.recordEdit(totalWords: 250, wordDelta: 50, characterDelta: 250)
        #expect(project.dailyWordSnapshots["2026-08-02"] == 250)
        #expect(tracker.todaysWordCount == 0)
        tracker.recordEdit(totalWords: 300, wordDelta: 50, characterDelta: 250)
        #expect(tracker.todaysWordCount == 50)
        #expect(project.dailyProgress.count == 2)
    }
}
