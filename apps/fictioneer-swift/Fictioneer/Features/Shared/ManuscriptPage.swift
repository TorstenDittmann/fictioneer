import SwiftUI

struct ManuscriptPageHeader {
    var project: String
    var section: String?
    var title: String
}

/// The manuscript sheet: a crisp-edged page floating on the glass desk, with
/// a letterspaced running head pinned to its top like a real typescript.
struct ManuscriptPage<Content: View>: View {
    let header: ManuscriptPageHeader
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(spacing: 0) {
            runningHead
            Divider()
            content()
        }
        .clipShape(RoundedRectangle(cornerRadius: 3))
        .overlay(
            RoundedRectangle(cornerRadius: 3)
                .strokeBorder(.separator)
        )
        .shadow(color: .black.opacity(0.10), radius: 2, y: 1)
        .shadow(color: .black.opacity(0.22), radius: 18, y: 6)
        .frame(maxWidth: 960)
        .padding(.horizontal, 24)
        .padding(.top, 16)
        .padding(.bottom, 20)
    }

    private var runningHead: some View {
        HStack(spacing: 10) {
            Spacer(minLength: 0)
            ManuscriptLabel(header.project, size: 10, color: .init(.tertiaryLabelColor))
            if let section = header.section, !section.isEmpty {
                headSeparator
                ManuscriptLabel(section, size: 10, color: .init(.tertiaryLabelColor))
            }
            headSeparator
            ManuscriptLabel(header.title, size: 10, color: .secondary)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 9)
        .background(Color(nsColor: EditorTheme.paperBackground))
    }

    private var headSeparator: some View {
        Text("·")
            .font(.custom("Quattrocento-Bold", size: 10))
            .foregroundStyle(.tertiary)
    }
}
