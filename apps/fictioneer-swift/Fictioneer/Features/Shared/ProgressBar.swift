import SwiftUI

/// Pure-SwiftUI progress bar. Deliberately NOT `ProgressView`: on macOS 26,
/// tinting the AppKit-backed NSProgressIndicator with the asset-catalog
/// accent color recurses infinitely in SwiftUI's color resolver and crashes
/// (stack overflow in AccentColorProvider.resolve).
struct ProgressBar: View {
    var fraction: Double
    var emphasized: Bool = true

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(.quaternary.opacity(0.6))
                Capsule()
                    .fill(fillColor)
                    .frame(width: max(0, min(1, fraction)) * geometry.size.width)
            }
        }
        .frame(height: 5)
    }

    private var fillColor: Color {
        // Static brand indigo — never the dynamic accent provider.
        let indigo = Color(red: 0x63 / 255, green: 0x66 / 255, blue: 0xF1 / 255)
        return emphasized ? indigo : indigo.opacity(0.5)
    }
}
