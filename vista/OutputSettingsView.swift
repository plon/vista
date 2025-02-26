import SwiftUI

// Reusable ToggleWithHelp View
struct ToggleWithHelp: View {
    var label: String
    var helpText: String
    @Binding var isOn: Bool
    var isDisabled: Bool
    var onChange: (Bool) -> Void

    var body: some View {
        HStack {
            Text(label)
            Button(action: { /* Show help */ }) {
                Image(systemName: "info.circle")
                    .foregroundColor(.blue)
                    .padding(.trailing, 4)
            }
            .buttonStyle(PlainButtonStyle())
            .help(helpText)
            Spacer()
            Toggle("", isOn: $isOn)
                .disabled(isDisabled)
                .onChange(of: isOn, perform: onChange)
        }
    }
}

struct OutputSettingsView: View {
    // Format settings
    @AppStorage("formatType") private var formatType = "plain_text"

    // Layout & Formatting
    @AppStorage("prettyFormatting") private var prettyFormatting = false
    @AppStorage("originalFormatting") private var originalFormatting = true

    // Language settings
    @AppStorage("languageDetection") private var languageDetection = false
    @AppStorage("latexMath") private var latexMath = true
    @AppStorage("targetLanguage") private var targetLanguage = ""

    // Advanced options
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
                    // Output Format
                    Section {
                        HStack {
                            Text("Output Format")
                                .font(.headline)

                            Spacer()

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
                            .frame(width: 130)
                            .disabled(isCustomMode)
                            .onChange(of: formatType) { _ in updateSystemPrompt() }
                        }
                    } header: {
                        Text("Format")
                            .foregroundStyle(.secondary)
                    }

                    // Layout Settings
                    Section {
                        VStack(spacing: 8) {
                            ToggleWithHelp(
                                label: "Use pretty formatting",
                                helpText: "Improves readability by adjusting paragraphs and layout",
                                isOn: $prettyFormatting,
                                isDisabled: isCustomMode || originalFormatting,
                                onChange: { newValue in
                                    if newValue && originalFormatting {
                                        originalFormatting = false
                                    }
                                    updateSystemPrompt()
                                }
                            )

                            ToggleWithHelp(
                                label: "Preserve original formatting",
                                helpText: "Maintains exact layout, indentation, and line breaks",
                                isOn: $originalFormatting,
                                isDisabled: isCustomMode || prettyFormatting,
                                onChange: { newValue in
                                    if newValue && prettyFormatting {
                                        prettyFormatting = false
                                    }
                                    updateSystemPrompt()
                                }
                            )
                        }
                    } header: {
                        Text("Structure")
                            .foregroundStyle(.secondary)
                    }

                    // Language & Math
                    Section {
                        VStack(spacing: 8) {
                            HStack {
                                Text("Convert math equations to LaTeX")
                                    .padding(.trailing, 4)
                                Button(action: { /* Show help for LaTeX conversion */ }) {
                                    Image(systemName: "info.circle")
                                        .foregroundColor(.blue)
                                }
                                .buttonStyle(PlainButtonStyle())
                                .help("Represents mathematical formulas using LaTeX formatting")
                                Spacer()
                                Toggle("", isOn: $latexMath)
                                    .disabled(isCustomMode)
                                    .onChange(of: latexMath) { _ in updateSystemPrompt() }
                            }

                            HStack {
                                Text("Detect language")
                                    .padding(.trailing, 4)
                                Button(action: { /* Show help for language detection */ }) {
                                    Image(systemName: "info.circle")
                                        .foregroundColor(.blue)
                                }
                                .buttonStyle(PlainButtonStyle())
                                .help("Identifies the language of the text")
                                Spacer()
                                Toggle("", isOn: $languageDetection)
                                    .disabled(isCustomMode)
                                    .onChange(of: languageDetection) { _ in updateSystemPrompt() }
                            }

                            if languageDetection {
                                HStack {
                                    Text("Target language:")
                                    TextField("Leave blank to keep original", text: $targetLanguage)
                                        .textFieldStyle(.roundedBorder)
                                        .disabled(isCustomMode)
                                        .onChange(of: targetLanguage) { _ in updateSystemPrompt() }
                                    Button(action: { /* Show help for target language */ }) {
                                        Image(systemName: "info.circle")
                                            .foregroundColor(.blue)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    .help("Specify a language code (e.g., 'en', 'es', 'fr') for translation")
                                }
                            }
                        }
                    } header: {
                        Text("Language & Math")
                            .foregroundStyle(.secondary)
                    }

                    // Advanced Options
                    Section {
                        DisclosureGroup("Advanced Options") {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("Error correction")
                                    Button(action: { /* Show help for error correction */ }) {
                                        Image(systemName: "info.circle")
                                            .foregroundColor(.blue)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    .help("Corrects recognition mistakes and improves grammar")
                                    Spacer()
                                    Toggle("", isOn: $errorCorrection)
                                        .disabled(isCustomMode)
                                        .onChange(of: errorCorrection) { _ in updateSystemPrompt() }
                                }

                                HStack {
                                    Text("Highlight uncertain text")
                                    Button(action: { /* Show help for low confidence highlighting */ }) {
                                        Image(systemName: "info.circle")
                                            .foregroundColor(.blue)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    .help("Marks low-confidence sections with [?]")
                                    Spacer()
                                    Toggle("", isOn: $lowConfidenceHighlighting)
                                        .disabled(isCustomMode)
                                        .onChange(of: lowConfidenceHighlighting) { _ in updateSystemPrompt() }
                                }

                                HStack {
                                    Text("Group related content")
                                    Button(action: { /* Show help for contextual grouping */ }) {
                                        Image(systemName: "info.circle")
                                            .foregroundColor(.blue)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    .help("Intelligently groups related content into cohesive blocks")
                                    Spacer()
                                    Toggle("", isOn: $contextualGrouping)
                                        .disabled(isCustomMode)
                                        .onChange(of: contextualGrouping) { _ in updateSystemPrompt() }
                                }

                                HStack {
                                    Text("Generate alt text for images")
                                    Button(action: { /* Show help for alt text generation */ }) {
                                        Image(systemName: "info.circle")
                                            .foregroundColor(.blue)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    .help("Creates descriptive text for images or graphics")
                                    Spacer()
                                    Toggle("", isOn: $accessibilityAltText)
                                        .disabled(isCustomMode)
                                        .onChange(of: accessibilityAltText) { _ in updateSystemPrompt() }
                                }

                                HStack {
                                    Text("Extract spatial context")
                                    Button(action: { /* Show help for spatial context extraction */ }) {
                                        Image(systemName: "info.circle")
                                            .foregroundColor(.blue)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    .help("Includes annotations and describes spatial relationships")
                                    Spacer()
                                    Toggle("", isOn: $smartContext)
                                        .disabled(isCustomMode)
                                        .onChange(of: smartContext) { _ in updateSystemPrompt() }
                                }
                            }
                            .padding(.top, 4)
                        }
                    } header: {
                        Text("Advanced")
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
