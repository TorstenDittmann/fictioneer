import SwiftUI

/// The quiet canvas: content sits directly on the paper-colored window — no
/// sheet, running head or stats bar competing with the prose. The paper runs
/// under the toolbar so the window reads as one surface. The text column's
/// own centering/inset logic lives in the editor.
struct ManuscriptPage<Content: View>: View {
    @ViewBuilder let content: () -> Content

    var body: some View {
        content()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(nsColor: EditorTheme.paperBackground).ignoresSafeArea())
            .background(VisualEffectView().ignoresSafeArea())
    }
}
