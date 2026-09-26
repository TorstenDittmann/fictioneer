import SwiftUI

struct SettingsView: View {
    @Environment(AppModel.self) private var appModel

    var body: some View {
        TabView {
            GeneralSettingsTab()
                .tabItem { Label("General", systemImage: "gearshape") }
            EditorSettingsTab()
                .tabItem { Label("Editor", systemImage: "textformat") }
            AISettingsTab()
                .tabItem { Label("AI", systemImage: "sparkles") }
        }
        .frame(width: 480)
    }
}

private struct GeneralSettingsTab: View {
    @Environment(AppModel.self) private var appModel

    var body: some View {
        @Bindable var settings = appModel.settings
        Form {
            Picker("Appearance", selection: $settings.theme) {
                ForEach(AppSettings.Theme.allCases) { theme in
                    Text(theme.label).tag(theme)
                }
            }
            .pickerStyle(.segmented)
        }
        .formStyle(.grouped)
    }
}

private struct EditorSettingsTab: View {
    @Environment(AppModel.self) private var appModel

    var body: some View {
        @Bindable var settings = appModel.settings
        Form {
            Picker("Font", selection: $settings.editorFontFamily) {
                ForEach(FontLoader.editorFamilies, id: \.self) { family in
                    Text(family).tag(family)
                }
            }
            LabeledContent("Size") {
                HStack {
                    Slider(value: $settings.editorFontSize, in: 12...28, step: 1)
                    Text("\(Int(settings.editorFontSize)) pt")
                        .monospacedDigit()
                        .frame(width: 44, alignment: .trailing)
                }
            }
            LabeledContent("Line Height") {
                HStack {
                    Slider(value: $settings.editorLineHeight, in: 1.2...2.4, step: 0.05)
                    Text(settings.editorLineHeight, format: .number.precision(.fractionLength(2)))
                        .monospacedDigit()
                        .frame(width: 44, alignment: .trailing)
                }
            }
            Toggle("Check Spelling", isOn: $settings.spellcheckEnabled)
            Toggle("Dim other paragraphs in focus mode", isOn: $settings.dimsParagraphsInFocusMode)
        }
        .formStyle(.grouped)
    }
}

private struct AISettingsTab: View {
    @Environment(AppModel.self) private var appModel

    var body: some View {
        @Bindable var settings = appModel.settings
        Form {
            Section {
                TextField("Server URL", text: $settings.intelligenceURLString)
                    .textFieldStyle(.roundedBorder)
                    .autocorrectionDisabled()
                Text("The Fictioneer intelligence service endpoint. Leave as-is unless you self-host.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Section {
                SecureField("License Key", text: $settings.licenseKey)
                    .textFieldStyle(.roundedBorder)
                HStack {
                    Button("Verify") {
                        appModel.license.verify(
                            key: settings.licenseKey,
                            baseURL: settings.intelligenceBaseURL
                        )
                    }
                    .disabled(settings.licenseKey.trimmingCharacters(in: .whitespaces).isEmpty)
                    statusLabel
                    Spacer()
                }
                Text("AI suggestions stay disabled until a key verifies. Hold ⌥ in the editor to stream a continuation; press Tab to accept it.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Section {
                HStack {
                    Button("Get a license…") {
                        NSWorkspace.shared.open(AppConfig.checkoutURL)
                    }
                    Button("Manage account…") {
                        NSWorkspace.shared.open(AppConfig.accountURL)
                    }
                    Spacer()
                }
            }
        }
        .formStyle(.grouped)
    }

    @ViewBuilder
    private var statusLabel: some View {
        switch appModel.license.status {
        case .unknown:
            EmptyView()
        case .verifying:
            ProgressView()
                .controlSize(.small)
        case .valid:
            Label("Valid", systemImage: "checkmark.circle.fill")
                .foregroundStyle(.green)
        case .invalid:
            Label("Invalid key", systemImage: "xmark.circle.fill")
                .foregroundStyle(.red)
        case .error(let message):
            Label(message, systemImage: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
                .lineLimit(2)
        }
    }
}
