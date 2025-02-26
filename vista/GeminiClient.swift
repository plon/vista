import Foundation

// MARK: - Errors
enum GeminiError: Error {
    case uploadFailed(String)
    case generateContentFailed(String)
    case invalidResponse
    case invalidJSON
    case noTextDetected
}

// MARK: - Models
enum GeminiModel: String, CaseIterable {
    case pro = "gemini-2.0-pro-exp-02-05"
    case flashLite = "gemini-2.0-flash-lite"
    case flash = "gemini-2.0-flash"

    var displayName: String {
        switch self {
        case .pro: return "Gemini 2.0 Pro Experimental 02-05"
        case .flashLite: return "Gemini 2.0 Flash-Lite"
        case .flash: return "Gemini 2.0 Flash"
        }
    }

    var iconName: String {
        switch self {
        case .pro: return "brain.fill"  // Most advanced/capable
        case .flashLite: return "bolt.fill"  // Fastest/smallest
        case .flash: return "star.fill"  // Standard/balanced
        }
    }

    static var `default`: GeminiModel { .flash }
}

// MARK: - Response Types
struct GenerationResponse: Codable {
    let candidates: [Candidate]

    struct Candidate: Codable {
        let content: ContentParts

        struct ContentParts: Codable {
            let parts: [TextPart]

            struct TextPart: Codable {
                let text: String
            }
        }
    }
}

// Structured response type
struct ExtractedContent: Codable {
    let extractedText: String
    let hasText: Bool
}

// MARK: - GeminiClient
final class GeminiClient {
    // MARK: - Properties
    private let apiKey: String
    private var model: String
    private let session: URLSession

    // MARK: - Constants
    private enum Constants {
        static let baseURL = "https://generativelanguage.googleapis.com"
        static let generateEndpoint = "/v1beta/models"
        static let mimeType = "image/png"
    }

    // MARK: - Initialization
    init(apiKey: String) {
        self.apiKey = apiKey
        self.model = GeminiModel.default.rawValue
        self.session = .shared
    }

    // MARK: - Public Methods
    func setModel(_ model: GeminiModel) {
        self.model = model.rawValue
    }

    func processImage(_ imageData: Data, withCustomPrompt customPrompt: String? = nil) async throws
        -> String
    {
        let url = URL(
            string:
                "\(Constants.baseURL)\(Constants.generateEndpoint)/\(model):generateContent?key=\(apiKey)"
        )!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Convert image data to base64
        let base64Image = imageData.base64EncodedString()

        // Print the model being used for this API call
        print("Making Gemini API request using model: \(model)")

        // Use the custom prompt if available, otherwise use the default
        let promptText =
            customPrompt
            ?? "Extract all text from the image while preserving its original structure, including line breaks, indentation, bullet points, tables, and formatting as closely as possible using markdown format. Convert math equations into LaTeX; For inline formulas, enclose the formula in $…$. For displayed formulas, use $$…$$."

        let requestBody: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        [
                            "text": promptText
                        ],
                        [
                            "inline_data": [
                                "mime_type": Constants.mimeType,
                                "data": base64Image,
                            ]
                        ],
                    ]
                ]
            ],
            "generationConfig": [
                "temperature": 0,
                "topK": 1,
                "topP": 0.3,
                "maxOutputTokens": 8192,
                "responseMimeType": "application/json",
                "responseSchema": [
                    "type": "object",
                    "properties": [
                        "extractedText": [
                            "type": "string"
                        ],
                        "hasText": [
                            "type": "boolean"
                        ],
                    ],
                    "required": ["extractedText", "hasText"],
                ],
            ],
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw GeminiError.generateContentFailed("Invalid response type")
        }

        print("Gemini API response received with status code: \(httpResponse.statusCode)")

        guard (200...299).contains(httpResponse.statusCode) else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            print("Gemini API error: \(errorMessage)")
            throw GeminiError.generateContentFailed("Generation failed: \(errorMessage)")
        }

        return try parseGenerationResponse(from: data)
    }

    // MARK: - Private Methods
    private func parseGenerationResponse(from data: Data) throws -> String {
        print("Parsing Gemini API response")
        let response = try JSONDecoder().decode(GenerationResponse.self, from: data)
        guard let jsonString = response.candidates.first?.content.parts.first?.text else {
            print("Failed to extract JSON from Gemini response")
            throw GeminiError.invalidJSON
        }

        // Parse the structured JSON response
        let jsonData = jsonString.data(using: .utf8)!
        let extractedContent = try JSONDecoder().decode(ExtractedContent.self, from: jsonData)

        // Check if text was detected
        guard extractedContent.hasText else {
            print("No text detected in the image")
            throw GeminiError.noTextDetected
        }

        print("Successfully extracted \(extractedContent.extractedText.count) characters of text")
        return extractedContent.extractedText
    }
}
