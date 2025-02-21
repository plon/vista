import SwiftUI
import KeyboardShortcuts

class SettingsWindow {
    static let shared = SettingsWindow()
    private var windowController: NSWindowController?
    private var toolbar: NSToolbar?
    private var keyboardManager: KeyboardShortcutManager?
    private var selectedTab: String = "General"

    func show(keyboardManager: KeyboardShortcutManager) {
        self.keyboardManager = keyboardManager
        
        if windowController == nil {
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 670, height: 580),
                styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
                backing: .buffered,
                defer: false
            )

            // Configure toolbar
            toolbar = NSToolbar(identifier: "SettingsToolbar")
            toolbar?.displayMode = .labelOnly
            toolbar?.showsBaselineSeparator = true
            toolbar?.allowsUserCustomization = false
            toolbar?.autosavesConfiguration = false
            window.toolbar = toolbar

            window.titlebarAppearsTransparent = true
            window.title = selectedTab
            window.toolbarStyle = .unified
            
            // Configure window for vibrancy
            window.backgroundColor = .clear
            window.isOpaque = false
            
            // Create visual effect view with automatic appearance
            let visualEffectView = NSVisualEffectView()
            visualEffectView.material = .sidebar
            visualEffectView.state = .active
            visualEffectView.blendingMode = .behindWindow
            visualEffectView.appearance = nil  // follow system appearance
            
            // Create hosting view with title update callback
            let hostingView = NSHostingView(rootView: SettingsContainerView(keyboardManager: keyboardManager) { [weak self] newTitle in
                self?.selectedTab = newTitle
                window.title = newTitle
            })
            
            // Set up view hierarchy
            visualEffectView.frame = window.contentView!.bounds
            visualEffectView.autoresizingMask = [.width, .height]
            window.contentView?.addSubview(visualEffectView)
            
            hostingView.frame = window.contentView!.bounds
            hostingView.autoresizingMask = [.width, .height]
            window.contentView?.addSubview(hostingView)
            
            window.isReleasedWhenClosed = false
            window.center()

            windowController = NSWindowController(window: window)
        } else if let window = windowController?.window {
            // Update content for existing window
            let hostingView = NSHostingView(rootView: SettingsContainerView(keyboardManager: keyboardManager) { [weak self] newTitle in
                self?.selectedTab = newTitle
                window.title = newTitle
            })
            hostingView.frame = window.contentView!.bounds
            hostingView.autoresizingMask = [.width, .height]
            
            // Remove old views and add new ones
            window.contentView?.subviews.forEach { $0.removeFromSuperview() }
            
            let visualEffectView = NSVisualEffectView()
            visualEffectView.material = .sidebar
            visualEffectView.state = .active
            visualEffectView.blendingMode = .behindWindow
            visualEffectView.frame = window.contentView!.bounds
            visualEffectView.autoresizingMask = [.width, .height]
            
            window.contentView?.addSubview(visualEffectView)
            window.contentView?.addSubview(hostingView)
        }

        windowController?.window?.center()
        windowController?.showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}

struct CustomSidebarLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.icon
                .font(.system(size: 18))
                .imageScale(.large)
            configuration.title
                .font(.system(size: 13))
        }
    }
}

struct SettingsContainerView: View {
    @State private var selectedTab = "General"
    @ObservedObject var keyboardManager: KeyboardShortcutManager
    var onTitleChange: (String) -> Void
    
    init(keyboardManager: KeyboardShortcutManager, onTitleChange: @escaping (String) -> Void) {
        self.keyboardManager = keyboardManager
        self.onTitleChange = onTitleChange
    }

    var body: some View {
        NavigationSplitView(columnVisibility: .constant(.all)) {
            List(selection: $selectedTab) {
                Label("General", systemImage: "gearshape.circle.fill")
                    .symbolRenderingMode(.hierarchical)
                    .tag("General")
                    .labelStyle(CustomSidebarLabelStyle())
                Label("Shortcuts", systemImage: "command.circle.fill")
                    .symbolRenderingMode(.hierarchical)
                    .tag("Shortcuts")
                    .labelStyle(CustomSidebarLabelStyle())
            }
            .toolbar(removing: .sidebarToggle)
            .listStyle(.sidebar)
            .frame(width: 200)
            .onChange(of: selectedTab) { newValue in
                onTitleChange(newValue)
            }
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
            .frame(maxHeight: .infinity, alignment: .top)
            .navigationSplitViewColumnWidth(min: 440, ideal: 440)
        }
    }
}

struct GeneralSettingsView: View {
    @AppStorage("popupEnabled") private var popupEnabled = true
    @AppStorage("displayTarget") private var displayTarget = "builtin"

    var body: some View {
        Form {
            Section {
                Toggle("Show status popup", isOn: $popupEnabled)
                
                HStack(spacing: 8) {
                    Button {
                        displayTarget = "builtin"
                    } label: {
                        VStack {
                            Image(systemName: "laptopcomputer")
                                .font(.system(size: 24))
                                .frame(height: 24)
                                .foregroundColor(displayTarget == "builtin" ? .accentColor : .primary)
                            Text("Show on built-in display")
                                .font(.system(size: 13, weight: displayTarget == "builtin" ? .semibold : .regular))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                    }
                    .buttonStyle(.bordered)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(displayTarget == "builtin" ? Color.accentColor : Color.clear, lineWidth: 2)
                    )
                    .animation(.easeInOut(duration: 0.15), value: displayTarget)
                    
                    Button {
                        displayTarget = "main"
                    } label: {
                        VStack {
                            Image(systemName: "desktopcomputer.and.macbook")
                                .font(.system(size: 24))
                                .frame(height: 24)
                                .foregroundColor(displayTarget == "main" ? .accentColor : .primary)
                            Text("Show on main screen")
                                .font(.system(size: 13, weight: displayTarget == "main" ? .semibold : .regular))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                    }
                    .buttonStyle(.bordered)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(displayTarget == "main" ? Color.accentColor : Color.clear, lineWidth: 2)
                    )
                    .animation(.easeInOut(duration: 0.2), value: displayTarget)
                }
            } header: {
                Text("System")
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .padding(.top, -20)
        .padding(.horizontal, -10)
        .background(.clear)
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
        .background(.clear)
    }
}

#Preview {
    SettingsContainerView(keyboardManager: KeyboardShortcutManager(screenshotManager: ScreenshotManager())) { _ in }
}