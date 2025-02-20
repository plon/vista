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
        setupShortcut()
        
        // Observe changes to shortcutEnabled setting
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(shortcutSettingChanged),
            name: UserDefaults.didChangeNotification,
            object: nil
        )
    }
    
    private func setupShortcut() {
        if shortcutEnabled {
            KeyboardShortcuts.onKeyUp(for: .takeScreenshot) { [weak self] in
                self?.screenshotManager.initiateScreenshot()
            }
        } else {
            KeyboardShortcuts.disable(.takeScreenshot)
        }
    }
    
    @objc private func shortcutSettingChanged() {
        setupShortcut()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
