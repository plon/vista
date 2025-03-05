import SwiftUI

@main
struct VistaApp: App {
    @StateObject private var screenshotManager = ScreenshotManager()
    @StateObject private var keyboardManager: KeyboardShortcutManager

    init() {
        // Set default model if not already set in UserDefaults
        if UserDefaults.standard.string(forKey: "selectedModelType") == nil {
            UserDefaults.standard.set(
                OCRModelType.geminiFlash.rawValue, forKey: "selectedModelType")
        }

        let manager = ScreenshotManager()
        _keyboardManager = StateObject(
            wrappedValue: KeyboardShortcutManager(screenshotManager: manager))
        _screenshotManager = StateObject(wrappedValue: manager)
    }

    var body: some Scene {
        MenuBarExtra("vista", systemImage: "mountain.2.fill") {
            MenuBarView(screenshotManager: screenshotManager, keyboardManager: keyboardManager)
        }
    }
}
