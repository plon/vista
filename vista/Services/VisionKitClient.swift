import Foundation
import SwiftUI
import Vision

enum VisionKitError: Error {
    case recognitionFailed(String)
    case invalidImageData
    case noTextDetected
}

final class VisionKitClient: @unchecked Sendable {
    // Configuration properties
    private var recognitionLevel: VNRequestTextRecognitionLevel = .accurate
    private var recognitionLanguages: [String] = []
    private var usesLanguageCorrection: Bool = true
    private var customWords: [String] = []

    init(
        recognitionLevel: VNRequestTextRecognitionLevel = .accurate,
        recognitionLanguages: [String] = [],
        usesLanguageCorrection: Bool = true,
        customWords: [String] = []
    ) {
        self.recognitionLevel = recognitionLevel
        self.recognitionLanguages = recognitionLanguages
        self.usesLanguageCorrection = usesLanguageCorrection
        self.customWords = customWords
    }

    // Method to update configuration
    func updateConfiguration(
        recognitionLevel: VNRequestTextRecognitionLevel? = nil,
        recognitionLanguages: [String]? = nil,
        usesLanguageCorrection: Bool? = nil,
        customWords: [String]? = nil
    ) {
        if let recognitionLevel = recognitionLevel {
            self.recognitionLevel = recognitionLevel
        }

        if let recognitionLanguages = recognitionLanguages {
            self.recognitionLanguages = recognitionLanguages
        }

        if let usesLanguageCorrection = usesLanguageCorrection {
            self.usesLanguageCorrection = usesLanguageCorrection
        }

        if let customWords = customWords {
            self.customWords = customWords
        }
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

        // Configure the request with our settings
        request.recognitionLevel = self.recognitionLevel

        if !self.recognitionLanguages.isEmpty {
            request.recognitionLanguages = self.recognitionLanguages
        }

        request.usesLanguageCorrection = self.usesLanguageCorrection

        if !self.customWords.isEmpty {
            request.customWords = self.customWords
        }

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
