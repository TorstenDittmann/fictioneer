import SwiftUI

struct ProgressDashboardView: View {
    let session: ProjectSession
    @State private var showingGoalsSheet = false

    private var progress: ProgressTracker { session.progress }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                ManuscriptLabel("Writing Progress")
                Spacer()
                Button(progress.goals == nil ? "Set Goals" : "Update Goals") {
                    showingGoalsSheet = true
                }
                .controlSize(.small)
            }

            if progress.goals != nil || progress.todaysProgress != nil {
                todayCard
                chart
                statsGrid
            } else {
                emptyState
            }
        }
        .sheet(isPresented: $showingGoalsSheet) {
            GoalsEditorSheet(session: session)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 6) {
            Image(systemName: "chart.bar.xaxis")
                .font(.title2)
                .foregroundStyle(.tertiary)
            Text("Track your writing progress")
                .font(.callout.weight(.medium))
            Text("Set a daily word goal to build a writing habit — streaks, charts, and pace live here.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(.separator))
    }

    private var todayCard: some View {
        let words = progress.todaysWordCount
        let target = progress.dailyTarget
        let percentage = progress.todaysPercentage
        let met = progress.todaysProgress?.goalMet ?? false
        return VStack(alignment: .leading, spacing: 6) {
            HStack {
                ManuscriptLabel("Today", size: 10)
                Spacer()
                Text("\(words) / \(target) words")
                    .font(.callout)
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            }
            ProgressBar(
                fraction: Double(words) / Double(max(1, target)),
                emphasized: met || percentage >= 80
            )
            Text(motivation(words: words, target: target, met: met, percentage: percentage))
                .font(.caption)
                .foregroundStyle(.secondary)
            if let sessions = progress.todaysProgress?.sessionsCount, sessions > 0 {
                Text("\(sessions) writing session\(sessions == 1 ? "" : "s") today")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(12)
        .overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(.separator))
    }

    private var chart: some View {
        let points = progress.chartPoints(days: 30)
        let maxValue = max(points.map(\.wordsWritten).max() ?? 1, points.first?.goalTarget ?? 1, 1)
        return VStack(alignment: .leading, spacing: 6) {
            ManuscriptLabel("Last 30 days", size: 10)
            GeometryReader { geometry in
                let goalY = geometry.size.height * (1 - CGFloat(points.first?.goalTarget ?? 0) / CGFloat(maxValue))
                ZStack(alignment: .bottom) {
                    // Goal line
                    Path { path in
                        path.move(to: CGPoint(x: 0, y: goalY))
                        path.addLine(to: CGPoint(x: geometry.size.width, y: goalY))
                    }
                    .stroke(Color.manuscriptIndigo.opacity(0.35), style: StrokeStyle(lineWidth: 1, dash: [4, 3]))

                    HStack(alignment: .bottom, spacing: 2) {
                        ForEach(points, id: \.date) { point in
                            let height = max(2, geometry.size.height * CGFloat(point.wordsWritten) / CGFloat(maxValue))
                            RoundedRectangle(cornerRadius: 1.5)
                                .fill(barColor(point))
                                .frame(height: point.wordsWritten > 0 ? height : 2)
                                .frame(maxWidth: .infinity, alignment: .bottom)
                                .help("\(point.date): \(point.wordsWritten) words")
                        }
                    }
                }
            }
            .frame(height: 72)
        }
        .padding(12)
        .overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(.separator))
    }

    private func barColor(_ point: ChartPoint) -> Color {
        if point.goalMet { return .manuscriptIndigo }
        if point.wordsWritten > 0 { return .manuscriptIndigo.opacity(0.45) }
        return Color.secondary.opacity(0.2)
    }

    private var statsGrid: some View {
        let stats = progress.stats
        return VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                statTile("\(stats.currentStreak)", "Current Streak")
                statTile("\(stats.longestStreak)", "Best Streak")
                statTile("\(stats.averageDailyWords)", "Avg Daily Words")
                statTile("\(stats.totalDaysActive)", "Active Days")
            }
            if let eta = stats.estimatedCompletionDate {
                Text("At this pace you'll reach your project goal around \(eta, format: .dateTime.month(.wide).day()).")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func statTile(_ value: String, _ label: String) -> some View {
        VStack(spacing: 3) {
            Text(value)
                .font(.title3.weight(.semibold))
                .monospacedDigit()
            ManuscriptLabel(label, size: 8, color: Color(nsColor: .tertiaryLabelColor))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(.separator))
    }

    private func motivation(words: Int, target: Int, met: Bool, percentage: Int) -> String {
        if met {
            let exceeded = words - target
            if exceeded > target / 2 { return "Outstanding! You're on fire today!" }
            if exceeded > 0 { return "Excellent work! You've exceeded your goal!" }
            return "Perfect! You've hit your daily goal!"
        }
        if percentage >= 80 { return "Almost there! You're so close to your goal!" }
        if percentage >= 50 { return "Great progress! You're halfway to your goal!" }
        if percentage >= 25 { return "Good start! Keep the momentum going!" }
        if words > 0 { return "Every word counts! You've made a start!" }
        return "Ready to begin? Your story is waiting!"
    }
}

struct GoalsEditorSheet: View {
    let session: ProjectSession
    @Environment(\.dismiss) private var dismiss

    @State private var dailyText: String
    @State private var projectText: String
    @State private var validationError: String?

    init(session: ProjectSession) {
        self.session = session
        _dailyText = State(initialValue: String(session.progress.dailyTarget))
        _projectText = State(initialValue: session.progress.goals?.projectWordTarget.map(String.init) ?? "")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Writing Goals")
                .font(.custom("Quattrocento-Bold", size: 20))

            VStack(alignment: .leading, spacing: 6) {
                ManuscriptLabel("Daily word goal", size: 10)
                TextField("500", text: $dailyText)
                    .textFieldStyle(.roundedBorder)
                Text("Recommended: 250–1000 words per day for consistent progress.")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }

            VStack(alignment: .leading, spacing: 6) {
                ManuscriptLabel("Project word goal (optional)", size: 10)
                TextField("e.g. 80000", text: $projectText)
                    .textFieldStyle(.roundedBorder)
            }

            if let validationError {
                Text(validationError)
                    .font(.caption)
                    .foregroundStyle(.red)
            }

            HStack {
                Spacer()
                Button("Cancel", role: .cancel) { dismiss() }
                Button("Save Goals") { save() }
                    .buttonStyle(.borderedProminent)
            }
        }
        .padding(24)
        .frame(width: 380)
    }

    private func save() {
        guard let daily = Int(dailyText), daily > 0 else {
            validationError = "Daily goal must be greater than 0"
            return
        }
        guard daily <= ProgressGoals.maxDailyTarget else {
            validationError = "Daily goal seems unreasonably high (max 10,000 words)"
            return
        }
        var projectTarget: Int?
        if !projectText.trimmingCharacters(in: .whitespaces).isEmpty {
            guard let project = Int(projectText), project > 0 else {
                validationError = "Project goal must be greater than 0"
                return
            }
            guard project <= ProgressGoals.maxProjectTarget else {
                validationError = "Project goal seems unreasonably high (max 1,000,000 words)"
                return
            }
            guard project >= daily else {
                validationError = "Project goal should be larger than daily goal"
                return
            }
            projectTarget = project
        }
        session.progress.setGoals(dailyTarget: daily, projectTarget: projectTarget)
        session.markDirty()
        dismiss()
    }
}
