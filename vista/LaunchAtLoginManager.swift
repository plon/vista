import Foundation
import ServiceManagement

class LaunchAtLoginManager {
    static let shared = LaunchAtLoginManager()

    private let loginItemIdentifier = "com.plon.vista.LaunchHelper"

    func isEnabled() -> Bool {
        if #available(macOS 13.0, *) {
            return SMAppService.mainApp.status == .enabled
        } else {
            return UserDefaults.standard.bool(forKey: "launchAtLogin")
        }
    }

    func setEnabled(_ enabled: Bool) {
        if #available(macOS 13.0, *) {
            let service = SMAppService.mainApp
            do {
                if enabled {
                    if service.status != .enabled {
                        try service.register()
                    }
                } else {
                    if service.status == .enabled {
                        try service.unregister()
                    }
                }
                // Cache the setting
                UserDefaults.standard.set(enabled, forKey: "launchAtLogin")
            } catch {
                print("Failed to \(enabled ? "register" : "unregister") launch at login: \(error)")
            }
        } else {
            // For macOS 12 and earlier store the setting in UserDefaults
            UserDefaults.standard.set(enabled, forKey: "launchAtLogin")
        }
    }
}
