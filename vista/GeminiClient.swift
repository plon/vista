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
    case flashLite = "gemini-2.0-flash-lite-preview-02-05"
    case flash = "gemini-2.0-flash"

    var displayName: String {
        switch self {
        case .pro: return "Gemini 2.0 Pro Experimental 02-05"
        case .flashLite: return "Gemini 2.0 Flash-Lite Preview 02-05"
        case .flash: return "Gemini 2.0 Flash"
        }
    }

    static var `default`: GeminiModel { .flash }
}

// MARK: - Response Types
struct FileUploadResponse: Codable {
    let file: FileInfo

    struct FileInfo: Codable {
        let name: String
        let uri: String
        let mimeType: String
        let sizeBytes: String
        let state: String
    }
}

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

struct ExtractedTextResponse: Codable {
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
        static let uploadEndpoint = "/upload/v1beta/files"
        static let generateEndpoint = "/v1beta/models"
        static let mimeType = "image/png"
    }

    // MARK: - Initialization
    init(
        apiKey: String = ProcessInfo.processInfo.environment["GEMINI_API_KEY"] ?? "",
        session: URLSession = .shared
    ) {
        self.apiKey = apiKey
        self.model = GeminiModel.default.rawValue
        self.session = session
    }

    // MARK: - Public Methods
    func setModel(_ model: GeminiModel) {
        self.model = model.rawValue
    }

    func processImage(_ imageData: Data) async throws -> String {
        let fileUri = try await uploadImage(imageData)
        return try await generateContent(fileUri: fileUri)
    }

    // MARK: - Private Methods
    private func uploadImage(_ imageData: Data) async throws -> String {
        let startRequest = try makeUploadStartRequest(imageData: imageData)
        let uploadURL = try await getUploadURL(from: startRequest)
        return try await performUpload(imageData: imageData, to: uploadURL)
    }

    private func makeUploadStartRequest(imageData: Data) throws -> URLRequest {
        let url = URL(string: Constants.baseURL + Constants.uploadEndpoint + "?key=\(apiKey)")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("resumable", forHTTPHeaderField: "X-Goog-Upload-Protocol")
        request.setValue("start", forHTTPHeaderField: "X-Goog-Upload-Command")
        request.setValue(
            "\(imageData.count)", forHTTPHeaderField: "X-Goog-Upload-Header-Content-Length")
        request.setValue(
            Constants.mimeType, forHTTPHeaderField: "X-Goog-Upload-Header-Content-Type")

        let metadata = ["file": ["display_name": "image.png"]]
        request.httpBody = try JSONSerialization.data(withJSONObject: metadata)

        return request
    }

    private func getUploadURL(from request: URLRequest) async throws -> URL {
        let (_, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
            let uploadURL = httpResponse.value(forHTTPHeaderField: "X-Goog-Upload-URL")
        else {
            throw GeminiError.uploadFailed("Failed to get upload URL")
        }
        return URL(string: uploadURL)!
    }

    private func performUpload(imageData: Data, to uploadURL: URL) async throws -> String {
        var request = URLRequest(url: uploadURL)
        request.httpMethod = "POST"
        request.setValue("\(imageData.count)", forHTTPHeaderField: "Content-Length")
        request.setValue("0", forHTTPHeaderField: "X-Goog-Upload-Offset")
        request.setValue("upload, finalize", forHTTPHeaderField: "X-Goog-Upload-Command")
        request.httpBody = imageData

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
            (200...299).contains(httpResponse.statusCode)
        else {
            throw GeminiError.uploadFailed(
                "Upload failed with status: \((response as? HTTPURLResponse)?.statusCode ?? -1)")
        }

        let uploadResponse = try JSONDecoder().decode(FileUploadResponse.self, from: data)
        return uploadResponse.file.uri
    }

    private func generateContent(fileUri: String) async throws -> String {
        let url = URL(
            string: Constants.baseURL + Constants.generateEndpoint
                + "/\(model):generateContent?key=\(apiKey)")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try makeGenerationRequestBody(fileUri: fileUri)

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
            (200...299).contains(httpResponse.statusCode)
        else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw GeminiError.generateContentFailed(
                "Generation failed with status: \((response as? HTTPURLResponse)?.statusCode ?? -1), Error: \(errorMessage)"
            )
        }

        return try parseGenerationResponse(from: data)
    }

    private func makeGenerationRequestBody(fileUri: String) throws -> Data {
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
                                "mime_type": Constants.mimeType,
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
                        "extractedText": ["type": "string"],
                        "hasText": ["type": "boolean"],
                    ],
                    "required": ["extractedText", "hasText"],
                ],
            ],
        ]

        return try JSONSerialization.data(withJSONObject: requestBody)
    }

    private func parseGenerationResponse(from data: Data) throws -> String {
        let response = try JSONDecoder().decode(GenerationResponse.self, from: data)
        guard let firstPartText = response.candidates.first?.content.parts.first?.text else {
            throw GeminiError.invalidJSON
        }

        let extractedResponse = try JSONDecoder().decode(
            ExtractedTextResponse.self,
            from: firstPartText.data(using: .utf8) ?? Data()
        )

        guard extractedResponse.hasText else {
            throw GeminiError.noTextDetected
        }

        return extractedResponse.extractedText
    }
}

// MARK: - Preview Support
extension GeminiClient {
    static func preview() -> GeminiClient {
        GeminiClient(apiKey: "dummy-key")
    }
}
