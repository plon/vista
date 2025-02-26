import SwiftUI

// Unified reusable component that works with any input control
struct InputWithHelp<Content: View>: View {
    var label: String
    var helpText: String
    @ViewBuilder var content: () -> Content
    @State private var showingPopover = false

    var body: some View {
        HStack {
            Text(label)

            // Info button with hover popover
            Image(systemName: "info.circle")
                .foregroundColor(.secondary)
                .padding(.trailing, 2)
                .onHover { hovering in
                    showingPopover = hovering
                }
                .popover(isPresented: $showingPopover, arrowEdge: .top) {
                    Text(helpText)
                        .font(.callout)
                        .padding(10)
                        .presentationCompactAdaptation(.popover)
                }

            Spacer()
            content()
        }
    }
}

struct OutputSettingsView: View {
    // Format settings
    @AppStorage("formatType") private var formatType = "plain_text"

    // Text Formatting
    @AppStorage("prettyFormatting") private var prettyFormatting = false
    @AppStorage("originalFormatting") private var originalFormatting = true
    @AppStorage("languageDetection") private var languageDetection = false
    @AppStorage("latexMath") private var latexMath = true
    @AppStorage("targetLanguage") private var targetLanguage = ""

    // Intelligence options
    @AppStorage("errorCorrection") private var errorCorrection = false
    @AppStorage("lowConfidenceHighlighting") private var lowConfidenceHighlighting = false
    @AppStorage("contextualGrouping") private var contextualGrouping = false
    @AppStorage("accessibilityAltText") private var accessibilityAltText = false
    @AppStorage("smartContext") private var smartContext = false

    // Custom mode
    @AppStorage("isCustomMode") private var isCustomMode = false
    @AppStorage("systemPrompt") private var systemPrompt = ""
    @State private var generatedPrompt: String = ""

