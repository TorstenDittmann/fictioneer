import SwiftUI

/// Full-text search across scenes — the `.search` detail view.
struct SearchResultsView: View {
    let session: ProjectSession

    @State private var query = ""
    @State private var results: [SceneSearchResult] = []
    @State private var searchTask: Task<Void, Never>?
    @FocusState private var fieldFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Search Scenes")
                    .font(.custom("Quattrocento-Bold", size: 24))
                Text("Search through all scene titles and content.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                TextField("Type at least 2 characters…", text: $query)
                    .textFieldStyle(.roundedBorder)
                    .focused($fieldFocused)
                    .padding(.top, 8)
            }
            .padding(.horizontal, 32)
            .padding(.top, 28)
            .padding(.bottom, 12)

            Divider()

            if query.trimmingCharacters(in: .whitespaces).count < SearchService.minQueryLength {
                emptyPane("Search your scenes", "Matches in titles rank higher than matches in prose.")
            } else if results.isEmpty {
                emptyPane("No scenes match \u{201C}\(query)\u{201D}", "Try a different search term.")
            } else {
                List(results, id: \.id) { result in
                    resultRow(result)
                        .listRowSeparator(.hidden)
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .safeAreaInset(edge: .top, spacing: 0) {
                    Text("\(results.count) scene\(results.count == 1 ? "" : "s") found")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 6)
                }
            }
        }
        .background(VisualEffectView().ignoresSafeArea())
        .navigationTitle("Search")
        .navigationSubtitle(session.project.title)
        .onAppear { fieldFocused = true }
        .onChange(of: query) { runSearch() }
    }

    private func emptyPane(_ title: String, _ subtitle: String) -> some View {
        VStack(spacing: 4) {
            Spacer()
            Image(systemName: "magnifyingglass")
                .font(.title)
                .foregroundStyle(.tertiary)
            Text(title)
                .font(.callout.weight(.medium))
            Text(subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private func resultRow(_ result: SceneSearchResult) -> some View {
        Button {
            session.selectedItem = .scene(result.id)
        } label: {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Image(systemName: "doc.text")
                        .foregroundStyle(.secondary)
                    Text(result.title)
                        .font(.body.weight(.medium))
                    Spacer()
                    Text("\(result.chapterTitle) • \(result.wordCount) words")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                ForEach(Array(result.snippets.enumerated()), id: \.offset) { _, snippet in
                    snippetText(snippet)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .padding(8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(.quaternary.opacity(0.4), in: RoundedRectangle(cornerRadius: 6))
                }
            }
            .padding(10)
            .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(.separator))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 24)
    }

    private func snippetText(_ snippet: SearchSnippet) -> Text {
        snippet.segments.reduce(Text("")) { accumulated, segment in
            let piece = segment.highlighted
                ? Text(segment.text).bold().foregroundStyle(Color.accentColor)
                : Text(segment.text)
            return accumulated + piece
        }
    }

    private func runSearch() {
        searchTask?.cancel()
        let currentQuery = query
        let entries = session.project.chapters.flatMap { chapter in
            chapter.scenes.map { scene in
                SceneSearchEntry(
                    id: scene.id,
                    title: scene.title,
                    content: scene.content.strippingTransientAttributes().string,
                    chapterTitle: chapter.title,
                    wordCount: scene.wordCount
                )
            }
        }
        searchTask = Task {
            try? await Task.sleep(for: .milliseconds(150))
            guard !Task.isCancelled else { return }
            let found = await Task.detached(priority: .userInitiated) {
                SearchService.search(query: currentQuery, in: entries)
            }.value
            guard !Task.isCancelled else { return }
            results = found
        }
    }
}
