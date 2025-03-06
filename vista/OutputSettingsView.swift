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

struct SettingsToggle: View {
    let label: String
    let helpText: String
    @Binding var isOn: Bool
    var isDisabled: Bool
    var onChange: ((Bool) -> Void)?

    var body: some View {
        InputWithHelp(label: label, helpText: helpText) {
            Toggle("", isOn: $isOn)
                .disabled(isDisabled)
                .onChange(of: isOn) { newValue in
                    onChange?(newValue)
                }
        }
    }
}

struct SettingsSection<Content: View>: View {
    let title: String
    let isDisabled: Bool
    @ViewBuilder let content: () -> Content

    var body: some View {
        Section {
            content()
        } header: {
            Text(title)
                .foregroundStyle(.secondary)
        }
        .opacity(isDisabled ? 0.5 : 1.0)
    }
}

struct OutputSettingsView: View {
    // Format settings
    @AppStorage("formatType") private var formatType = "plain_text"
    @AppStorage("selectedModelType") private var selectedModelType = OCRModelType.default

    // Text Formatting
    @AppStorage("prettyFormatting") private var prettyFormatting = false
    @AppStorage("originalFormatting") private var originalFormatting = true
    @AppStorage("outputLanguage") private var outputLanguage = ""
    @AppStorage("latexMath") private var latexMath = true

    // Intelligence options
    @AppStorage("spellCheck") private var spellCheck = false
    @AppStorage("lowConfidenceHighlighting") private var lowConfidenceHighlighting = false
    @AppStorage("contextualGrouping") private var contextualGrouping = false
    @AppStorage("accessibilityAltText") private var accessibilityAltText = false
    @AppStorage("smartContext") private var smartContext = false

    // Custom mode
    @AppStorage("isCustomMode") private var isCustomMode = false
    @AppStorage("systemPrompt") private var systemPrompt = ""
    @State private var generatedPrompt: String = ""

    @State private var showingResetConfirmation = false
    @State private var previousModelType: OCRModelType = OCRModelType.default

    private var isSettingsDisabled: Bool {
        isCustomMode || selectedModelType == .visionKit
    }

