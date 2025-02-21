import SwiftUI
import KeyboardShortcuts

class SettingsWindow {
    static let shared = SettingsWindow()
    private var windowController: NSWindowController?
    private var toolbar: NSToolbar?
    private var keyboardManager: KeyboardShortcutManager?

    func show(keyboardManager: KeyboardShortcutManager) {
        self.keyboardManager = keyboardManager
        
        if windowController == nil {
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 780, height: 460),
                styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
                backing: .buffered,
                defer: false
            )

            // Configure toolbar
            toolbar = NSToolbar(identifier: "SettingsToolbar")
            toolbar?.displayMode = .iconOnly
            toolbar?.showsBaselineSeparator = false
            toolbar?.allowsUserCustomization = false
            toolbar?.autosavesConfiguration = false
            window.toolbar = toolbar

            window.titlebarAppearsTransparent = true
            window.title = ""  // Clear default title
            window.toolbarStyle = .unified
            window.contentView = NSHostingView(rootView: SettingsContainerView(keyboardManager: keyboardManager))
            window.isReleasedWhenClosed = false
            window.center()  // Center the window on the active screen

            windowController = NSWindowController(window: window)
        } else if let window = windowController?.window {
            window.contentView = NSHostingView(rootView: SettingsContainerView(keyboardManager: keyboardManager))
        }

        windowController?.window?.center()  // Ensure window is centered even when reshown
        windowController?.showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}

struct CustomSidebarLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.icon
                .imageScale(.large)
            configuration.title
                .font(.system(size: 13))
        }
    }
}

struct SettingsContainerView: View {
    @State private var selectedTab = "General"
    @ObservedObject var keyboardManager: KeyboardShortcutManager

    var body: some View {
        NavigationSplitView(columnVisibility: .constant(.all)) {
            List(selection: $selectedTab) {
                Label("General", systemImage: "square.text.square.fill")
                    .tag("General")
                    .labelStyle(CustomSidebarLabelStyle())
                Label("Shortcuts", systemImage: "command.square.fill")
                    .tag("Shortcuts")
                    .labelStyle(CustomSidebarLabelStyle())
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
                    ShortcutSettingsView(keyboardManager: keyboardManager)
                default:
                    EmptyView()
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigation) {
                    Text(selectedTab)
                        .font(.system(size: 17, weight: .regular))
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
            } header: {
                Text("System")
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .padding(.top, -20)
        .padding(.horizontal, -10)
    } 
}

struct ShortcutSettingsView: View {
    @AppStorage("shortcutEnabled") private var shortcutEnabled = true
    @ObservedObject var keyboardManager: KeyboardShortcutManager
    
    init(keyboardManager: KeyboardShortcutManager) {
        self.keyboardManager = keyboardManager
    }

    var body: some View {
        Form {
            Section {
                Toggle("Enable keyboard shortcut", isOn: $shortcutEnabled)
                
                if shortcutEnabled {
                    KeyboardShortcuts.Recorder("Screenshot shortcut:", name: .takeScreenshot)
                        .disabled(!shortcutEnabled)
                }
            } header: {
                Text("Keyboard Shortcut")
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .padding(.top, -20)
        .padding(.horizontal, -10)
    }
}

#Preview {
    SettingsContainerView(keyboardManager: KeyboardShortcutManager(screenshotManager: ScreenshotManager()))
}
