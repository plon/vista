import SwiftUI
import KeyboardShortcuts

extension KeyboardShortcuts.Name {
    static let takeScreenshot = Self("takeScreenshot", default: .init(.two, modifiers: [.command, .shift]))
}

class KeyboardShortcutManager: ObservableObject {
    private let screenshotManager: ScreenshotManager
    
    init(screenshotManager: ScreenshotManager) {
        self.screenshotManager = screenshotManager
        setupShortcut()
    }
    
    private func setupShortcut() {
        KeyboardShortcuts.onKeyUp(for: .takeScreenshot) { [weak self] in
            self?.screenshotManager.initiateScreenshot()
        }
    }
}
