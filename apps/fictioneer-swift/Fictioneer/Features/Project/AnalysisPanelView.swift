import SwiftUI

/// The expandable stats capsule (bottom-right of the editor): collapsed it
/// shows score + counts; expanded it mirrors the Tauri stats pill — sweet-spot
/// bar, readability, prose metrics, top issues.
struct AnalysisPanelView: View {
    let analysis: AnalysisCoordinator
    let scene: Scene
    let aiReady: Bool

    @State private var isExpanded = false

    private static let targetMin = 800
    private static let targetMax = 1800

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if isExpanded, let result = analysis.result {
                expandedContent(result)
                    .padding(12)
                Divider()
            }
            header
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
        }
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: isExpanded ? 12 : 14))
        .overlay(
            RoundedRectangle(cornerRadius: isExpanded ? 12 : 14)
                .strokeBorder(.separator)
        )
        .frame(maxWidth: isExpanded ? 300 : nil)
        .padding(12)
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
                        .help("Hold ⌥ for an AI continuation · Tab accepts")
                }
                if let result = analysis.result {
                    Text("\(result.overallScore)")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(scoreColor(result.overallScore))
                        .monospacedDigit()
                    Text("score ·")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
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
