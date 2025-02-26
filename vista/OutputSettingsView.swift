import SwiftUI

struct InputWithHelp<Content: View>: View {
    var label: String
    var helpText: String
    @ViewBuilder var content: () -> Content
    @State private var showingPopover = false

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(label)

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
    @AppStorage("outputLanguage") private var outputLanguage = ""
    @AppStorage("latexMath") private var latexMath = true

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

    // Add this property to track if we're showing the reset confirmation alert
    @State private var showingResetConfirmation = false

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
                                    .disabled(isCustomMode)
                                    .onChange(of: prettyFormatting) { newValue in
                                        if newValue {
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
                                    .disabled(isCustomMode)
                                    .onChange(of: originalFormatting) { newValue in
                                        if newValue {
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
                                label: "Output language:",
                                helpText:
                                    "Leave blank to keep original language, or enter a language code (e.g., 'en', 'es', 'fr') to translate"
                            ) {
                                TextField("", text: $outputLanguage)
                                    .textFieldStyle(.roundedBorder)
                                    .disabled(isCustomMode)
                                    .onChange(of: outputLanguage) { _ in updateSystemPrompt() }
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

                    Section {
                        EmptyView()
                    }
                    Section {
                        EmptyView()
                    }

                    // 4. Reset to Defaults section
                    Section {
                        Button(action: { showingResetConfirmation = true }) {
                            HStack {
                                Spacer()
                                Image(systemName: "arrow.triangle.2.circlepath")
                                    .foregroundStyle(Color.blue)
                                Text("Reset to Defaults")
                                    .foregroundStyle(Color.blue)
                                Spacer()
                            }
                            .padding(.vertical, 8)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .alert("Reset Settings", isPresented: $showingResetConfirmation) {
                            Button("Cancel", role: .cancel) {}
                            Button("Reset", role: .destructive) { resetToDefaults() }
                        } message: {
                            Text("Are you sure you want to reset all output settings to defaults?")
                        }
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
                outputLanguage: outputLanguage,
                latexMath: latexMath,
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

    private func resetToDefaults() {
        // Reset format
        formatType = "plain_text"

        // Reset text formatting
        prettyFormatting = false
        originalFormatting = true
        outputLanguage = ""
        latexMath = true

        // Reset intelligence options
        errorCorrection = false
        lowConfidenceHighlighting = false
        contextualGrouping = false
        accessibilityAltText = false
        smartContext = false

        // Reset custom mode
        isCustomMode = false

        // Regenerate the system prompt based on default settings
        updateSystemPrompt()
    }
}
