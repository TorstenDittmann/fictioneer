import SwiftUI

/// Quiet once-per-day celebration when the daily word goal is reached.
struct GoalToast: View {
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.seal.fill")
                .foregroundStyle(Color.accentColor)
            Text("Daily goal reached")
                .font(.callout.weight(.medium))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 9)
        .background(.regularMaterial, in: .capsule)
        .overlay(Capsule().strokeBorder(.separator))
        .shadow(color: .black.opacity(0.15), radius: 10, y: 3)
        .padding(.bottom, 48)
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }
}
