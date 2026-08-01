import SwiftUI

struct ProjectWindowView: View {
    let session: ProjectSession

    var body: some View {
        NavigationSplitView {
            SidebarView(session: session)
                .navigationSplitViewColumnWidth(min: 230, ideal: 280, max: 360)
        } detail: {
            detailView
        }
        .frame(minWidth: 900, minHeight: 560)
    }

    @ViewBuilder
    private var detailView: some View {
        let project = session.project
        if let noteID = session.selectedNoteID, let note = project.note(withID: noteID) {
            NoteEditorView(session: session, note: note)
                .id(note.id)
        } else if let sceneID = session.selectedSceneID, let scene = project.scene(withID: sceneID) {
            SceneEditorView(session: session, scene: scene)
                .id(scene.id)
        } else {
            ProjectOverviewView(session: session)
        }
    }
}
