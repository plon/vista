import Combine
import SwiftUI
import Vision
import VisionKit

enum ProcessingStatus: Equatable {
    case none
    case processing
    case success
    case cancelled
    case error(String)
}

enum OCRError: Error {
    case noTextDetected
    case recognitionFailed(String)
    case invalidImageData
}

class ScreenshotManager: ObservableObject {
    @Published var status: ProcessingStatus = .none
    @Published var isProcessing = false
    @AppStorage("selectedModelType") private var selectedModelType = OCRModelType.default
    private let modelManager: ModelManager
    private let statusWindow = StatusWindowController()

    private var activeTask: Task<Void, Never>?

    init() {
        // Set default model if not already set in UserDefaults
        if UserDefaults.standard.string(forKey: "selectedModelType") == nil {
            UserDefaults.standard.set(
                OCRModelType.geminiFlash.rawValue, forKey: "selectedModelType")
        }

        self.modelManager = ModelManager(apiKey: "AIzaSyDA7Hk_b6UrgLWyiObL6uZ9MHMasgy8imQ")
        self.modelManager.setModel(selectedModelType)
    }

    func updateModel(_ model: OCRModelType) {
        selectedModelType = model
        print("Updating model to: \(model.displayName)")
        modelManager.setModel(model)
    }

    func updateVisionKitSettings(
        recognitionLevel: VNRequestTextRecognitionLevel? = nil,
        recognitionLanguages: [String]? = nil,
        usesLanguageCorrection: Bool? = nil,
        customWords: [String]? = nil
    ) {
        modelManager.updateVisionKitClient(
            recognitionLevel: recognitionLevel,
            recognitionLanguages: recognitionLanguages,
            usesLanguageCorrection: usesLanguageCorrection,
            customWords: customWords
        )
    }

    private var hasScreenRecordingPermission: Bool {
        CGPreflightScreenCaptureAccess()
    }

    private func requestScreenRecordingPermission() {
        CGRequestScreenCaptureAccess()
    }

    func cancelProcessing() {
        print("Canceling active processing task")
        activeTask?.cancel()
        activeTask = nil

        DispatchQueue.main.async {
            self.isProcessing = false
            self.status = .cancelled
            self.statusWindow.show(withStatus: .cancelled, onCancel: nil)
        }
    }