    var body: some View {
        VSplitView {
            ScrollView {
                Form {
                    SettingsSection(title: "OCR Provider", isDisabled: false) {
                        InputWithHelp(
                            label: "OCR Provider",
                            helpText:
                                "Choose between Gemini (more intelligent, requires internet) or VisionKit (native macOS, works offline)"
                        ) {
                            Picker("", selection: $selectedModelType) {
                                Group {
                                    Text("Gemini Flash").tag(OCRModelType.geminiFlash)
                                    Text("Gemini Flash Lite").tag(OCRModelType.geminiFlashLite)
                                    Text("Gemini Pro").tag(OCRModelType.geminiPro)
                                }
                                Divider()
                                Text("VisionKit (Local)").tag(OCRModelType.visionKit)
                            }
                            .labelsHidden()
                            .pickerStyle(.menu)
                            .onChange(of: selectedModelType) { newValue in
                                let wasVisionKit = previousModelType == .visionKit
                                let isNowVisionKit = newValue == .visionKit

                                if !wasVisionKit && !isNowVisionKit {
                                    // Update system prompt when switching between Gemini models
                                    updateSystemPrompt()
                                }

                                previousModelType = newValue
                            }
                        }
                    }

                    SettingsSection(title: "Output Format", isDisabled: isSettingsDisabled) {
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
                            .disabled(isSettingsDisabled)
                            .onChange(of: formatType) { _ in updateSystemPrompt() }
                        }
                    }

                    SettingsSection(title: "Text Formatting", isDisabled: isSettingsDisabled) {
                        VStack(spacing: 8) {
                            SettingsToggle(
                                label: "Use pretty formatting",
                                helpText: "Improves readability by adjusting paragraphs and layout",
                                isOn: $prettyFormatting,
                                isDisabled: isSettingsDisabled
                            ) { newValue in
                                if newValue {
                                    originalFormatting = false
                                }
                                updateSystemPrompt()
                            }

                            Divider()

                            SettingsToggle(
                                label: "Preserve original formatting",
                                helpText: "Maintains exact layout, indentation, and line breaks",
                                isOn: $originalFormatting,
                                isDisabled: isSettingsDisabled
                            ) { newValue in
                                if newValue {
                                    prettyFormatting = false
                                }
                                updateSystemPrompt()
                            }

                            Divider()

                            SettingsToggle(
                                label: "Convert math equations to LaTeX",
                                helpText: "Represents mathematical formulas using LaTeX formatting",
                                isOn: $latexMath,
                                isDisabled: isSettingsDisabled
                            ) { _ in updateSystemPrompt() }

                            Divider()

                            InputWithHelp(
                                label: "Output language:",
                                helpText:
                                    "Leave blank to keep original language, or enter a language to translate to"
                            ) {
                                TextField("", text: $outputLanguage)
                                    .textFieldStyle(.roundedBorder)
                                    .disabled(isSettingsDisabled)
                                    .onChange(of: outputLanguage) { _ in updateSystemPrompt() }
                            }
                        }
                    }

                    SettingsSection(title: "Intelligence", isDisabled: isSettingsDisabled) {
                        VStack(alignment: .leading, spacing: 8) {
                            SettingsToggle(
                                label: "Spell check",
                                helpText: "Automatically applies spell correction to the text",
                                isOn: $spellCheck,
                                isDisabled: isSettingsDisabled
                            ) { _ in updateSystemPrompt() }

                            Divider()

                            SettingsToggle(
                                label: "Group related content",
                                helpText:
                                    "Intelligently groups related content into cohesive blocks",
                                isOn: $contextualGrouping,
                                isDisabled: isSettingsDisabled
                            ) { _ in updateSystemPrompt() }

                            Divider()

                            SettingsToggle(
                                label: "Extract spatial context",
                                helpText:
                                    "Includes annotations and describes spatial relationships",
                                isOn: $smartContext,
                                isDisabled: isSettingsDisabled
                            ) { _ in updateSystemPrompt() }

                            Divider()

                            SettingsToggle(
                                label: "Generate alt text for images",
                                helpText: "Creates descriptive text for images or graphics",
                                isOn: $accessibilityAltText,
                                isDisabled: isSettingsDisabled
                            ) { _ in updateSystemPrompt() }

                            Divider()

                            SettingsToggle(
                                label: "Highlight uncertain text",
                                helpText: "Marks low-confidence sections with [?]",
                                isOn: $lowConfidenceHighlighting,
                                isDisabled: isSettingsDisabled
                            ) { _ in updateSystemPrompt() }
                        }
                    }

                    Section {
                        EmptyView()
                    }
                    Section {
                        EmptyView()
                    }

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

            // Bottom section (System Prompt)
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("System Prompt")
                        .font(.headline)

                    Spacer()

                    if isCustomMode && selectedModelType != .visionKit {
                        Button(action: resetToGenerated) {
                            Label("Reset to Generated", systemImage: "arrow.counterclockwise")
                                .font(.subheadline)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                        .tint(.orange)
                    }
                }

                if selectedModelType == .visionKit {
                    HStack(spacing: 12) {
                        Image(systemName: "info.circle")
                            .foregroundStyle(.secondary)
                        Text(
                            "System prompt is not used when VisionKit is selected. VisionKit performs local OCR without additional processing."
                        )
                        .foregroundStyle(.secondary)
                        .font(.callout)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.textBackgroundColor))
                    .cornerRadius(6)
                } else {
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
            }
            .padding()
            .frame(minHeight: 120, idealHeight: 200, maxHeight: .infinity)
        }
        .onAppear {
            if systemPrompt.isEmpty {
                updateSystemPrompt()
            } else if !isCustomMode {
                updateSystemPrompt()
            }
        }
    }

    private func updateSystemPrompt() {
        if !isCustomMode && selectedModelType != .visionKit {
            generatedPrompt = generateOCRSystemPrompt(
                formatType: formatType,
                prettyFormatting: prettyFormatting,
                originalFormatting: originalFormatting,
                outputLanguage: outputLanguage,
                latexMath: latexMath,
                spellCheck: spellCheck,
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
        formatType = "plain_text"

        // Reset text formatting
        prettyFormatting = false
        originalFormatting = true
        outputLanguage = ""
        latexMath = true

        // Reset intelligence options
        spellCheck = false
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
