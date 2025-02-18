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
}