    func initiateScreenshot() {
        // Don't allow starting a new screenshot while already processing
        if isProcessing {
            return
        }

        if !hasScreenRecordingPermission {
            requestScreenRecordingPermission()
            statusWindow.show(
                withStatus: .error("Screen Recording permission is required"), onCancel: nil)
            return
        }

        // Get the current mouse position to determine which screen the user is on
        let mouseLocation = NSEvent.mouseLocation
        let screenWithMouse =
            NSScreen.screens.first { screen in
                NSMouseInRect(mouseLocation, screen.frame, false)
            } ?? NSScreen.main

        statusWindow.setActiveScreen(screenWithMouse)

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
                    statusWindow.show(
                        withStatus: .error("Failed to read screenshot data"), onCancel: nil)
                }
            } else {
                // If no file exists, it means the user cancelled
                statusWindow.show(withStatus: .cancelled, onCancel: nil)
            }
        } catch {
            print("Screenshot error: \(error.localizedDescription)")
            statusWindow.show(
                withStatus: .error("Failed to capture screenshot: \(error.localizedDescription)"),
                onCancel: nil
            )
        }
    }

    func processScreenshotData(_ imageData: Data) {
        isProcessing = true
        statusWindow.show(
            withStatus: .processing,
            onCancel: { [weak self] in
                self?.cancelProcessing()
            })

        // TO DELETE
        // Print original image dimensions right at the start
        if let originalImage = NSImage(data: imageData) {
            print(
                "Original image dimensions before processing: \(Int(originalImage.size.width))x\(Int(originalImage.size.height))"
            )
        }

        let hapticFeedbackEnabled = UserDefaults.standard.bool(forKey: "hapticFeedbackEnabled")
        if hapticFeedbackEnabled {
            Task {
                try? await Task.sleep(nanoseconds: 200_000_000)  // 0.2 seconds
                let hapticFeedback = NSHapticFeedbackManager.defaultPerformer
                hapticFeedback.perform(
                    NSHapticFeedbackManager.FeedbackPattern.alignment,
                    performanceTime: .now
                )
            }
        }

        activeTask = Task {
            do {
                // Check for cancellation
                if Task.isCancelled {
                    await MainActor.run {
                        self.isProcessing = false
                        self.status = .cancelled
                        self.statusWindow.show(withStatus: .cancelled, onCancel: nil)
                    }
                    return
                }

                let processedImageData = self.resizeImageIfNeeded(imageData)

                // TO DELETE
                // Print dimensions after resizing
                if let processedImage = NSImage(data: processedImageData) {
                    print(
                        "Image dimensions after resizing: \(Int(processedImage.size.width))x\(Int(processedImage.size.height))"
                    )
                }

                let systemPrompt =
                    UserDefaults.standard.string(forKey: "systemPrompt")
                    ?? generateOCRSystemPrompt()

                let extractedText = try await modelManager.processImage(
                    processedImageData, withCustomPrompt: systemPrompt)

                // Check for cancellation after receiving response
                if Task.isCancelled {
                    await MainActor.run {
                        self.isProcessing = false
                        self.status = .cancelled
                        self.statusWindow.show(withStatus: .cancelled, onCancel: nil)
                    }
                    return
                }

                await MainActor.run {
                    self.copyToClipboard(extractedText)

                    let hapticFeedbackEnabled = UserDefaults.standard.bool(
                        forKey: "hapticFeedbackEnabled")
                    if hapticFeedbackEnabled {
                        let hapticFeedback = NSHapticFeedbackManager.defaultPerformer
                        hapticFeedback.perform(
                            NSHapticFeedbackManager.FeedbackPattern.levelChange,
                            performanceTime: .now
                        )
                    }

                    self.isProcessing = false
                    self.status = .success
                    self.statusWindow.show(withStatus: .success, onCancel: nil)
                }
            } catch VisionKitError.noTextDetected, GeminiError.noTextDetected {
                await MainActor.run {
                    self.isProcessing = false
                    self.status = .error("No text detected")
                    self.statusWindow.show(
                        withStatus: .error("No text detected in image"), onCancel: nil)
                }
            } catch VisionKitError.recognitionFailed(let message),
                GeminiError.generateContentFailed(let message)
            {
                await MainActor.run {
                    self.isProcessing = false
                    self.status = .error(message)
                    self.statusWindow.show(
                        withStatus: .error("Recognition failed: \(message)"), onCancel: nil)
                }
            } catch VisionKitError.invalidImageData, GeminiError.invalidResponse {
                await MainActor.run {
                    self.isProcessing = false
                    self.status = .error("Invalid image data")
                    self.statusWindow.show(
                        withStatus: .error("Invalid image data"), onCancel: nil)
                }
            } catch GeminiError.uploadFailed(let message) {
                await MainActor.run {
                    self.isProcessing = false
                    self.status = .error(message)
                    self.statusWindow.show(
                        withStatus: .error("Upload failed: \(message)"), onCancel: nil)
                }
            } catch GeminiError.invalidJSON {
                await MainActor.run {
                    self.isProcessing = false
                    self.status = .error("Invalid response format")
                    self.statusWindow.show(
                        withStatus: .error("Invalid response format"), onCancel: nil)
                }
            } catch {
                if error is CancellationError {
                    await MainActor.run {
                        self.isProcessing = false
                        self.status = .cancelled
                        self.statusWindow.show(withStatus: .cancelled, onCancel: nil)
                    }
                } else {
                    print("Processing error: \(error)")
                    await MainActor.run {
                        self.isProcessing = false
                        self.status = .error(error.localizedDescription)
                        self.statusWindow.show(
                            withStatus: .error("Processing failed: \(error.localizedDescription)"),
                            onCancel: nil
                        )
                    }
                }
            }

            // Clear the active task reference when done
            self.activeTask = nil
        }
    }

    func copyToClipboard(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()

        // Get the user's preferred format
        let formatType = UserDefaults.standard.string(forKey: "formatType") ?? "plain_text"

        // Always set plain text as a fallback
        pasteboard.setString(text, forType: .string)

        // Handle rich text formats
        switch formatType {
        case "html":
            if let data = text.data(using: .utf8) {
                pasteboard.setData(data, forType: .html)
                print("Copied HTML to clipboard as rich text")
            }

        case "rtf":
            if let data = text.data(using: .utf8) {
                pasteboard.setData(data, forType: .rtf)
                print("Copied RTF to clipboard as rich text")
            }

        default:
            // For all other formats (markdown, json, latex, xml, plain_text),
            // we just use the plain text representation we already set
            print("Copied \(formatType) to clipboard as plain text")
        }
    }

    private func resizeImageIfNeeded(_ imageData: Data) -> Data {
        let resolutionLimitEnabled = UserDefaults.standard.bool(forKey: "resolutionLimitEnabled")
        if !resolutionLimitEnabled {
            return imageData
        }

        // Get the max dimensions from user settings
        let maxImageWidth = UserDefaults.standard.double(forKey: "maxImageWidth")
        let maxImageHeight = UserDefaults.standard.double(forKey: "maxImageHeight")

        if maxImageWidth <= 0 || maxImageHeight <= 0 {
            return imageData
        }

        guard let image = NSImage(data: imageData) else {
            return imageData
        }

        let originalSize = image.size
        if originalSize.width <= maxImageWidth && originalSize.height <= maxImageHeight {
            return imageData
        }

        // Calculate the scaling factor based on both dimensions
        let widthRatio = maxImageWidth / originalSize.width
        let heightRatio = maxImageHeight / originalSize.height
        let scaleFactor = min(widthRatio, heightRatio)

        let newSize = NSSize(
            width: originalSize.width * scaleFactor,
            height: originalSize.height * scaleFactor
        )

        let resizedImage = NSImage(size: newSize)
        resizedImage.lockFocus()
        NSGraphicsContext.current?.imageInterpolation = .high
        image.draw(in: NSRect(origin: .zero, size: newSize))
        resizedImage.unlockFocus()

        guard let tiffData = resizedImage.tiffRepresentation,
            let bitmapImage = NSBitmapImageRep(data: tiffData),
            let pngData = bitmapImage.representation(using: .png, properties: [:])
        else {
            return imageData
        }
        return pngData
    }
}
