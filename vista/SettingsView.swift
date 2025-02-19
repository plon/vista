import SwiftUI

class SettingsWindow {
    static let shared = SettingsWindow()
    private var window: NSWindow?

    func show() {
        if window == nil {
            window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 375, height: 200),
                styleMask: [.titled, .closable],
                backing: .buffered,
                defer: false
            )

            window?.title = "Vista Settings"
            window?.contentView = NSHostingView(rootView: SettingsContainerView())
            window?.isReleasedWhenClosed = false
            window?.center()
        }

        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}

struct SettingsContainerView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            GeneralSettingsView()
                .tabItem {
                    Label("General", systemImage: "gear")
                }
                .tag(0)

            ShortcutSettingsView()
                .tabItem {
                    Label("Shortcuts", systemImage: "keyboard")
                }
                .tag(1)
        }
        .padding()
        .frame(width: 375, height: 200)
    }
}

struct GeneralSettingsView: View {
    @AppStorage("popupEnabled") private var popupEnabled = true

    var body: some View {
        Form {
            Toggle("Show status popup", isOn: $popupEnabled)
        }
    }
}

struct ShortcutSettingsView: View {
    @AppStorage("shortcutEnabled") private var shortcutEnabled = true

    var body: some View {
        Form {
            Toggle("Enable keyboard shortcut (⌘⇧2)", isOn: $shortcutEnabled)
        }
    }
}

#Preview {
    SettingsContainerView()
}
