import Carbon
import Foundation
import SwiftUI

class KeyboardShortcutManager: ObservableObject {
    private var eventHandler: EventHandlerRef?
    private let screenshotManager: ScreenshotManager

    init(screenshotManager: ScreenshotManager) {
        self.screenshotManager = screenshotManager
        registerShortcut()
    }

    deinit {
        if let handler = eventHandler {
            RemoveEventHandler(handler)
        }
    }

    private func registerShortcut() {
        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: OSType(kEventHotKeyPressed)
        )

        // Install handler
        InstallEventHandler(
            GetApplicationEventTarget(),
            { (_, event, userData) -> OSStatus in
                guard let userData = userData else { return OSStatus(eventNotHandledErr) }
                let manager = Unmanaged<KeyboardShortcutManager>.fromOpaque(userData)
                    .takeUnretainedValue()
                return manager.handleKeyboardEvent(event)
            },
            1,
            &eventType,
            Unmanaged.passUnretained(self).toOpaque(),
            &eventHandler
        )

        // Register hot key (Command + Shift + 2)
        var hotKeyID = EventHotKeyID(signature: OSType("vtsa".fourCharCodeValue), id: 1)
        var hotKeyRef: EventHotKeyRef?

        RegisterEventHotKey(
            UInt32(kVK_ANSI_2),
            UInt32(cmdKey | shiftKey),
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )
    }

    private func handleKeyboardEvent(_ event: EventRef?) -> OSStatus {
        var hotKeyID = EventHotKeyID()
        let error = GetEventParameter(
            event,
            EventParamName(kEventParamDirectObject),
            EventParamType(typeEventHotKeyID),
            nil,
            MemoryLayout<EventHotKeyID>.size,
            nil,
            &hotKeyID
        )

        if error == noErr && hotKeyID.signature == OSType("vtsa".fourCharCodeValue)
            && hotKeyID.id == 1
        {
            DispatchQueue.main.async {
                self.screenshotManager.initiateScreenshot()
            }
        }

        return noErr
    }
}

// Extension to convert string to four char code
extension String {
    var fourCharCodeValue: UInt32 {
        var result: UInt32 = 0
        let chars = utf8.prefix(4)
        for char in chars {
            result = result << 8 + UInt32(char)
        }
        return result
    }
}
