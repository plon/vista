import SwiftUI

struct OutputSettingsView: View {
    // Preferences
    @AppStorage("outputFormat") private var outputFormat = "json"
    @AppStorage("keepLineBreaks") private var keepLineBreaks = true
    @AppStorage("prettyFormatting") private var prettyFormatting = true
    @AppStorage("language") private var language = "en"
    @AppStorage("customInstructions") private var customInstructions = ""
    @AppStorage("systemPrompt") private var systemPrompt = ""
    @AppStorage("isCustomMode") private var isCustomMode = false

    @State private var generatedPrompt: String = ""

    // Language options
    private let languages = [
        ("auto", "Auto"),
        ("en", "English"),
        ("es", "Spanish"),
        ("fr", "French"),
        ("de", "German"),
        ("zh", "Chinese"),
        ("ja", "Japanese"),
    ]

    var body: some View {
        Form {
            Section {
                Picker("Output Format", selection: $outputFormat) {
                    Text("JSON").tag("json")
                    Text("HTML").tag("html")
                    Text("LaTeX").tag("latex")
                    Text("Plain Text").tag("plain")
                }
                .pickerStyle(.menu)
                .disabled(isCustomMode)
                .onChange(of: outputFormat) { _ in updateSystemPrompt() }

                Toggle("Keep Line Breaks", isOn: $keepLineBreaks)
                    .disabled(isCustomMode)
                    .onChange(of: keepLineBreaks) { _ in updateSystemPrompt() }

                Toggle("Use Pretty Formatting", isOn: $prettyFormatting)
                    .disabled(isCustomMode)
                    .onChange(of: prettyFormatting) { _ in updateSystemPrompt() }

                Picker("Language", selection: $language) {
                    ForEach(languages, id: \.0) { code, name in
                        Text(name).tag(code)
                    }
                }
                .pickerStyle(.menu)
                .disabled(isCustomMode)
                .onChange(of: language) { _ in updateSystemPrompt() }

                TextField("Custom Instructions", text: $customInstructions)
                    .disabled(isCustomMode)
                    .onChange(of: customInstructions) { _ in updateSystemPrompt() }

            } header: {
                Text("Output Options")
                    .foregroundStyle(.secondary)
                    .accessibilityAddTraits(.isHeader)
            }

            Section {
                HStack {
                    Text("System Prompt")
                        .foregroundStyle(.secondary)

                    Spacer()

                    if isCustomMode {
                        Button(action: resetToGenerated) {
                            Label("Reset", systemImage: "arrow.counterclockwise")
                        }
                        .buttonStyle(.borderless)
                    }
                }

                TextEditor(text: $systemPrompt)
                    .font(.system(.body, design: .monospaced))
                    .frame(minHeight: 240)
                    .onChange(of: systemPrompt) { newValue in
                        if !isCustomMode && systemPrompt != generatedPrompt {
                            isCustomMode = true
                        }
                    }
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(isCustomMode ? Color.orange : Color.clear, lineWidth: 2)
                    )

                if isCustomMode {
                    Text("Custom mode: Changes to settings won't affect the prompt.")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            } header: {
                Text("Advanced")
                    .foregroundStyle(.secondary)
                    .accessibilityAddTraits(.isHeader)
            }
        }
        .formStyle(.grouped)
        .padding(.top, -20)
        .padding(.horizontal, -10)
        .background(.clear)
        .onAppear {
            // Generate the initial prompt if needed
            if systemPrompt.isEmpty || (!isCustomMode && generatedPrompt.isEmpty) {
                updateSystemPrompt()
            }
        }
    }

    private func generatePrompt() -> String {
        """
        You are an advanced OCR system with the following preferences:
        - Output format: \(outputFormat)\(outputFormat == "json" ? " (use valid JSON syntax)" : "")
        - Keep line breaks: \(keepLineBreaks ? "Yes" : "No")
        - Use pretty formatting: \(prettyFormatting ? "Yes" : "No")
        - Language: \(language)
        \(outputFormat == "html" ? "- Use semantic HTML tags when appropriate" : "")
        \(outputFormat == "latex" ? "- Use LaTeX syntax for mathematical expressions" : "")
        \(customInstructions.isEmpty ? "" : "- Additional instructions: \(customInstructions)")

        Please process the given image and return the extracted text according to these preferences.
        """
    }

    private func updateSystemPrompt() {
        if !isCustomMode {
            generatedPrompt = generatePrompt()
            systemPrompt = generatedPrompt
        }
    }

    private func resetToGenerated() {
        isCustomMode = false
        generatedPrompt = generatePrompt()
        systemPrompt = generatedPrompt
    }
}
