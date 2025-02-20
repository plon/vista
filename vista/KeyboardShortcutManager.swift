import Carbon
import Foundation
import SwiftUI

class KeyboardShortcutManager: ObservableObject {
    private var eventHandler: EventHandlerRef?
    private var hotKeyRef: EventHotKeyRef?
    private let screenshotManager: ScreenshotManager
    
    @AppStorage("customShortcut") private var customShortcut: Data?
    @AppStorage("shortcutEnabled") private var shortcutEnabled = true {
        didSet {
            DispatchQueue.main.async {
                self.updateShortcutState()
            }
        }
    }
    
    var currentShortcut: KeyboardShortcut? {
        get {
            guard let data = customShortcut else { return defaultShortcut }
            return try? JSONDecoder().decode(KeyboardShortcut.self, from: data)
        }
        set {
            if let newValue = newValue {
                customShortcut = try? JSONEncoder().encode(newValue)
                updateShortcutState()
            } else {
                customShortcut = nil
                updateShortcutState()
            }
        }
    }
    
    private var defaultShortcut: KeyboardShortcut {
        KeyboardShortcut(keyCode: UInt16(kVK_ANSI_2), modifierFlags: UInt32(cmdKey | shiftKey))
    }

    init(screenshotManager: ScreenshotManager) {
        self.screenshotManager = screenshotManager
        setupEventHandler()

        // Force a clean registration on launch
        unregisterHotKey()
        if shortcutEnabled {
            registerHotKey()
        }
    }

    deinit {
        if let handler = eventHandler {
            RemoveEventHandler(handler)
        }
        unregisterHotKey()
    }

    private func setupEventHandler() {
        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: OSType(kEventHotKeyPressed)
        )

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
    }

    private func registerHotKey() {
        // Don't register if shortcuts are disabled
        guard shortcutEnabled else {
            unregisterHotKey()
            return
        }
        
        unregisterHotKey()
        
        let shortcut = currentShortcut ?? defaultShortcut
        var hotKeyID = EventHotKeyID(signature: OSType("vtsa".fourCharCodeValue), id: 1)

        // Use proper Carbon modifier flags format
        let modifiers = shortcut.modifierFlags

        let status = RegisterEventHotKey(
            UInt32(shortcut.keyCode),
            modifiers,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )

        if status != noErr {
            print("Failed to register hot key - Error: \(status)")
            switch status {
            case -9876:  // eventHotKeyExistsErr
                print("Hot key already exists")
                // Try to unregister and register again
                unregisterHotKey()
                let retryStatus = RegisterEventHotKey(
                    UInt32(shortcut.keyCode),
                    modifiers,
                    hotKeyID,
                    GetApplicationEventTarget(),
                    0,
                    &hotKeyRef
                )
                if retryStatus != noErr {
                    print("Failed to register hot key after retry - Error: \(retryStatus)")
                }
            case -9878:  // errInvalidModifiers
                print("Invalid modifier flags")
            case -9868:  // eventInvalidEventParameterErr
                print("Invalid event flags")
            default:
                print("Unknown error")
            }
        } else {
            print("Successfully registered hot key")
        }
    }

    private func unregisterHotKey() {
        if let hotKeyRef = hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
            self.hotKeyRef = nil
        }
    }

    private func updateShortcutState() {
        if shortcutEnabled {
            registerHotKey()
        } else {
            unregisterHotKey()
        }
    }

    private func handleKeyboardEvent(_ event: EventRef?) -> OSStatus {
        // Don't handle events if shortcuts are disabled
        guard shortcutEnabled else {
            return OSStatus(eventNotHandledErr)
        }
        
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
