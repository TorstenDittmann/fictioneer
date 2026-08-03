import SwiftUI

/// The page's stats folio (docked at the page foot, below the prose so it
/// never covers it): collapsed it shows score + counts; expanded it mirrors
/// the Tauri stats pill — sweet-spot bar, readability, prose metrics, top
/// issues — pushing the editor up rather than overlaying it.
struct AnalysisPanelView: View {
    let analysis: AnalysisCoordinator
    let scene: Scene
    let aiReady: Bool

    @State private var isExpanded = false

    private static let targetMin = 800
    private static let targetMax = 1800

    var body: some View {
        VStack(alignment: .trailing, spacing: 0) {
            if isExpanded, let result = analysis.result {
                expandedContent(result)
                    .frame(width: 300, alignment: .leading)
                    .padding(12)
                Divider()
            }
            header
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
        .background(Color(nsColor: EditorTheme.paperBackground))
        .onContinuousHover { phase in
            if case .active = phase {
                NSCursor.arrow.set()
            }
        }
    }

    private var header: some View {
        Button {
            isExpanded.toggle()
        } label: {
            HStack(spacing: 6) {
                if aiReady {
                    Image(systemName: "sparkle")
                        .font(.caption2)
                        .foregroundStyle(Color.accentColor)
                        .hoverTip("Hold ⌥ for an AI continuation · Tab accepts")
                }
                if let result = analysis.result {
                    scoreRing(result.overallScore)
                }
                Text("\(scene.wordCount) words · \(scene.characterCount) chars")
                    .font(.caption)
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
                Image(systemName: isExpanded ? "chevron.down" : "chevron.up")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func expandedContent(_ result: AnalysisResult) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Scene progress")
                        .font(.caption.weight(.medium))
                    Spacer()
                    Text("\(Self.targetMin)–\(Self.targetMax) words")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
                ProgressBar(
                    fraction: Double(scene.wordCount) / Double(Self.targetMax),
                    emphasized: scene.wordCount >= Self.targetMin
                )
            }

            Text(result.summary)
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            VStack(alignment: .leading, spacing: 3) {
                Text("Readability")
                    .font(.caption.weight(.medium))
                metricRow("Reading Ease", String(format: "%.1f", result.readability.fleschReadingEase))
                metricRow("Grade Level", String(format: "%.1f", result.readability.fleschKincaidGrade))
            }

            VStack(alignment: .leading, spacing: 3) {
                Text("Prose Metrics")
                    .font(.caption.weight(.medium))
                metricRow(
                    "Adverbs",
                    String(format: "%.1f%%", result.metrics.adverbPercentage),
                    warn: result.metrics.adverbPercentage > 2
                )
                metricRow(
                    "Passive Voice",
                    String(format: "%.1f%%", result.metrics.passiveVoicePercentage),
                    warn: result.metrics.passiveVoicePercentage > 15
                )
                metricRow("Filter Words", "\(result.metrics.filterWordCount)")
                metricRow("Dialogue", "\(result.metrics.dialoguePercentage)%")
                metricRow("Sentence Variety", "\(result.metrics.sentenceVariety)/100")
            }

            if !result.topIssues.isEmpty {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Top Issues")
                        .font(.caption.weight(.medium))
                    ForEach(Array(result.topIssues.prefix(5).enumerated()), id: \.offset) { _, issue in
                        HStack(spacing: 6) {
                            Circle()
                                .fill(issueColor(issue.severity))
                                .frame(width: 6, height: 6)
                            Text(issue.message)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                        }
                    }
                }
            }
        }
    }

    private func metricRow(_ label: String, _ value: String, warn: Bool = false) -> some View {
        HStack {
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.caption2)
                .monospacedDigit()
                .foregroundStyle(warn ? Color.yellow : Color.primary)
        }
    }

    /// The prose score as a gauge ring — the one place the brand's
    /// indigo→violet gradient appears inside the app. Static colors, never the
    /// dynamic accent provider (see the ProgressBar crash note).
    private func scoreRing(_ score: Int) -> some View {
        let indigo = Color(red: 0x63 / 255, green: 0x66 / 255, blue: 0xF1 / 255)
        let violet = Color(red: 0x8B / 255, green: 0x5C / 255, blue: 0xF6 / 255)
        return ZStack {
            Circle()
                .stroke(.quaternary.opacity(0.6), lineWidth: 2.5)
            Circle()
                .trim(from: 0, to: Double(score) / 100)
                .stroke(
                    AngularGradient(
                        colors: [indigo, violet],
                        center: .center,
                        startAngle: .degrees(0),
                        endAngle: .degrees(360)
                    ),
                    style: StrokeStyle(lineWidth: 2.5, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
            Text("\(score)")
                .font(.system(size: 8.5, weight: .bold))
                .monospacedDigit()
                .foregroundStyle(.secondary)
        }
        .frame(width: 22, height: 22)
        .padding(.vertical, 1)
    }

    private func scoreColor(_ score: Int) -> Color {
        if score >= 70 { return .green }
        if score >= 50 { return .yellow }
        return .red
    }

    private func issueColor(_ severity: AnalysisSeverity) -> Color {
        switch severity {
        case .error: .red
        case .warning: .yellow
        case .info: .blue
        }
    }
}