    var body: some View {
        VSplitView {
            // Top section - Settings form
            ScrollView {
                Form {
                    // 1. Output Format
                    Section {
                        InputWithHelp(
                            label: "Output Format",
                            helpText: "Choose the format for the processed text output"
                        ) {
                            Picker("", selection: $formatType) {
                                Text("Plain Text").tag("plain_text")
                                Text("Markdown").tag("markdown")
                                Text("HTML").tag("html")
                                Text("JSON").tag("json")
                                Text("LaTeX").tag("latex")
                                Text("RTF").tag("rtf")
                                Text("XML").tag("xml")
                            }
                            .labelsHidden()
                            .pickerStyle(.menu)
                            .disabled(isCustomMode)
                            .onChange(of: formatType) { _ in updateSystemPrompt() }
                        }
                    } header: {
                        Text("Output Format")
                            .foregroundStyle(.secondary)
                    }

                    // 2. Text Formatting
                    Section {
                        VStack(spacing: 8) {
                            InputWithHelp(
                                label: "Use pretty formatting",
                                helpText: "Improves readability by adjusting paragraphs and layout"
                            ) {
                                Toggle("", isOn: $prettyFormatting)
                                    .disabled(isCustomMode || originalFormatting)
                                    .onChange(of: prettyFormatting) { newValue in
                                        if newValue && originalFormatting {
                                            originalFormatting = false
                                        }
                                        updateSystemPrompt()
                                    }
                            }

                            Divider()

                            InputWithHelp(
                                label: "Preserve original formatting",
                                helpText: "Maintains exact layout, indentation, and line breaks"
                            ) {
                                Toggle("", isOn: $originalFormatting)
                                    .disabled(isCustomMode || prettyFormatting)
                                    .onChange(of: originalFormatting) { newValue in
                                        if newValue && prettyFormatting {
                                            prettyFormatting = false
                                        }
                                        updateSystemPrompt()
                                    }
                            }

                            Divider()

                            InputWithHelp(
                                label: "Convert math equations to LaTeX",
                                helpText: "Represents mathematical formulas using LaTeX formatting"
                            ) {
                                Toggle("", isOn: $latexMath)
                                    .disabled(isCustomMode)
                                    .onChange(of: latexMath) { _ in updateSystemPrompt() }
                            }

                            Divider()

                            InputWithHelp(
                                label: "Detect language",
                                helpText: "Identifies the language of the text"
                            ) {
                                Toggle("", isOn: $languageDetection)
                                    .disabled(isCustomMode)
                                    .onChange(of: languageDetection) { _ in updateSystemPrompt() }
                            }

                            if languageDetection {
                                Divider()

                                InputWithHelp(
                                    label: "Target language:",
                                    helpText:
                                        "Specify a language code (e.g., 'en', 'es', 'fr') for translation"
                                ) {
                                    TextField("Leave blank to keep original", text: $targetLanguage)
                                        .textFieldStyle(.roundedBorder)
                                        .disabled(isCustomMode)
                                        .onChange(of: targetLanguage) { _ in updateSystemPrompt() }
                                }
                            }
                        }
                    } header: {
                        Text("Text Formatting")
                            .foregroundStyle(.secondary)
                    }

                    // 3. Intelligence
                    Section {
                        VStack(alignment: .leading, spacing: 8) {
                            InputWithHelp(
                                label: "Error correction",
                                helpText: "Corrects recognition mistakes and improves grammar"
                            ) {
                                Toggle("", isOn: $errorCorrection)
                                    .disabled(isCustomMode)
                                    .onChange(of: errorCorrection) { _ in updateSystemPrompt() }
                            }

                            Divider()

                            InputWithHelp(
                                label: "Group related content",
                                helpText:
                                    "Intelligently groups related content into cohesive blocks"
                            ) {
                                Toggle("", isOn: $contextualGrouping)
                                    .disabled(isCustomMode)
                                    .onChange(of: contextualGrouping) { _ in updateSystemPrompt() }
                            }

                            Divider()

                            InputWithHelp(
                                label: "Extract spatial context",
                                helpText: "Includes annotations and describes spatial relationships"
                            ) {
                                Toggle("", isOn: $smartContext)
                                    .disabled(isCustomMode)
                                    .onChange(of: $smartContext.wrappedValue) { _ in
                                        updateSystemPrompt()
                                    }
                            }

                            Divider()

                            InputWithHelp(
                                label: "Generate alt text for images",
                                helpText: "Creates descriptive text for images or graphics"
                            ) {
                                Toggle("", isOn: $accessibilityAltText)
                                    .disabled(isCustomMode)
                                    .onChange(of: accessibilityAltText) { _ in updateSystemPrompt()
                                    }
                            }

                            Divider()

                            InputWithHelp(
                                label: "Highlight uncertain text",
                                helpText: "Marks low-confidence sections with [?]"
                            ) {
                                Toggle("", isOn: $lowConfidenceHighlighting)
                                    .disabled(isCustomMode)
                                    .onChange(of: lowConfidenceHighlighting) { _ in
                                        updateSystemPrompt()
                                    }
                            }
                        }
                    } header: {
                        Text("Intelligence")
                            .foregroundStyle(.secondary)
                    }
                }
                .formStyle(.grouped)
                .padding(.top, -20)
                .padding(.horizontal, -10)
            }
            .frame(minHeight: 120, idealHeight: 300, maxHeight: .infinity)

            // Bottom section - System Prompt
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
            if systemPrompt.isEmpty {
                // First time use - initialize with default prompt
                updateSystemPrompt()
            } else if !isCustomMode {
                // Regenerate the prompt to match current settings
                updateSystemPrompt()
            } else {
                // Custom mode - keep the existing prompt
            }
        }
    }

    private func updateSystemPrompt() {
        if !isCustomMode {
            generatedPrompt = generateOCRSystemPrompt(
                formatType: formatType,
                prettyFormatting: prettyFormatting,
                originalFormatting: originalFormatting,
                languageDetection: languageDetection,
                latexMath: latexMath,
                targetLanguage: targetLanguage.isEmpty ? nil : targetLanguage,
                errorCorrection: errorCorrection,
                lowConfidenceHighlighting: lowConfidenceHighlighting,
                contextualGrouping: contextualGrouping,
                accessibilityAltText: accessibilityAltText,
                smartContext: smartContext
            )
            systemPrompt = generatedPrompt
        }
    }

    private func resetToGenerated() {
        isCustomMode = false
        updateSystemPrompt()
    }
}
