import SwiftUI

struct ExportView: View {
    let model: ExportModel

    var body: some View {
        HStack(spacing: 0) {
            ExportSidebar(model: model)
                .frame(width: 400)
            Divider()
            ExportPreviewPane(model: model)
        }
        .frame(minWidth: 1020, minHeight: 680)
        .ignoresSafeArea(.container, edges: .top)
        .onChange(of: model.project.book) { model.bookDidChange() }
        .onChange(of: model.project.title) { model.bookDidChange() }
        .onChange(of: model.project.details) { model.bookDidChange() }
        .onChange(of: model.project.coverImage) { model.bookDidChange() }
    }
}

// MARK: - Sidebar

private struct ExportSidebar: View {
    @Bindable var model: ExportModel

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 14) {
                VStack(alignment: .leading, spacing: 2) {
                    ManuscriptLabel("Export", size: 10)
                    Text(model.project.title)
                        .font(.custom("Quattrocento-Bold", size: 22))
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
                FormatPicker(selection: $model.options.format)
            }
            .padding(.horizontal, 20)
            .padding(.top, 40)
            .padding(.bottom, 14)

            if model.options.format == .epub {
                PaneBar(selection: $model.pane)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 4)
                Divider()
                Group {
                    switch model.pane {
                    case .details: DetailsPane(model: model)
                    case .cover: CoverPane(model: model)
                    case .design: DesignPane(model: model)
                    case .matter: PagesPane(model: model)
                    case .contents: ContentsPane(model: model)
                    }
                }
                .frame(maxHeight: .infinity)
            } else {
                Divider()
                ManuscriptPane(model: model)
                    .frame(maxHeight: .infinity)
            }

            Divider()
            ExportFooter(model: model)
        }
        .background(.background)
    }
}

private struct FormatPicker: View {
    @Binding var selection: ExportFormat

