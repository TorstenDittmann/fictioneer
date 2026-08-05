import SwiftUI

/// Quiet once-per-day celebration when the daily word goal is reached.
struct GoalToast: View {
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.seal.fill")
                .foregroundStyle(Color.manuscriptIndigo)
            ManuscriptLabel("Daily goal reached", size: 11, color: .primary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 9)
        .background(.regularMaterial, in: .capsule)
        .overlay(Capsule().strokeBorder(.separator))
        .shadow(color: .black.opacity(0.15), radius: 10, y: 3)
        .padding(.bottom, 48)
        .transition(.move(edge: .bottom).combined(with: .opacity))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Daily goal reached")
    }
}
