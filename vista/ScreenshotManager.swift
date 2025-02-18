import Combine
import SwiftUI

enum ProcessingStatus {
    case none
    case processing
    case success
    case error(String)
}

class ScreenshotManager: ObservableObject {
    @Published var status: ProcessingStatus = .none
    private let geminiClient = GeminiClient()

    func initiateScreenshot() {
        let task = Process()
        task.launchPath = "/usr/sbin/screencapture"
        task.arguments = ["-i", "-c"]  // Interactive mode, copy to clipboard

        do {
            try task.run()
            task.waitUntilExit()

            if task.terminationStatus == 0 {
                processScreenshot()
            }
        } catch {
            status = .error("Failed to capture screenshot")
        }
    }

    private func processScreenshot() {
        guard let pasteboard = NSPasteboard.general.pasteboardItems?.first,
            let imageData = pasteboard.data(forType: .png)
        else {
            status = .error("No screenshot data found")
            return
        }

        status = .processing

        Task {
            do {
                let extractedText = try await geminiClient.processImage(imageData)

                DispatchQueue.main.async {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(extractedText, forType: .string)
                    self.status = .success

                    // Auto-dismiss after 2 seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        self.status = .none
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    self.status = .error(error.localizedDescription)
                }
            }
        }
    }
}