    var body: some View {
        HStack(spacing: 8) {
            ForEach(ExportFormat.allCases) { format in
                let isSelected = selection == format
                Button {
                    selection = format
                } label: {
                    VStack(alignment: .leading, spacing: 6) {
                        Image(systemName: format.systemImage)
                            .font(.system(size: 18, weight: .regular))
                            .foregroundStyle(isSelected ? Color.accentColor : .secondary)
                        Text(format.shortLabel)
                            .font(.system(size: 12, weight: .semibold))
                        Text(format == .epub ? "EPUB" : format == .rtf ? "RTF" : "TXT")
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(10)
                    .background(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(isSelected ? Color.accentColor.opacity(0.1) : Color.primary.opacity(0.03))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .strokeBorder(isSelected ? Color.accentColor : Color.primary.opacity(0.1), lineWidth: isSelected ? 1.5 : 1)
                    )
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .help(format.detail)
                .accessibilityLabel("\(format.shortLabel), \(format.detail)")
                .accessibilityAddTraits(isSelected ? .isSelected : [])
            }
        }
    }
}

private struct PaneBar: View {
    @Binding var selection: ExportPane

    var body: some View {
        HStack(spacing: 2) {
            ForEach(ExportPane.allCases) { pane in
                let isSelected = selection == pane
                Button {
                    selection = pane
                } label: {
                    VStack(spacing: 3) {
                        Image(systemName: pane.systemImage)
                            .font(.system(size: 13))
                        Text(pane.title)
                            .font(.system(size: 10.5, weight: isSelected ? .semibold : .regular))
                    }
                    .foregroundStyle(isSelected ? Color.accentColor : .secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(isSelected ? Color.accentColor.opacity(0.1) : .clear)
                    )
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(pane.title)
                .accessibilityAddTraits(isSelected ? .isSelected : [])
            }
        }
    }
}

// MARK: - Footer

private struct ExportFooter: View {
    @Bindable var model: ExportModel
    @State private var showsIssues = false

    var body: some View {
        HStack(spacing: 10) {
            readiness
            Spacer()
            if model.isExporting {
                ProgressView().controlSize(.small)
            }
            Button {
                model.export()
            } label: {
                Text("Export \(model.options.format.shortLabel)…")
                    .frame(minWidth: 120)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .keyboardShortcut(.defaultAction)
            .disabled(!model.canExport)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
    }

    @ViewBuilder
    private var readiness: some View {
        let issues = model.issues
        let worst = issues.first?.severity
        Button {
            showsIssues.toggle()
        } label: {
            HStack(spacing: 6) {
                Image(systemName: icon(for: worst))
                    .foregroundStyle(color(for: worst))
                Text(summary(issues))
                    .font(.callout)
                    .foregroundStyle(.primary)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(issues.isEmpty)
        .popover(isPresented: $showsIssues, arrowEdge: .top) {
            IssueList(issues: issues) { issue in
                showsIssues = false
                model.pane = issue.pane
            }
        }
        .accessibilityLabel(summary(issues))
        .accessibilityHint(issues.isEmpty ? "" : "Shows what to check before exporting")
    }

    private func summary(_ issues: [ReadinessIssue]) -> String {
        if issues.contains(where: { $0.severity == .blocking }) { return "Can’t export yet" }
        if issues.isEmpty { return "Ready to export" }
        let count = issues.count
        return count == 1 ? "1 thing to check" : "\(count) things to check"
    }

    private func icon(for severity: ReadinessIssue.Severity?) -> String {
        switch severity {
        case nil: "checkmark.circle.fill"
        case .blocking: "xmark.octagon.fill"
        case .warning: "exclamationmark.triangle.fill"
        case .suggestion: "lightbulb.fill"
        }
    }

    private func color(for severity: ReadinessIssue.Severity?) -> Color {
        switch severity {
        case nil: .green
        case .blocking: .red
        case .warning: .orange
        case .suggestion: .yellow
        }
    }
}

private struct IssueList: View {
    let issues: [ReadinessIssue]
    let onSelect: (ReadinessIssue) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            ForEach(issues) { issue in
                Button {
                    onSelect(issue)
                } label: {
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Image(systemName: issue.severity == .suggestion ? "lightbulb" : "exclamationmark.triangle")
                            .foregroundStyle(issue.severity == .blocking ? .red : issue.severity == .warning ? .orange : .secondary)
                            .frame(width: 16)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(issue.message)
                                .fixedSize(horizontal: false, vertical: true)
                            Text("Open \(issue.pane.title)")
                                .font(.caption)
                                .foregroundStyle(Color.accentColor)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(8)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(8)
        .frame(width: 320)
    }
}

// MARK: - Preview pane

private struct ExportPreviewPane: View {
    @Bindable var model: ExportModel

    var body: some View {
        let preview = model.preview
        VStack(spacing: 0) {
            PreviewToolbar(preview: preview, isEpub: model.options.format == .epub)
                .padding(.horizontal, 20)
                .padding(.top, 36)
                .padding(.bottom, 10)
            ZStack(alignment: .top) {
                BookPreviewStage(controller: preview)
                if let outcome = model.outcome {
                    OutcomeBanner(model: model, outcome: outcome)
                        .padding(.top, 8)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
            .animation(.snappy, value: model.outcome)
            PageControls(preview: preview)
                .padding(.bottom, 16)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(nsColor: .underPageBackgroundColor))
    }
}

private struct PreviewToolbar: View {
    @Bindable var preview: BookPreviewController
    let isEpub: Bool

    var body: some View {
        HStack(spacing: 14) {
            Picker("Device", selection: $preview.device) {
                ForEach(BookPreviewController.Device.allCases) { device in
                    Label(device.label, systemImage: device.systemImage).tag(device)
                }
            }
            .pickerStyle(.segmented)
            .labelStyle(.iconOnly)
            .fixedSize()
            .help("Preview size")

            HStack(spacing: 6) {
                ForEach(BookPreviewController.Theme.allCases) { theme in
                    Button {
                        preview.theme = theme
                    } label: {
                        Circle()
                            .fill(theme.background)
                            .overlay(Circle().strokeBorder(Color.primary.opacity(0.25), lineWidth: 1))
                            .overlay(
                                Circle().strokeBorder(Color.accentColor, lineWidth: 2)
                                    .padding(-3)
                                    .opacity(preview.theme == theme ? 1 : 0)
                            )
                            .frame(width: 16, height: 16)
                    }
                    .buttonStyle(.plain)
                    .help("\(theme.label) reading theme")
                    .accessibilityLabel("\(theme.label) theme")
                    .accessibilityAddTraits(preview.theme == theme ? .isSelected : [])
                }
            }

            ControlGroup {
                Button {
                    preview.textScale = max(70, preview.textScale - 10)
                } label: {
                    Image(systemName: "textformat.size.smaller")
                }
                .help("Smaller text")
                .accessibilityLabel("Smaller text")
                Button {
                    preview.textScale = min(200, preview.textScale + 10)
                } label: {
                    Image(systemName: "textformat.size.larger")
                }
                .help("Larger text")
                .accessibilityLabel("Larger text")
            }
            .fixedSize()

            Spacer()

            if isEpub, let spine = preview.publication?.spine, !spine.isEmpty {
                Menu {
                    ForEach(Array(spine.enumerated()), id: \.offset) { index, item in
                        Button(item.title) { preview.go(toSpineIndex: index) }
                    }
                } label: {
                    Label(preview.currentItem?.title ?? "Go to", systemImage: "list.bullet")
                        .lineLimit(1)
                }
                .menuStyle(.borderlessButton)
                .fixedSize()
                .help("Jump to a page of the book")
            }
        }
    }
}

private struct PageControls: View {
    let preview: BookPreviewController

    var body: some View {
        HStack(spacing: 16) {
            Button {
                preview.previousPage()
            } label: {
                Image(systemName: "chevron.left")
                    .frame(width: 24, height: 24)
            }
            .disabled(!preview.canGoBack)
            .accessibilityLabel("Previous page")

            Text("Page \(preview.page + 1) of \(preview.pageCount)")
                .font(.callout)
                .monospacedDigit()
                .foregroundStyle(.secondary)
                .frame(minWidth: 110)

            Button {
                preview.nextPage()
            } label: {
                Image(systemName: "chevron.right")
                    .frame(width: 24, height: 24)
            }
            .disabled(!preview.canGoForward)
            .accessibilityLabel("Next page")
        }
        .buttonStyle(.borderless)
    }
}

private struct OutcomeBanner: View {
    let model: ExportModel
    let outcome: ExportModel.Outcome

    var body: some View {
        HStack(spacing: 12) {
            switch outcome {
            case .exported(let url):
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                Text("Exported “\(url.lastPathComponent)”")
                    .lineLimit(1)
                    .truncationMode(.middle)
                Button("Show in Finder") { model.revealExport() }
                if url.pathExtension == "epub" {
                    Button("Open in Books") { model.openExportInBooks() }
                }
            case .failed(let message):
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
                Text(message)
                    .lineLimit(2)
            }
            Button {
                model.outcome = nil
            } label: {
                Image(systemName: "xmark")
            }
            .buttonStyle(.borderless)
            .accessibilityLabel("Dismiss")
        }
        .controlSize(.small)
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(.regularMaterial, in: Capsule())
        .shadow(color: .black.opacity(0.12), radius: 10, y: 4)
    }
}
