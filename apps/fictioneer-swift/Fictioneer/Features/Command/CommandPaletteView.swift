import AppKit
import SwiftUI

struct PaletteItem: Identifiable {
    enum Group: Int, CaseIterable {
        case recent, navigation, actions, notes, scenes

        var label: String {
            switch self {
            case .recent: "Recent"
            case .navigation: "Navigation"
            case .actions: "Actions"
            case .notes: "Notes"
            case .scenes: "Scenes"
            }
        }
    }

    let id: String
    let group: Group
    let title: String
    let subtitle: String
    let icon: String
    let keywords: [String]
    let action: () -> Void
}

/// ⌘K command palette: fuzzy-filtered commands, navigation, and content.
struct CommandPaletteView: View {
    @Environment(AppModel.self) private var appModel
    let session: ProjectSession

    @State private var query = ""
    @State private var selectedIndex = 0
    @FocusState private var searchFocused: Bool

    var body: some View {
        let filtered = filteredItems()
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Search commands, scenes, and notes…", text: $query)
                    .textFieldStyle(.plain)
                    .font(.title3)
                    .focused($searchFocused)
                    .onSubmit { activate(filtered) }
                Text("esc")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                    .overlay(RoundedRectangle(cornerRadius: 4).strokeBorder(.separator))
            }
            .padding(14)
            Divider()

