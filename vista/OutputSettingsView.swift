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

    var body: some View {
        VSplitView {
            // Top section - An actual Form
            ScrollView {
                Form {
                    Section {
                        // Output Format
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Output Format")
                                .font(.headline)

                            Picker("", selection: $outputFormat) {
                                Text("JSON").tag("json")
                                Text("HTML").tag("html")
                                Text("LaTeX").tag("latex")
                                Text("Plain Text").tag("plain")
                            }
                            .pickerStyle(.segmented)
                            .disabled(isCustomMode)
                            .onChange(of: outputFormat) { _ in updateSystemPrompt() }
                        }

                        // Options
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Options")
                                .font(.headline)

                            Toggle("Keep Line Breaks", isOn: $keepLineBreaks)
                                .disabled(isCustomMode)
                                .onChange(of: keepLineBreaks) { _ in updateSystemPrompt() }

                            Toggle("Use Pretty Formatting", isOn: $prettyFormatting)
                                .disabled(isCustomMode)
                                .onChange(of: prettyFormatting) { _ in updateSystemPrompt() }
                        }

                        // Language
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Language")
                                .font(.headline)

                            TextField("Enter language code (e.g. en, es, fr)", text: $language)
                                .textFieldStyle(.roundedBorder)
                                .disabled(isCustomMode)
                                .onChange(of: language) { _ in updateSystemPrompt() }
                        }

                        // Custom Instructions
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Custom Instructions")
                                .font(.headline)

                            TextField(
                                "Enter any additional instructions", text: $customInstructions
                            )
                            .textFieldStyle(.roundedBorder)
                            .disabled(isCustomMode)
                            .onChange(of: customInstructions) { _ in updateSystemPrompt() }
                        }
                    }
                }
                .formStyle(.grouped)
                .padding(.top, -20)
                .padding(.horizontal, -10)
            }
            .frame(minHeight: 120, idealHeight: 200, maxHeight: .infinity)

            // Bottom section - System Prompt (not a Form)
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("System Prompt")
                        .font(.headline)

                    Spacer()

                    if isCustomMode {
                        Button(action: resetToGenerated) {
                            Label("Reset to Generated", systemImage: "arrow.counterclockwise")
                                .font(.subheadline)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                        .tint(.orange)
                    }
                }

                TextEditor(text: $systemPrompt)
                    .font(.system(.body, design: .monospaced))
                    .padding(4)
                    .background(Color(.textBackgroundColor))
                    .cornerRadius(6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(
                                isCustomMode ? Color.orange : Color.gray.opacity(0.3),
                                lineWidth: isCustomMode ? 2 : 1)
                    )
                    .onChange(of: systemPrompt) { newValue in
                        if !isCustomMode && systemPrompt != generatedPrompt {
                            isCustomMode = true
                        }
                    }

                if isCustomMode {
                    Text(
                        "Using your custom prompt. Use 'Reset to Generated' to re-enable the options above."
                    )
                    .font(.caption)
                    .foregroundColor(.orange)
                }
            }
            .padding()
            .frame(minHeight: 120, idealHeight: 200, maxHeight: .infinity)
        }
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
