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
final class GeminiClient: @unchecked Sendable {
    // MARK: - Properties
    private let apiKey: String
    private var model: String
    private let session: URLSession
    private let lock = NSLock()  // Add a lock for thread safety
    private var _activeSessionTask: URLSessionDataTask?

    // Thread-safe access to activeSessionTask
    private var activeSessionTask: URLSessionDataTask? {
        get {
            lock.lock()
            defer { lock.unlock() }
            return _activeSessionTask
        }
        set {
            lock.lock()
            defer { lock.unlock() }
            _activeSessionTask = newValue
        }
    }

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
        lock.lock()
        defer { lock.unlock() }
        self.model = model.rawValue
    }

    func processImage(_ imageData: Data, withCustomPrompt customPrompt: String? = nil) async throws
        -> String
    {
        return try await withTaskCancellationHandler {
            // Capture needed values to avoid capturing self
            let model = lock.withLock { self.model }
            let apiKey = self.apiKey
            let session = self.session

            // Create the URL request
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

            let promptText = customPrompt ?? generateOCRSystemPrompt()

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
                    "topK": 5,
                    "topP": 0.5,
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

            // Check for cancellation before making the network request
            try Task.checkCancellation()

            // Create a task that can be properly cancelled
            let resultData: (data: Data, response: HTTPURLResponse) =
                try await withCheckedThrowingContinuation { continuation in
                    let task = session.dataTask(with: request) { data, response, error in
                        // First check for task cancellation error
                        if let nsError = error as NSError?,
                            nsError.domain == NSURLErrorDomain
                                && nsError.code == NSURLErrorCancelled
                        {
                            // Resume with a cancellation error instead of not resuming
                            continuation.resume(throwing: CancellationError())
                            return
                        }

                        // Handle other errors
                        if let error = error {
                            continuation.resume(
                                throwing: GeminiError.uploadFailed(
                                    "Network error: \(error.localizedDescription)"))
                            return
                        }

                        guard let data = data else {
                            continuation.resume(throwing: GeminiError.invalidResponse)
                            return
                        }

                        guard let httpResponse = response as? HTTPURLResponse else {
                            continuation.resume(
                                throwing: GeminiError.generateContentFailed("Invalid response type")
                            )
                            return
                        }

                        if !(200...299).contains(httpResponse.statusCode) {
                            let errorMessage =
                                String(data: data, encoding: .utf8) ?? "Unknown error"
                            print("Gemini API error: \(errorMessage)")
                            continuation.resume(
                                throwing: GeminiError.generateContentFailed(
                                    "Generation failed: \(errorMessage)"))
                            return
                        }

                        // Success path - return both data and response
                        continuation.resume(returning: (data, httpResponse))
                    }

                    self.activeSessionTask = task
                    task.resume()
                }

            // Process the data after we've successfully received it
            print(
                "Gemini API response received with status code: \(resultData.response.statusCode)")
            return try self.parseGenerationResponse(from: resultData.data)

        } onCancel: { [weak self] in
            // This correctly handles user cancellation
            self?.activeSessionTask?.cancel()
            self?.activeSessionTask = nil
            print("Gemini API request was cancelled")
        }
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
