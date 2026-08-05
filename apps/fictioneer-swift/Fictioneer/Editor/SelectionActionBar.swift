import AppKit
import SwiftUI

/// The floating "✦ Rephrase" pill that appears above a text selection —
/// AI at the moment of intent, invisible otherwise.
struct SelectionActionBarView: View {
    var isHovered: Bool

    private static let indigo = Color(red: 0x63 / 255, green: 0x66 / 255, blue: 0xF1 / 255)

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: "sparkles")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Self.indigo)
            Text("Rephrase")
                .font(.system(size: 12, weight: .semibold))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(.regularMaterial, in: Capsule())
        .background(
            Capsule().fill(isHovered ? Self.indigo.opacity(0.14) : Color.clear)
        )
        .overlay(
            Capsule().strokeBorder(isHovered ? Self.indigo.opacity(0.55) : Color(nsColor: .separatorColor))
        )
        .shadow(color: .black.opacity(0.18), radius: 6, y: 2)
    }
}

/// AppKit host: own tracking area (cursor + hover state), click → action.
final class SelectionBarHostView: NSView {
    var onAction: (() -> Void)?

    private var hostingView: NSHostingView<SelectionActionBarView>
    private var isHovered = false {
        didSet {
            hostingView.rootView = SelectionActionBarView(isHovered: isHovered)
        }
    }

    init() {
        hostingView = NSHostingView(rootView: SelectionActionBarView(isHovered: false))
        super.init(frame: .zero)
        hostingView.autoresizingMask = [.width, .height]
        addSubview(hostingView)

        setAccessibilityElement(true)
        setAccessibilityRole(.button)
        setAccessibilityLabel("Rephrase selection")
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    var pillSize: NSSize {
        hostingView.fittingSize
    }

    override func layout() {
        super.layout()
        hostingView.frame = bounds
    }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        trackingAreas.forEach(removeTrackingArea)
        addTrackingArea(NSTrackingArea(
            rect: bounds,
            options: [.mouseEnteredAndExited, .activeInKeyWindow],
            owner: self,
            userInfo: nil
        ))
    }

    override func mouseEntered(with event: NSEvent) {
        NSCursor.arrow.set()
        isHovered = true
    }

    override func mouseExited(with event: NSEvent) {
        isHovered = false
    }

    override func mouseDown(with event: NSEvent) {
        onAction?()
    }

    override func accessibilityPerformPress() -> Bool {
        onAction?()
        return true
    }
}
