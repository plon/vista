import Foundation

enum GeminiError: Error {
    case uploadFailed(String)
    case generateContentFailed(String)
    case invalidResponse
    case invalidJSON
    case noTextDetected
}

enum GeminiModel: String, CaseIterable {
    case pro = "gemini-2.0-pro-exp-02-05"
    case flashLite = "gemini-2.0-flash-lite-preview-02-05"
    case flash = "gemini-2.0-flash"

    var displayName: String {
        switch self {
        case .pro: return "Gemini 2.0 Pro Experimental 02-05"
        case .flashLite: return "Gemini 2.0 Flash-Lite Preview 02-05"
        case .flash: return "Gemini 2.0 Flash"
        }
    }

    static var `default`: GeminiModel {
        .flash
    }
}

struct FileUploadResponse: Codable {
    struct File: Codable {
        let name: String
        let uri: String
        let mimeType: String
        let sizeBytes: String
        let state: String
    }
    let file: File
}

struct GenerationResponse: Codable {
    let candidates: [Candidate]
}

struct Candidate: Codable {
    let content: Content
}

struct Content: Codable {
    let parts: [Part]
}

struct Part: Codable {
    let text: String
}

struct ExtractedTextResponse: Codable {
    let extractedText: String
    let hasText: Bool
}

class GeminiClient {
    private let apiKey: String
    private var model: String

    init(apiKey: String = ProcessInfo.processInfo.environment["GEMINI_API_KEY"] ?? "") {
        self.apiKey = apiKey
        self.model = GeminiModel.default.rawValue
    }

    func setModel(_ model: GeminiModel) {
        self.model = model.rawValue
    }

    func processImage(_ imageData: Data) async throws -> String {
        let fileUri = try await uploadImage(imageData)
        print("File URI received: \(fileUri)")  // Debug print
        return try await generateContent(fileUri: fileUri)
    }

    private func uploadImage(_ imageData: Data) async throws -> String {
        let startURL = "https://generativelanguage.googleapis.com/upload/v1beta/files?key=\(apiKey)"

        var startRequest = URLRequest(url: URL(string: startURL)!)
        startRequest.httpMethod = "POST"
        startRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        startRequest.setValue("resumable", forHTTPHeaderField: "X-Goog-Upload-Protocol")
        startRequest.setValue("start", forHTTPHeaderField: "X-Goog-Upload-Command")
        startRequest.setValue(
            "\(imageData.count)", forHTTPHeaderField: "X-Goog-Upload-Header-Content-Length")
        startRequest.setValue("image/png", forHTTPHeaderField: "X-Goog-Upload-Header-Content-Type")

        let metadata = ["file": ["display_name": "image.png"]]
        startRequest.httpBody = try JSONSerialization.data(withJSONObject: metadata)

        let (_, startResponse) = try await URLSession.shared.data(for: startRequest)

        guard let httpResponse = startResponse as? HTTPURLResponse,
            let uploadURL = httpResponse.value(forHTTPHeaderField: "X-Goog-Upload-URL")
        else {
            throw GeminiError.uploadFailed("Failed to get upload URL")
        }

        var uploadRequest = URLRequest(url: URL(string: uploadURL)!)
        uploadRequest.httpMethod = "POST"
        uploadRequest.setValue("\(imageData.count)", forHTTPHeaderField: "Content-Length")
        uploadRequest.setValue("0", forHTTPHeaderField: "X-Goog-Upload-Offset")
        uploadRequest.setValue("upload, finalize", forHTTPHeaderField: "X-Goog-Upload-Command")
        uploadRequest.httpBody = imageData

        let (data, response) = try await URLSession.shared.data(for: uploadRequest)

        guard let httpResponse = response as? HTTPURLResponse,
            (200...299).contains(httpResponse.statusCode)
        else {
            throw GeminiError.uploadFailed(
                "Upload failed with status: \((response as? HTTPURLResponse)?.statusCode ?? -1)")
        }

        guard let uploadResponse = try? JSONDecoder().decode(FileUploadResponse.self, from: data)
        else {
            throw GeminiError.uploadFailed("Invalid upload response")
        }

        return uploadResponse.file.uri
    }

    private func generateContent(fileUri: String) async throws -> String {
        let generateURL =
            "https://generativelanguage.googleapis.com/v1beta/models/\(model):generateContent?key=\(apiKey)"

        let requestBody: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        [
                            "text":
                                "Extract all text from the image while preserving its original structure, including line breaks, indentation, bullet points, tables, and formatting as closely as possible using markdown format. Convert math equations into LaTeX; For inline formulas, enclose the formula in $…$. For displayed formulas, use $$…$$."
                        ],
                        [
                            "file_data": [
                                "mime_type": "image/png",
                                "file_uri": fileUri,
                            ]
                        ],
                    ]
                ]
            ],
            "generationConfig": [
                "temperature": 0,
                "topK": 40,
                "topP": 0.95,
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

        var request = URLRequest(url: URL(string: generateURL)!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let jsonData = try JSONSerialization.data(withJSONObject: requestBody)
        request.httpBody = jsonData

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
            (200...299).contains(httpResponse.statusCode)
        else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw GeminiError.generateContentFailed(
                "Generation failed with status: \((response as? HTTPURLResponse)?.statusCode ?? -1), Error: \(errorMessage)"
            )
        }

        guard
            let candidateResponse = try? JSONDecoder().decode(GenerationResponse.self, from: data),
            let firstPartText = candidateResponse.candidates.first?.content.parts.first?.text
        else {
            throw GeminiError.invalidJSON
        }

        guard
            let extractedResponse = try? JSONDecoder().decode(
                ExtractedTextResponse.self,
                from: firstPartText.data(using: .utf8) ?? Data())
        else {
            throw GeminiError.invalidJSON
        }

        if !extractedResponse.hasText {
            throw GeminiError.noTextDetected
        }

        return extractedResponse.extractedText
    }
}

// Extension for testing
extension GeminiClient {
    static func preview() -> GeminiClient {
        GeminiClient(apiKey: "dummy-key")
    }
}
