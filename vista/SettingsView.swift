import SwiftUI

class SettingsWindow {
    static let shared = SettingsWindow()
    private var window: NSWindow?

    func show() {
        if window == nil {
            window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 375, height: 300),
                styleMask: [.titled, .closable],
                backing: .buffered,
                defer: false
            )

            window?.title = "Settings"
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
                    Label("General", systemImage: "switch.on.square.fill")
                }
                .tag(0)

            ShortcutSettingsView()
                .tabItem {
                    Label("Shortcuts", systemImage: "command.square.fill")
                }
                .tag(1)

            AboutView()
                .tabItem {
                    Label("About", systemImage: "v.square.fill")
                }
                .tag(2)
        }
        .tabViewStyle(.automatic)
        .padding()
        .frame(width: 375, height: 300)
    }
}

struct GeneralSettingsView: View {
    @AppStorage("launchAtLogin") private var launchAtLogin = false
    @AppStorage("disableStatusPopup") private var disableStatusPopup = false

    var body: some View {
        Form {
            HStack {
                Image(systemName: "gearshape.fill")
                Text("Launch at login")
                Spacer()
                Toggle("", isOn: $launchAtLogin)
            }
            
            HStack {
                Image(systemName: "bell.fill")
                Text("Disable status popup")
                Spacer()
                Toggle("", isOn: $disableStatusPopup)
            }
        }
        .formStyle(.grouped)
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

struct AboutView: View {
    var body: some View {
        VStack {
            Text("About content here")
        }
    }
}

#Preview {
    SettingsContainerView()
}
