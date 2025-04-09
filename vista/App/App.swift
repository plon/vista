import SwiftUI

@main
struct VistaApp: App {
    @StateObject private var screenshotManager = ScreenshotManager()
    @StateObject private var keyboardManager: KeyboardShortcutManager

    init() {
        // Register all default settings at launch
        _ = DefaultSettings.shared

        let manager = ScreenshotManager()
        _keyboardManager = StateObject(
            wrappedValue: KeyboardShortcutManager(screenshotManager: manager)
        )
        _screenshotManager = StateObject(wrappedValue: manager)
    }

    var body: some Scene {
        MenuBarExtra("vista", image: "MenuBarIcon") {
            MenuBarView(
                screenshotManager: screenshotManager,
                keyboardManager: keyboardManager)
        }
    }
}