            if filtered.isEmpty {
                VStack(spacing: 4) {
                    Text("No results found")
                        .font(.callout.weight(.medium))
                    Text("Try searching for something else.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
            } else {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 2) {
                            ForEach(Array(filtered.enumerated()), id: \.element.id) { index, item in
                                row(item, isSelected: index == selectedIndex, showGroupHeader: showsHeader(filtered, index))
                                    .id(item.id)
                                    .onTapGesture { item.action(); dismiss() }
                            }
                        }
                        .padding(8)
                    }
                    .frame(maxHeight: 380)
                    .onChange(of: selectedIndex) {
                        if selectedIndex < filtered.count {
                            proxy.scrollTo(filtered[selectedIndex].id)
                        }
                    }
                }
            }

            Divider()
            HStack(spacing: 12) {
                legend("↑↓", "navigate")
                legend("↵", "select")
                legend("esc", "close")
                Spacer()
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
        }
        .frame(width: 560)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(.separator))
        .shadow(color: .black.opacity(0.25), radius: 24, y: 8)
        .onAppear {
            NSApp.keyWindow?.makeFirstResponder(nil)
            searchFocused = true
        }
        .onChange(of: query) { selectedIndex = 0 }
        .onKeyPress(.downArrow) {
            selectedIndex = min(selectedIndex + 1, max(0, filteredItems().count - 1))
            return .handled
        }
        .onKeyPress(.upArrow) {
            selectedIndex = max(0, selectedIndex - 1)
            return .handled
        }
        .onKeyPress(.escape) {
            dismiss()
            return .handled
        }
    }

    private func showsHeader(_ items: [PaletteItem], _ index: Int) -> Bool {
        index == 0 || items[index].group != items[index - 1].group
    }

    private func row(_ item: PaletteItem, isSelected: Bool, showGroupHeader: Bool) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            if showGroupHeader {
                Text(item.group.label)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.tertiary)
                    .padding(.horizontal, 8)
                    .padding(.top, 6)
            }
            HStack(spacing: 10) {
                Image(systemName: item.icon)
                    .frame(width: 18)
                    .foregroundStyle(isSelected ? Color.accentColor : Color.secondary)
                VStack(alignment: .leading, spacing: 1) {
                    Text(item.title)
                        .font(.callout.weight(.medium))
                        .lineLimit(1)
                    if !item.subtitle.isEmpty {
                        Text(item.subtitle)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
                Spacer()
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(
                RoundedRectangle(cornerRadius: 7)
                    .fill(isSelected ? AnyShapeStyle(Color.accentColor.opacity(0.18)) : AnyShapeStyle(.clear))
            )
            .contentShape(Rectangle())
        }
    }

    private func legend(_ keys: String, _ label: String) -> some View {
        HStack(spacing: 4) {
            Text(keys).monospaced()
            Text(label)
        }
        .font(.caption2)
        .foregroundStyle(.tertiary)
    }

    private func activate(_ items: [PaletteItem]) {
        guard selectedIndex < items.count else { return }
        items[selectedIndex].action()
        dismiss()
    }

    private func dismiss() {
        session.isCommandPaletteVisible = false
        // Return keyboard focus to the editor.
        DispatchQueue.main.async {
            if let window = NSApp.keyWindow,
               let textView = window.firstResponderCandidateTextView {
                window.makeFirstResponder(textView)
            }
        }
    }

    // MARK: - Items

    private func allItems() -> [PaletteItem] {
        let project = session.project
        var items: [PaletteItem] = []

        let recentScenes = project.allScenes
            .sorted { $0.updatedAt > $1.updatedAt }
            .prefix(10)
        for scene in recentScenes.prefix(3) {
            let chapter = project.chapter(containing: scene.id)
            items.append(PaletteItem(
                id: "recent-\(scene.id)", group: .recent,
                title: scene.title,
                subtitle: "Recent • \(chapter?.title ?? "") • \(scene.wordCount) words",
                icon: "clock",
                keywords: ["recent", "scene", scene.title, chapter?.title ?? ""],
                action: { session.selectedItem = .scene(scene.id) }
            ))
        }

        items.append(PaletteItem(
            id: "nav-overview", group: .navigation,
            title: "Project Overview", subtitle: "Go to project dashboard",
            icon: "house", keywords: ["overview", "dashboard", "project", "home"],
            action: { session.selectedItem = .overview }
        ))
        items.append(PaletteItem(
            id: "nav-search", group: .navigation,
            title: "Search Scenes", subtitle: "Full-text search across all scenes",
            icon: "magnifyingglass", keywords: ["search", "find", "text"],
            action: { session.selectedItem = .search }
        ))

        items.append(PaletteItem(
            id: "action-new-chapter", group: .actions,
            title: "New Chapter", subtitle: "Create a new chapter",
            icon: "plus.rectangle.on.folder", keywords: ["new", "create", "chapter", "add"],
            action: { session.createChapter() }
        ))
        items.append(PaletteItem(
            id: "action-new-scene", group: .actions,
            title: "New Scene", subtitle: "Create a new scene in the current chapter",
            icon: "plus.square", keywords: ["new", "create", "scene", "add", "write"],
            action: { session.createSceneInCurrentChapter() }
        ))
        items.append(PaletteItem(
            id: "action-new-note", group: .actions,
            title: "New Note", subtitle: "Create a note for characters, ideas, and reference",
            icon: "note.text.badge.plus", keywords: ["new", "create", "note", "character", "idea"],
            action: { session.createNote() }
        ))
        items.append(PaletteItem(
            id: "action-export", group: .actions,
            title: "Export Project…", subtitle: "Compile as RTF, EPUB, or plain text",
            icon: "square.and.arrow.up", keywords: ["export", "epub", "rtf", "compile"],
            action: { appModel.isExportSheetRequested = true }
        ))
        items.append(PaletteItem(
            id: "action-goals", group: .actions,
            title: "Writing Goals", subtitle: "View progress on the overview",
            icon: "target", keywords: ["goals", "progress", "streak", "words"],
            action: { session.selectedItem = .overview }
        ))
        items.append(PaletteItem(
            id: "action-focus", group: .actions,
            title: session.isFocusMode ? "Exit Focus Mode" : "Enter Focus Mode",
            subtitle: "Distraction-free writing",
            icon: session.isFocusMode ? "eye" : "eye.slash",
            keywords: ["focus", "distraction", "free", "zen", "mode"],
            action: { session.isFocusMode.toggle() }
        ))

        for note in project.notes {
            let tags = note.tags.isEmpty
                ? "No tags"
                : "Tags: " + note.tags.prefix(3).joined(separator: ", ") + (note.tags.count > 3 ? "…" : "")
            items.append(PaletteItem(
                id: "note-\(note.id)", group: .notes,
                title: note.title, subtitle: tags,
                icon: "note.text",
                keywords: ["note", note.title] + note.tags,
                action: { session.selectedItem = .note(note.id) }
            ))
        }

        let recentIDs = Set(recentScenes.map(\.id))
        for chapter in project.chapters {
            for scene in chapter.scenes where !recentIDs.contains(scene.id) {
                items.append(PaletteItem(
                    id: "scene-\(scene.id)", group: .scenes,
                    title: scene.title,
                    subtitle: "\(chapter.title) • \(scene.wordCount) words",
                    icon: "doc.text",
                    keywords: ["scene", scene.title, chapter.title, "write", "edit"],
                    action: { session.selectedItem = .scene(scene.id) }
                ))
            }
        }
        return items
    }

    private func filteredItems() -> [PaletteItem] {
        let items = allItems()
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return items }
        let scored = items.compactMap { item -> (PaletteItem, Double)? in
            let haystack = item.title + " " + item.keywords.joined(separator: " ")
            let score = CommandScore.score(trimmed, in: haystack)
            return score > 0 ? (item, score) : nil
        }
        // Groups ordered by their best score; items by score within group.
        let groupBest = Dictionary(grouping: scored, by: { $0.0.group })
            .mapValues { $0.map(\.1).max() ?? 0 }
        return scored
            .sorted { lhs, rhs in
                let lg = groupBest[lhs.0.group] ?? 0
                let rg = groupBest[rhs.0.group] ?? 0
                if lg != rg { return lg > rg }
                if lhs.0.group != rhs.0.group { return lhs.0.group.rawValue < rhs.0.group.rawValue }
                return lhs.1 > rhs.1
            }
            .map(\.0)
    }
}

private extension NSWindow {
    var firstResponderCandidateTextView: NSTextView? {
        func find(in view: NSView) -> NSTextView? {
            if let textView = view as? FictioneerTextView { return textView }
            for subview in view.subviews {
                if let found = find(in: subview) { return found }
            }
            return nil
        }
        return contentView.flatMap(find(in:))
    }
}
