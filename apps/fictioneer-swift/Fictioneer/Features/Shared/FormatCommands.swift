import SwiftUI

/// Paragraph styles, shared by the toolbar menu and Format ▸ Paragraph Style.
struct ParagraphStyleButtons: View {
    let controller: EditorController?

    var body: some View {
        Button("Body Text") { controller?.applyBlockStyle(.body) }
        Divider()
        Button("Heading 1") { controller?.applyBlockStyle(.heading(1)) }
        Divider()
        Button("Heading 2") { controller?.applyBlockStyle(.heading(2)) }
        Button("Heading 3") { controller?.applyBlockStyle(.heading(3)) }
        Divider()
        Button("Blockquote") { controller?.applyBlockStyle(.blockquote) }
    }
}

/// The Format menu: character formatting and paragraph styles for the editor
/// in the key window. Living in the menu bar, the shortcuts work in focus
/// mode too, where the toolbar is hidden.
struct FormatCommands: Commands {
    let appModel: AppModel

    private var editor: EditorController? {
        appModel.activeSession?.activeEditor
    }

    var body: some Commands {
        CommandMenu("Format") {
            Group {
                Button("Bold") { editor?.toggleBold() }
                    .keyboardShortcut("b", modifiers: .command)
                Button("Italic") { editor?.toggleItalic() }
                    .keyboardShortcut("i", modifiers: .command)
                Button("Underline") { editor?.toggleUnderline() }
                    .keyboardShortcut("u", modifiers: .command)
                Button("Strikethrough") { editor?.toggleStrikethrough() }
                    .keyboardShortcut("x", modifiers: [.command, .shift])
                Divider()
                Menu("Paragraph Style") {
                    ParagraphStyleButtons(controller: editor)
                }
                Divider()
                Button("Convert Quotes") {
                    guard let project = appModel.activeSession?.project else { return }
                    editor?.convertQuotes(to: project.effectiveQuoteStyle)
                }
            }
            .disabled(editor == nil)
        }
    }
}
