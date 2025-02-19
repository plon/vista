import Combine
import SwiftUI

class ScreenshotManager: ObservableObject {
    @Published var status: ProcessingStatus = .none
    @AppStorage("selectedModel") private var selectedModel = GeminiModel.flash
    private lazy var geminiClient = GeminiClient(apiKey: "AIzaSyDA7Hk_b6UrgLWyiObL6uZ9MHMasgy8imQ")
    private let statusWindow = StatusWindowController()

    init() {
        geminiClient.setModel(selectedModel)
    }

    func updateModel(_ model: GeminiModel) {
        selectedModel = model
        geminiClient.setModel(model)
    }

    private var hasScreenRecordingPermission: Bool {
        CGPreflightScreenCaptureAccess()
    }

    private func requestScreenRecordingPermission() {
        CGRequestScreenCaptureAccess()
    }

    func initiateScreenshot() {
        if !hasScreenRecordingPermission {
            requestScreenRecordingPermission()
            statusWindow.show(withStatus: .error("Screen Recording permission is required"))
            return
        }

        let tempFile = FileManager.default.temporaryDirectory.appendingPathComponent(
            "vista_temp_screenshot.png")

        let task = Process()
        task.launchPath = "/usr/sbin/screencapture"
        task.arguments = ["-i", tempFile.path]

        do {
            try task.run()
            task.waitUntilExit()

            // Only try to process if the file exists
            if FileManager.default.fileExists(atPath: tempFile.path) {
                if let imageData = try? Data(contentsOf: tempFile) {
                    processScreenshotData(imageData)
                    try? FileManager.default.removeItem(at: tempFile)
                } else {
                    statusWindow.show(withStatus: .error("Failed to read screenshot data"))
                }
            } else {
                // If no file exists, it means the user cancelled
                statusWindow.show(withStatus: .cancelled)
            }
        } catch {
            print("Screenshot error: \(error.localizedDescription)")
            statusWindow.show(
                withStatus: .error("Failed to capture screenshot: \(error.localizedDescription)"))
        }
    }

    func processScreenshotData(_ imageData: Data) {
        statusWindow.show(withStatus: .processing)

        Task {
            do {
                let extractedText = try await geminiClient.processImage(imageData)

                await MainActor.run {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(extractedText, forType: .string)
                    self.status = .success
                    self.statusWindow.show(withStatus: .success)
                }
            } catch GeminiError.noTextDetected {
                await MainActor.run {
                    self.status = .error("No text detected")
                    self.statusWindow.show(withStatus: .error("No text detected in image"))
                }
            } catch GeminiError.uploadFailed(let message) {
                await MainActor.run {
                    self.status = .error(message)
                    self.statusWindow.show(withStatus: .error("Upload failed: \(message)"))
                }
            } catch GeminiError.generateContentFailed(let message) {
                await MainActor.run {
                    self.status = .error(message)
                    self.statusWindow.show(
                        withStatus: .error("Content generation failed: \(message)"))
                }
            } catch {
                print("Processing error: \(error)")
                await MainActor.run {
                    self.status = .error(error.localizedDescription)
                    self.statusWindow.show(
                        withStatus: .error("Processing failed: \(error.localizedDescription)"))
                }
            }
        }
    }
}
