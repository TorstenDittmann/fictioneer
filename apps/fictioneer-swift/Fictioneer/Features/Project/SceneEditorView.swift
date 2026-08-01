import SwiftUI

struct SceneEditorView: View {
    @Environment(AppModel.self) private var appModel
    let session: ProjectSession
    let scene: Scene

    @State private var controller = EditorController()

    var body: some View {
        VStack(spacing: 0) {
            RichTextEditor(
                initialContent: scene.content,
                settings: appModel.settings,
                controller: controller,
                configureGhost: { textView, editorController in
                    let settings = appModel.settings
                    let license = appModel.license
                    let ghostController = GhostTextController { content, context in
                        IntelligenceClient(
                            baseURL: settings.intelligenceBaseURL,
                            licenseKey: settings.licenseKey
                        )
                        .continueWriting(content: content, context: context)
                    }
                    editorController.ghostPresenter = GhostTextPresenter(
                        textView: textView,
                        editorController: editorController,
                        controller: ghostController,
                        isEnabled: { license.isReadyForSuggestions },
                        contextInfo: { [weak scene, weak session] in
                            (scene?.title, session?.project.details.isEmpty == false ? session?.project.details : nil)
                        }
                    )
                }
            ) { content in
                scene.updateContent(content)
                session.markDirty(sceneID: scene.id)
            }
            Divider()
            footer
        }
        .navigationTitle(scene.title)
        .navigationSubtitle(session.project.chapter(containing: scene.id)?.title ?? "")
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                blockStyleMenu
                ControlGroup {
                    formatButton("bold", "Bold") { controller.toggleBold() }
                        .keyboardShortcut("b", modifiers: .command)
                    formatButton("italic", "Italic") { controller.toggleItalic() }
                        .keyboardShortcut("i", modifiers: .command)
                    formatButton("underline", "Underline") { controller.toggleUnderline() }
                        .keyboardShortcut("u", modifiers: .command)
                    formatButton("strikethrough", "Strikethrough") { controller.toggleStrikethrough() }
                        .keyboardShortcut("x", modifiers: [.command, .shift])
                }
            }
        }
    }

    private var blockStyleMenu: some View {
        Menu {
            Button("Body Text") { controller.applyBlockStyle(.body) }
            Divider()
            Button("Heading 1") { controller.applyBlockStyle(.heading(1)) }
            Button("Heading 2") { controller.applyBlockStyle(.heading(2)) }
            Button("Heading 3") { controller.applyBlockStyle(.heading(3)) }
            Divider()
            Button("Blockquote") { controller.applyBlockStyle(.blockquote) }
        } label: {
            Label("Paragraph Style", systemImage: "paragraphsign")
        }
    }

    private func formatButton(_ icon: String, _ help: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(help, systemImage: icon)
        }
        .help(help)
    }

    private var footer: some View {
        HStack {
            if appModel.settings.licenseKey.isEmpty {
                Text("Add a license key in Settings to enable AI suggestions")
                    .foregroundStyle(.tertiary)
            } else {
                Text("Hold ⌥ for an AI continuation")
                    .foregroundStyle(.tertiary)
            }
            Spacer()
            Text("\(scene.wordCount) words · \(scene.characterCount) characters")
                .monospacedDigit()
                .foregroundStyle(.secondary)
        }
        .font(.caption)
        .padding(.horizontal, 16)
        .padding(.vertical, 7)
        .background(.bar)
    }
}
