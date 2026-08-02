import AppKit
import SwiftUI

nonisolated struct MarginIssue: Equatable, Sendable {
    var type: AnalysisType
    var message: String
    var suggestion: String?
}

nonisolated struct MarginAnnotation: Equatable, Sendable {
    /// Anchor range (the first flagged range on the line); used to recompute
    /// the chip's position after relayout.
    var lineRange: NSRange
    var items: [MarginIssue]
}

nonisolated enum AnalysisMarginGrouping {
    /// Groups highlights into per-line annotations, preserving encounter order.
    /// `lineIndex` maps a highlight range to a stable line identifier.
    static func groupIntoLines(
        _ highlights: [AnalysisHighlight],
        lineIndex: (NSRange) -> Int
    ) -> [MarginAnnotation] {
        var order: [Int] = []
        var anchors: [Int: NSRange] = [:]
        var items: [Int: [MarginIssue]] = [:]
        for highlight in highlights {
            let line = lineIndex(highlight.range)
            if anchors[line] == nil {
                anchors[line] = highlight.range
                order.append(line)
            }
            items[line, default: []].append(MarginIssue(
                type: highlight.type,
                message: highlight.message,
                suggestion: highlight.suggestion
            ))
        }
        return order.map { line in
            MarginAnnotation(lineRange: anchors[line]!, items: items[line]!)
        }
    }
}

// MARK: - SwiftUI content

struct AnalysisMarginChipView: View {
    let annotation: MarginAnnotation

    private var distinctTypes: [AnalysisType] {
        var seen: [AnalysisType] = []
        for item in annotation.items where !seen.contains(item.type) {
            seen.append(item.type)
        }
        return seen
    }

    var body: some View {
        HStack(spacing: 5) {
            HStack(spacing: 2) {
                ForEach(Array(distinctTypes.prefix(3).enumerated()), id: \.offset) { _, type in
                    Circle()
                        .fill(Color(nsColor: AnalysisHighlighter.style(for: type).underlineColor.withAlphaComponent(1)))
                        .frame(width: 5, height: 5)
                }
            }
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .padding(.horizontal, 7)
        .padding(.vertical, 3)
        .background(.quaternary.opacity(0.4), in: Capsule())
    }

    private var label: String {
        let first = annotation.items[0].type.label
        let extra = annotation.items.count - 1
        return extra > 0 ? "\(first) +\(extra)" : first
    }
}

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
            }
        }
        .padding(12)
        .frame(width: 300, alignment: .leading)
    }
}

// MARK: - AppKit chip host (own tracking area — no NSTextView interference)

final class MarginChipHostView: NSView {
    let annotation: MarginAnnotation
    private let hostingView: NSHostingView<AnalysisMarginChipView>
    private var popover: NSPopover?

    init(annotation: MarginAnnotation) {
        self.annotation = annotation
        self.hostingView = NSHostingView(rootView: AnalysisMarginChipView(annotation: annotation))
        super.init(frame: .zero)
        hostingView.autoresizingMask = [.width, .height]
        addSubview(hostingView)
    }

    /// The pill's natural size — the host frame must match it exactly, or the
    /// invisible remainder eats editor clicks and misplaces the popover anchor.
    var pillSize: NSSize {
        hostingView.fittingSize
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
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
        showPopover()
    }

    override func mouseExited(with event: NSEvent) {
        popover?.close()
        popover = nil
    }

    override func mouseDown(with event: NSEvent) {
        if let popover, popover.isShown {
            popover.close()
            self.popover = nil
        } else {
            showPopover()
        }
    }

    private func showPopover() {
        guard popover?.isShown != true else { return }
        let newPopover = NSPopover()
        newPopover.behavior = .transient
        newPopover.animates = false
        newPopover.contentViewController = NSHostingController(
            rootView: AnalysisIssueListView(items: annotation.items)
        )
        newPopover.show(relativeTo: bounds, of: self, preferredEdge: .maxX)
        popover = newPopover
    }
}
