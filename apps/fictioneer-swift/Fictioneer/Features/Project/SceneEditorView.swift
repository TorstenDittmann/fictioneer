import SwiftUI

struct SceneEditorView: View {
    @Environment(AppModel.self) private var appModel
    let session: ProjectSession
    let scene: Scene

    @State private var controller = EditorController()

    var body: some View {
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
        .background(VisualEffectView().ignoresSafeArea())
        .overlay(alignment: .bottomTrailing) {
            statsCapsule
        }
        .overlay(alignment: .top) {
            floatingToolbar
        }
        .navigationTitle(scene.title)
        .navigationSubtitle(session.project.chapter(containing: scene.id)?.title ?? "")
    }

    /// Floating format bar over the writing surface — layout borrowed from the
    /// Tauri app's editor pill, rendered with native materials.
    private var floatingToolbar: some View {
        HStack(spacing: 2) {
            formatButton("arrow.uturn.backward", "Undo") { controller.undo() }
            formatButton("arrow.uturn.forward", "Redo") { controller.redo() }
            toolbarDivider
            blockStyleMenu
                .menuStyle(.borderlessButton)
                .fixedSize()
            toolbarDivider
            formatButton("bold", "Bold") { controller.toggleBold() }
                .keyboardShortcut("b", modifiers: .command)
            formatButton("italic", "Italic") { controller.toggleItalic() }
                .keyboardShortcut("i", modifiers: .command)
            formatButton("underline", "Underline") { controller.toggleUnderline() }
                .keyboardShortcut("u", modifiers: .command)
            formatButton("strikethrough", "Strikethrough") { controller.toggleStrikethrough() }
                .keyboardShortcut("x", modifiers: [.command, .shift])
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(.separator)
        )
        .shadow(color: .black.opacity(0.12), radius: 8, y: 2)
        .padding(.top, 10)
    }

    private var toolbarDivider: some View {
        Divider()
            .frame(height: 16)
            .padding(.horizontal, 4)
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
            Image(systemName: icon)
                .frame(width: 24, height: 22)
                .contentShape(Rectangle())
        }
        .buttonStyle(.borderless)
        .help(help)
    }

    private var statsCapsule: some View {
        HStack(spacing: 6) {
            if appModel.license.isReadyForSuggestions {
                Image(systemName: "sparkle")
                    .font(.caption2)
                    .foregroundStyle(Color.accentColor)
                    .help("Hold ⌥ for an AI continuation · Tab accepts")
            }
            Text("\(scene.wordCount) words · \(scene.characterCount) chars")
                .font(.caption)
                .monospacedDigit()
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(.regularMaterial, in: .capsule)
        .padding(12)
        .allowsHitTesting(false)
    }
}
