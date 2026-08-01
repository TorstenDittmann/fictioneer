import SwiftUI

/// Pure-SwiftUI hover tooltip. `.help(_:)` rides AppKit's tooltip machinery,
/// which is unreliable for views floating over the NSTextView — this one is
/// rendered entirely by SwiftUI.
struct HoverTipModifier: ViewModifier {
    let text: String
    @State private var isShowing = false
    @State private var hoverTask: Task<Void, Never>?

    func body(content: Content) -> some View {
        content
            .onHover { hovering in
                hoverTask?.cancel()
                if hovering {
                    hoverTask = Task {
                        try? await Task.sleep(for: .milliseconds(600))
                        guard !Task.isCancelled else { return }
                        withAnimation(.easeOut(duration: 0.12)) {
                            isShowing = true
                        }
                    }
                } else {
                    withAnimation(.easeOut(duration: 0.1)) {
                        isShowing = false
                    }
                }
            }
            .overlay(alignment: .bottom) {
                if isShowing {
                    Text(text)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 6))
                        .overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(.separator))
                        .fixedSize()
                        .offset(y: 32)
                        .allowsHitTesting(false)
                        .transition(.opacity)
                        .zIndex(10)
                }
            }
    }
}

extension View {
    func hoverTip(_ text: String) -> some View {
        modifier(HoverTipModifier(text: text))
    }
}
