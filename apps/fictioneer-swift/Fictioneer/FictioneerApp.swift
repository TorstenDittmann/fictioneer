import SwiftUI

@main
struct FictioneerApp: App {
    // `SwiftUI.Scene` is spelled out because the writing domain has its own `Scene` model.
    var body: some SwiftUI.Scene {
        WindowGroup {
            Text("Fictioneer")
                .frame(minWidth: 600, minHeight: 400)
        }
    }
}
