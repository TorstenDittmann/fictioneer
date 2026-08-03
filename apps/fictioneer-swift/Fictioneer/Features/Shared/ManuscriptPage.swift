import SwiftUI

struct ManuscriptPageHeader {
    var project: String
    var section: String?
    var title: String
}

/// The manuscript sheet: a crisp-edged, clearly elevated page floating on the
/// glass desk. The running head doubles as the page's toolbar — controls live
/// in its trailing edge as quiet icons, not in a floating box over the prose.
struct ManuscriptPage<Content: View, Accessory: View>: View {
    let header: ManuscriptPageHeader
    @ViewBuilder let accessory: () -> Accessory
    @ViewBuilder let content: () -> Content

    init(
        header: ManuscriptPageHeader,
        @ViewBuilder accessory: @escaping () -> Accessory = { EmptyView() },
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.header = header
        self.accessory = accessory
        self.content = content
    }

    var body: some View {
        VStack(spacing: 0) {
            runningHead
            Divider()
            content()
        }
        .clipShape(RoundedRectangle(cornerRadius: 4))
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .strokeBorder(.separator)
        )
        .shadow(color: .black.opacity(0.12), radius: 3, y: 1)
        .shadow(color: .black.opacity(0.32), radius: 26, y: 10)
        .frame(maxWidth: 960)
        .padding(.horizontal, 28)
        .padding(.top, 18)
        .padding(.bottom, 24)
    }

    private var runningHead: some View {
        ZStack {
            HStack(spacing: 10) {
                Spacer(minLength: 0)
                ManuscriptLabel(header.project, size: 10, color: Color(nsColor: .tertiaryLabelColor))
                if let section = header.section, !section.isEmpty {
                    headSeparator
                    ManuscriptLabel(section, size: 10, color: .accentColor)
                }
                headSeparator
                ManuscriptLabel(header.title, size: 10, color: .secondary)
                Spacer(minLength: 0)
            }
            HStack {
                Spacer()
                accessory()
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(Color(nsColor: EditorTheme.paperBackground))
    }

    private var headSeparator: some View {
        Text("·")
            .font(.custom("Quattrocento-Bold", size: 10))
            .foregroundStyle(.tertiary)
    }
}
