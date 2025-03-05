import Foundation
import SwiftUI

protocol OCRModel {
    var displayName: String { get }
    var iconName: String { get }
    func processImage(_ imageData: Data, withCustomPrompt customPrompt: String?) async throws
        -> String
}

enum OCRModelType: String, CaseIterable {
    // Gemini models
    case geminiPro = "gemini-2.0-pro-exp-02-05"
    case geminiFlashLite = "gemini-2.0-flash-lite"
    case geminiFlash = "gemini-2.0-flash"

    // VisionKit model
    case visionKit = "visionkit-local"

    var displayName: String {
        switch self {
        case .geminiPro: return "Gemini 2.0 Pro Experimental 02-05"
        case .geminiFlashLite: return "Gemini 2.0 Flash-Lite"
        case .geminiFlash: return "Gemini 2.0 Flash"
        case .visionKit: return "VisionKit (local)"
        }
    }

    var iconName: String {
        switch self {
        case .geminiPro: return "brain.fill"  // Most advanced/capable
        case .geminiFlashLite: return "bolt.fill"  // Fastest/smallest
        case .geminiFlash: return "star.fill"  // Standard/balanced
        case .visionKit: return "laptopcomputer"  // Local processing
        }
    }

    var isGeminiModel: Bool {
        switch self {
        case .geminiPro, .geminiFlashLite, .geminiFlash:
            return true
        case .visionKit:
            return false
        }
    }

    static var `default`: OCRModelType { .geminiFlash }
}

class ModelManager: ObservableObject {
    private let geminiClient: GeminiClient
    private let visionKitClient: VisionKitClient
    @Published var selectedModel: OCRModelType

    init(apiKey: String) {
        self.geminiClient = GeminiClient(apiKey: apiKey)
        self.visionKitClient = VisionKitClient()

        // Get model from UserDefaults or use default
        if let modelTypeString = UserDefaults.standard.string(forKey: "selectedModelType"),
            let modelType = OCRModelType(rawValue: modelTypeString)
        {
            self.selectedModel = modelType
        } else {
            self.selectedModel = OCRModelType.default
            UserDefaults.standard.set(OCRModelType.default.rawValue, forKey: "selectedModelType")
        }

        // Set initial model for Gemini client
        if selectedModel.isGeminiModel {
            geminiClient.setModelString(selectedModel.rawValue)
        }
    }

    func setModel(_ model: OCRModelType) {
        selectedModel = model

        // Update Gemini client if a Gemini model is selected
        if model.isGeminiModel {
            geminiClient.setModelString(model.rawValue)
        }
    }

    func processImage(_ imageData: Data, withCustomPrompt customPrompt: String? = nil) async throws
        -> String
    {
        switch selectedModel {
        case .geminiPro, .geminiFlashLite, .geminiFlash:
            return try await geminiClient.processImage(imageData, withCustomPrompt: customPrompt)
        case .visionKit:
            return try await visionKitClient.processImage(imageData, withCustomPrompt: customPrompt)
        }
    }
}
