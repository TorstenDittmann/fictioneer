import AppKit
import SwiftUI

nonisolated struct MarginIssue: Equatable, Sendable {
    var type: AnalysisType
    var message: String
    var suggestion: String?
}

// MARK: - SwiftUI content

struct AnalysisIssueListView: View {
    let items: [MarginIssue]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                HStack(alignment: .top, spacing: 8) {
                    Circle()
                        .fill(Color(nsColor: AnalysisHighlighter.style(for: item.type).underlineColor.withAlphaComponent(1)))
                        .frame(width: 7, height: 7)
                        .padding(.top, 4)
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.message)
                            .font(.callout)
                            .fixedSize(horizontal: false, vertical: true)
                        if let suggestion = item.suggestion {
                            Text(suggestion)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
                .accessibilityElement(children: .combine)
            }
        }
        .padding(12)
        .frame(width: 300, alignment: .leading)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(.separator))
        .shadow(color: .black.opacity(0.18), radius: 10, y: 3)
    }
}
