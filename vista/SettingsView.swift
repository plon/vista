import SwiftUI

class SettingsWindow {
    static let shared = SettingsWindow()
    private var windowController: NSWindowController?

    func show() {
        if windowController == nil {
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 780, height: 460),
                styleMask: [.titled, .closable, .miniaturizable, .fullSizeContentView],
                backing: .buffered,
                defer: false
            )
            
            window.titlebarAppearsTransparent = true
            window.title = ""  // Clear default title
            window.toolbarStyle = .unified
            window.contentView = NSHostingView(rootView: SettingsContainerView())
            window.isReleasedWhenClosed = false
            window.center() // Center the window on the active screen
            
            windowController = NSWindowController(window: window)
        }

        windowController?.window?.center() // Ensure window is centered even when reshown
        windowController?.showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}

struct SettingsContainerView: View {
    @State private var selectedTab = "General"
    
    var body: some View {
        NavigationSplitView(columnVisibility: .constant(.all)) {
            List(selection: $selectedTab) {
                Label("General", systemImage: "gear")
                    .tag("General")
                Label("Shortcuts", systemImage: "keyboard")
                    .tag("Shortcuts")
            }
            .toolbar(removing: .sidebarToggle)
            .listStyle(.sidebar)
            .frame(width: 200)
        } detail: {
            Group {
                switch selectedTab {
                case "General":
                    GeneralSettingsView()
                case "Shortcuts":
                    ShortcutSettingsView()
                default:
                    EmptyView()
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigation) {
                    Text(selectedTab)
                        .font(.system(size: 20, weight: .regular))
                }
            }
            .frame(maxHeight: .infinity, alignment: .top)
            .navigationSplitViewColumnWidth(min: 440, ideal: 440)
        }
    }
}

struct GeneralSettingsView: View {
    @AppStorage("popupEnabled") private var popupEnabled = true

    var body: some View {
        Form {
            Section {
                Toggle("Show status popup", isOn: $popupEnabled)
            }
        }
        .formStyle(.grouped)
        .padding(.top, -20)
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
