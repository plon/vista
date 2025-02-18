import SwiftUI

struct MenuBarView: View {
    @AppStorage("shortcutEnabled") private var shortcutEnabled = true
    @AppStorage("selectedModel") private var selectedModel = GeminiModel.flash
    @StateObject private var screenshotManager = ScreenshotManager()
    @State private var testResult: String = ""
    @State private var isProcessing = false

    // Create GeminiClient instance with your API key
    private let geminiClient = GeminiClient(apiKey: "AIzaSyDA7Hk_b6UrgLWyiObL6uZ9MHMasgy8imQ")

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button("Take Screenshot (⌘⇧2)") {
                screenshotManager.initiateScreenshot()
            }
            .disabled(isProcessing)

            Divider()

            Picker("Model", selection: $selectedModel) {
                ForEach(GeminiModel.allCases, id: \.self) { model in
                    Text(model.displayName).tag(model)
                }
            }
            .onChange(of: selectedModel) { newModel in
                geminiClient.setModel(newModel)
            }
            Button("Test with Sample Image") {
                testGeminiClient()
            }
            .disabled(isProcessing)

            if isProcessing {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
            }

            if !testResult.isEmpty {
                ScrollView {
                    Text(testResult)
                        .font(.system(size: 12))
                        .foregroundColor(testResult.hasPrefix("Error") ? .red : .green)
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(maxHeight: 200)
            }

            Divider()

            Toggle("Enable Shortcut", isOn: $shortcutEnabled)

            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
        }
        .padding()
        .frame(width: 300)
    }

    private func testGeminiClient() {
        guard let imageURL = Bundle.main.url(forResource: "test", withExtension: "png"),
            let imageData = try? Data(contentsOf: imageURL)
        else {
            testResult = "Error: Could not load test image"
            return
        }

        print("Found test image")
        isProcessing = true
        testResult = "Processing..."

        Task {
            do {
                print("Starting API request...")
                let extractedText = try await geminiClient.processImage(imageData)
                print("API request completed successfully")
                await MainActor.run {
                    testResult = "Success:\n\n\(extractedText)"
                    isProcessing = false
                }
            } catch GeminiError.noTextDetected {
                await MainActor.run {
                    testResult = "Error: No text was detected in the image"
                    isProcessing = false
                }
            } catch GeminiError.uploadFailed(let message) {
                await MainActor.run {
                    testResult = "Error: Failed to upload image - \(message)"
                    isProcessing = false
                }
            } catch GeminiError.generateContentFailed(let message) {
                await MainActor.run {
                    testResult = "Error: Failed to generate content - \(message)"
                    isProcessing = false
                }
            } catch GeminiError.invalidJSON {
                await MainActor.run {
                    testResult = "Error: Invalid JSON response received"
                    isProcessing = false
                }
            } catch {
                print("API request failed with error: \(error)")
                await MainActor.run {
                    testResult = "Error: Unexpected error - \(error.localizedDescription)"
                    isProcessing = false
                }
            }
        }
    }
}

#Preview {
    MenuBarView()
}
