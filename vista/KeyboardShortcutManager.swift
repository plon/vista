import SwiftUI
import KeyboardShortcuts

extension KeyboardShortcuts.Name {
    static let takeScreenshot = Self("takeScreenshot", default: .init(.two, modifiers: [.command, .shift]))
}

class KeyboardShortcutManager: ObservableObject {
    private let screenshotManager: ScreenshotManager
    @AppStorage("shortcutEnabled") private var shortcutEnabled = true

    init(screenshotManager: ScreenshotManager) {
        self.screenshotManager = screenshotManager
        
        // Register the callback only once.
        KeyboardShortcuts.onKeyUp(for: .takeScreenshot) { [weak self] in
            // Only proceed if the shortcut is enabled.
            guard self?.shortcutEnabled == true else { return }
            self?.screenshotManager.initiateScreenshot()
        }
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(shortcutSettingChanged),
            name: UserDefaults.didChangeNotification,
            object: nil
        )
    }
    
    @objc private func shortcutSettingChanged() {

    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
