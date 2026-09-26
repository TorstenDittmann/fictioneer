import AppKit
import SwiftUI

/// One button in the selection bar.
struct SelectionBarItem: Identifiable {
    let id: String
    /// Accessibility label and hover tip.
    let label: String
    var systemImage: String?
    /// Shown beside the icon (the AI action reads "Rephrase").
    var title: String?
    var isAccent = false
    /// Formatting keeps the bar up so several styles can be applied in a row.
    var keepsBarOpen = false
    let action: () -> Void
}

/// The floating bar above a text selection: formatting at the point of
/// use (the toolbar no longer carries it) plus "✦ Rephrase" when AI is
/// available. Invisible otherwise.
struct SelectionActionBarView: View {
    let items: [SelectionBarItem]
    let perform: (SelectionBarItem) -> Void

    private static let indigo = Color(red: 0x63 / 255, green: 0x66 / 255, blue: 0xF1 / 255)

    var body: some View {
        HStack(spacing: 2) {
            ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                if index > 0, item.isAccent {
                    Divider()
                        .frame(height: 14)
                        .padding(.horizontal, 3)
                }
                SelectionBarButton(item: item, accent: Self.indigo) {
                    perform(item)
                }
            }
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 3)
        .background(.regularMaterial, in: Capsule())
        .overlay(Capsule().strokeBorder(Color(nsColor: .separatorColor)))
        .shadow(color: .black.opacity(0.18), radius: 6, y: 2)
        .fixedSize()
    }
}

private struct SelectionBarButton: View {
    let item: SelectionBarItem
    let accent: Color
    let action: () -> Void
    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if let systemImage = item.systemImage {
                    Image(systemName: systemImage)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(item.isAccent ? accent : .primary)
                }
                if let title = item.title {
                    Text(title)
                        .font(.system(size: 12, weight: .semibold))
                }
            }
            .frame(minWidth: 22, minHeight: 20)
            .padding(.horizontal, item.title == nil ? 2 : 6)
            .background(
                Capsule().fill(isHovered
                    ? (item.isAccent ? accent.opacity(0.14) : Color.primary.opacity(0.08))
                    : Color.clear)
            )
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
            if hovering { NSCursor.arrow.set() }
        }
        .help(item.label)
        .accessibilityLabel(item.label)
    }
}

/// AppKit host placed inside the text view above the selection.
final class SelectionBarHostView: NSView {
    private let hostingView: NSHostingView<SelectionActionBarView>

    init(items: [SelectionBarItem], perform: @escaping (SelectionBarItem) -> Void) {
        hostingView = NSHostingView(rootView: SelectionActionBarView(items: items, perform: perform))
        super.init(frame: .zero)
        hostingView.autoresizingMask = [.width, .height]
        addSubview(hostingView)
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
}

extension EditorController {
    /// Bold, italic, underline and quote — shared by scene and note editors.
    func formattingBarItems() -> [SelectionBarItem] {
        [
            SelectionBarItem(id: "bold", label: "Bold — ⌘B", systemImage: "bold", keepsBarOpen: true) { [weak self] in
                self?.toggleBold()
            },
            SelectionBarItem(id: "italic", label: "Italic — ⌘I", systemImage: "italic", keepsBarOpen: true) { [weak self] in
                self?.toggleItalic()
            },
            SelectionBarItem(id: "underline", label: "Underline — ⌘U", systemImage: "underline", keepsBarOpen: true) { [weak self] in
                self?.toggleUnderline()
            },
            SelectionBarItem(id: "quote", label: "Blockquote", systemImage: "text.quote", keepsBarOpen: true) { [weak self] in
                self?.applyBlockStyle(.blockquote)
            },
        ]
    }

    /// Shows the bar above stabilized selections and hides it on edits.
    func attachSelectionBar(to textView: FictioneerTextView, items: @escaping () -> [SelectionBarItem]) {
        textView.selectionBarItems = items
        selectionChangeObservers.append { [weak textView] in
            textView?.scheduleSelectionBarUpdate()
        }
        documentEditObservers.append { [weak textView] in
            textView?.dismissSelectionBar()
        }
    }
}
