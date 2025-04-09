import Foundation
import SwiftUI

class DefaultSettings {
    static let shared = DefaultSettings()

    private init() {
        registerDefaults()
    }

    func registerDefaults() {
        let defaults: [String: Any] = [
            "selectedModelType": OCRModelType.geminiFlash.rawValue,
            "shortcutEnabled": true,
            "popupEnabled": true,
            "displayTarget": "screenshot",
            "popupSize": StatusPopupSize.large.rawValue,
            "hapticFeedbackEnabled": true,
            "resolutionLimitEnabled": false,
            "maxImageWidth": 4000.0,
            "maxImageHeight": 4000.0,
            "formatType": "plain_text",
            "prettyFormatting": false,
            "originalFormatting": true,
            "latexMath": true,
            "spellCheck": false,
            "lowConfidenceHighlighting": false,
            "contextualGrouping": false,
            "accessibilityAltText": false,
            "smartContext": false,
            "visionKitRecognitionLevel": "accurate",
            "visionKitUsesLanguageCorrection": true,
            "isCustomMode": false,
            "geminiApiKey": "",
        ]

        UserDefaults.standard.register(defaults: defaults)
    }
}
