import Foundation
import SwiftUI
import Vision

enum VisionKitError: Error {
    case recognitionFailed(String)
    case invalidImageData
    case noTextDetected
}

final class VisionKitClient: @unchecked Sendable {
    init() {
        // No initialization needed for VisionKit
    }

    func processImage(_ imageData: Data, withCustomPrompt customPrompt: String? = nil) async throws
        -> String
    {
        guard let image = NSImage(data: imageData) else {
            throw VisionKitError.invalidImageData
        }

        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            throw VisionKitError.invalidImageData
        }

        let requestHandler = VNImageRequestHandler(cgImage: cgImage)
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate

        do {
            try requestHandler.perform([request])
            guard let observations = request.results else {
                throw VisionKitError.recognitionFailed("No results returned")
            }

            let recognizedText = observations.compactMap { observation in
                observation.topCandidates(1).first?.string
            }.joined(separator: "\n")

            if recognizedText.isEmpty {
                throw VisionKitError.noTextDetected
            }

            return recognizedText
        } catch {
            throw VisionKitError.recognitionFailed(error.localizedDescription)
        }
    }
}
