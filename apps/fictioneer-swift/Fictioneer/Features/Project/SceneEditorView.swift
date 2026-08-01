import SwiftUI

struct SceneEditorView: View {
    let session: ProjectSession
    let scene: Scene

    var body: some View {
        VStack(spacing: 8) {
            Text(scene.title)
                .font(.title2.weight(.semibold))
            Text("The rich text editor arrives in the next milestone.")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
