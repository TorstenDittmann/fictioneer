import SwiftUI

struct ProjectWindowView: View {
    let session: ProjectSession

    @State private var columnVisibility: NavigationSplitViewVisibility = .all

    var body: some View {
        @Bindable var session = session
        NavigationSplitView(columnVisibility: $columnVisibility) {
            SidebarView(session: session)
                .navigationSplitViewColumnWidth(min: 230, ideal: 280, max: 360)
        } detail: {
            detailView
        }
        .frame(minWidth: 900, minHeight: 560)
        .toolbar(session.isFocusMode ? .hidden : .automatic, for: .windowToolbar)
        .onChange(of: session.isFocusMode) {
            withAnimation {
                columnVisibility = session.isFocusMode ? .detailOnly : .all
            }
        }
        .sheet(isPresented: $session.isExportSheetRequested) {
            ExportSheet(session: session)
        }
        .overlay {
            if session.isCommandPaletteVisible {
                ZStack(alignment: .top) {
                    Color.black.opacity(0.2)
                        .ignoresSafeArea()
                        .onTapGesture { session.isCommandPaletteVisible = false }
                    CommandPaletteView(session: session)
                        .padding(.top, 80)
                }
            }
        }
    }

    @ViewBuilder
    private var detailView: some View {
        let project = session.project
        if session.showsSearch {
            SearchResultsView(session: session)
        } else if let noteID = session.selectedNoteID, let note = project.note(withID: noteID) {
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
