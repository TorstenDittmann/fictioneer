import SwiftUI

/// AI Prompt: quick templates or a custom prompt, streamed preview, insert at
/// the caret. Mirrors the Tauri prompt modal's flow.
struct PromptSheet: View {
    @Environment(AppModel.self) private var appModel
    @Environment(\.dismiss) private var dismiss
    let controller: EditorController

    @State private var customPrompt = ""
    @State private var selectedTemplate: String?
    @State private var generated = ""
    @State private var isGenerating = false
    @State private var generationTask: Task<Void, Never>?
    @FocusState private var promptFocused: Bool

    private struct Template: Identifiable {
        let id: String
        let label: String
        let prompt: String
    }

    private static let templates: [Template] = [
        Template(id: "continue", label: "Continue Writing",
                 prompt: "Continue the story naturally from where it leaves off, keeping the established tone and point of view."),
        Template(id: "expand", label: "Expand Scene",
                 prompt: "Expand the current scene with more sensory detail, atmosphere, and grounding description."),
        Template(id: "dialogue", label: "Add Dialogue",
                 prompt: "Write a dialogue exchange between the characters present in this scene that advances the tension."),
        Template(id: "conflict", label: "Add Conflict",
                 prompt: "Introduce a complication or conflict that raises the stakes of the current scene."),
        Template(id: "description", label: "Enhance Description",
                 prompt: "Write a vivid description of the current setting, focusing on specific, concrete details."),
        Template(id: "character", label: "Develop Character",
                 prompt: "Write a moment that reveals character through action and behavior rather than explanation."),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("AI Prompt")
                .font(.title3.weight(.semibold))

            if generated.isEmpty && !isGenerating {
                idleContent
            } else {
                streamingContent
            }
        }
        .padding(20)
        .frame(width: 500)
        .onDisappear { generationTask?.cancel() }
    }

    private var idleContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 140))], spacing: 8) {
                ForEach(Self.templates) { template in
                    Button {
                        selectedTemplate = template.id
                        customPrompt = template.prompt
                    } label: {
                        Text(template.label)
                            .font(.callout)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 7)
                                    .fill(selectedTemplate == template.id
                                        ? AnyShapeStyle(Color.accentColor.opacity(0.18))
                                        : AnyShapeStyle(.quaternary.opacity(0.4)))
                            )
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Custom Prompt")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
                TextField("Describe what to write…", text: $customPrompt, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(4, reservesSpace: true)
                    .focused($promptFocused)
                Text("⌘↩ to generate")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }

            HStack {
                Spacer()
                Button("Cancel", role: .cancel) { dismiss() }
                Button("Generate Content") { generate() }
                    .buttonStyle(.borderedProminent)
                    .disabled(customPrompt.trimmingCharacters(in: .whitespaces).isEmpty)
                    .keyboardShortcut(.return, modifiers: .command)
            }
        }
        .onAppear { promptFocused = true }
    }

    private var streamingContent: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                if isGenerating {
                    ProgressView().controlSize(.small)
                    Text("Writing…")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                } else {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                    Text("Complete")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if isGenerating {
                    Button("Cancel") { cancelGeneration() }
                        .controlSize(.small)
                }
            }

            ScrollView {
                Text(generated.isEmpty ? "Starting generation…" : generated)
                    .font(.callout)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(10)
                    .textSelection(.enabled)
            }
            .frame(maxHeight: 280)
            .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(.separator))

            if !isGenerating, !generated.isEmpty {
                HStack {
                    Button("Regenerate") { generate() }
                    Spacer()
                    Button("Discard", role: .cancel) {
                        generated = ""
                        dismiss()
                    }
                    Button("Insert") {
                        controller.insertAtCaret(generated)
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
    }

    private func generate() {
        let prompt = customPrompt.trimmingCharacters(in: .whitespaces)
        guard !prompt.isEmpty else { return }
        generationTask?.cancel()
        generated = ""
        isGenerating = true
        let settings = appModel.settings
        let client = IntelligenceClient(
            baseURL: settings.intelligenceBaseURL,
            licenseKey: settings.licenseKey
        )
        generationTask = Task {
            do {
                for try await accumulated in client.start(prompt: prompt) {
                    guard !Task.isCancelled else { return }
                    generated = accumulated
                }
            } catch {
                if !Task.isCancelled, generated.isEmpty {
                    generated = "Generation failed: \(error.localizedDescription)"
                }
            }
            isGenerating = false
        }
    }

    private func cancelGeneration() {
        generationTask?.cancel()
        isGenerating = false
    }
}
