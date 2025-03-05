import KeyboardShortcuts
import SwiftUI

class SettingsWindow {
    static let shared = SettingsWindow()
    private var windowController: NSWindowController?
    private var initialTab: String = "General"

    func show(keyboardManager: KeyboardShortcutManager) {
        if windowController == nil {
            let window = createWindow()
            setupWindowContent(window: window, keyboardManager: keyboardManager)

            windowController = NSWindowController(window: window)
        } else if let window = windowController?.window {
            setupWindowContent(window: window, keyboardManager: keyboardManager)
        }

        windowController?.window?.center()
        windowController?.showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func createWindow() -> NSWindow {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 815, height: 615),
            styleMask: [.titled, .closable, .miniaturizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        window.titlebarAppearsTransparent = true
        window.title = initialTab
        window.toolbarStyle = .unified
        window.isReleasedWhenClosed = true

        return window
    }

    private func setupWindowContent(window: NSWindow, keyboardManager: KeyboardShortcutManager) {
        let visualEffectView = NSVisualEffectView()
        visualEffectView.material = .sidebar
        visualEffectView.state = .active
        visualEffectView.blendingMode = .behindWindow
        visualEffectView.appearance = nil  // follow system appearance

        let hostingView = NSHostingView(
            rootView:
                SettingsContainerView(keyboardManager: keyboardManager) { newTitle in
                    window.title = newTitle
                }
        )

        visualEffectView.frame = window.contentView!.bounds
        visualEffectView.autoresizingMask = [.width, .height]

        // Remove old views if they exist
        window.contentView?.subviews.forEach { $0.removeFromSuperview() }

        window.contentView?.addSubview(visualEffectView)

        hostingView.frame = window.contentView!.bounds
        hostingView.autoresizingMask = [.width, .height]
        window.contentView?.addSubview(hostingView)
    }

    func cleanup() {
        windowController?.close()
        windowController = nil
    }

    deinit {
        cleanup()
    }
}

struct CustomSidebarLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.icon
                .font(.system(size: 18))
                .imageScale(.large)
                .accessibility(hidden: true)
            configuration.title
                .font(.system(size: 13))
        }
        .accessibilityElement(children: .combine)
    }
}

struct SettingsContainerView: View {
    @ObservedObject var keyboardManager: KeyboardShortcutManager
    @State private var selectedTab: String = "General"
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
                    .accessibilityLabel("General settings")

                Label("Output", systemImage: "square.and.pencil.circle.fill")
                    .symbolRenderingMode(.hierarchical)
                    .tag("Output")
                    .labelStyle(CustomSidebarLabelStyle())
                    .accessibilityLabel("Output settings")

                Label("Shortcuts", systemImage: "command.circle.fill")
                    .symbolRenderingMode(.hierarchical)
                    .tag("Shortcuts")
                    .labelStyle(CustomSidebarLabelStyle())
                    .accessibilityLabel("Keyboard shortcuts settings")
            }
            .toolbar(removing: .sidebarToggle)
            .listStyle(.sidebar)
            .frame(width: 200)
            .onChange(of: selectedTab) { newTab in
                onTitleChange(newTab)
            }
        } detail: {
            Group {
                switch selectedTab {
                case "General":
                    GeneralSettingsView()
                case "Output":
                    OutputSettingsView()
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
    @AppStorage("displayTarget") private var displayTarget = "screenshot"
    @AppStorage("popupSize") private var popupSize = StatusPopupSize.normal.rawValue
    @AppStorage("hapticFeedbackEnabled") private var hapticFeedbackEnabled = true
    @State private var launchAtLogin: Bool = LaunchAtLoginManager.shared.isEnabled()

    var body: some View {
        Form {
            Section {
                Toggle("Launch at login", isOn: $launchAtLogin)
                    .accessibilityLabel("Launch at login")
                    .accessibilityHint("Open Vista automatically when you log in")
                    .onChange(of: launchAtLogin) { newValue in
                        LaunchAtLoginManager.shared.setEnabled(newValue)
                    }

                Toggle("Show status popup", isOn: $popupEnabled)
                    .accessibilityLabel("Toggle status popup visibility")
                    .accessibilityHint(
                        "When enabled, a status popup will be shown during screenshot processing")

                Picker("Popup size:", selection: $popupSize) {
                    Text("Normal").tag(StatusPopupSize.normal.rawValue)
                    Text("Large").tag(StatusPopupSize.large.rawValue)
                }
                .accessibilityLabel("Status popup size")
                .accessibilityHint("Choose between normal and large popup size")

                HStack(spacing: 8) {
                    Button {
                        displayTarget = "screenshot"
                    } label: {
                        DisplayTargetOptionView(
                            title: "Show on screenshot display",
                            iconName: "rectangle.inset.filled.on.rectangle",
                            isSelected: displayTarget == "screenshot"
                        )
                    }
                    .accessibilityLabel("Show on screenshot display")
                    .accessibilityHint(
                        "Display status on the screen where the screenshot was taken"
                    )
                    .accessibilityAddTraits(displayTarget == "screenshot" ? .isSelected : [])
                    .buttonStyle(.plain)

                    Button {
                        displayTarget = "main"
                    } label: {
                        DisplayTargetOptionView(
                            title: "Show on main screen",
                            iconName: "desktopcomputer.and.macbook",
                            isSelected: displayTarget == "main"
                        )
                    }
                    .accessibilityLabel("Show on main screen")
                    .accessibilityHint("Display status on the main screen, which may be external")
                    .accessibilityAddTraits(displayTarget == "main" ? .isSelected : [])
                    .buttonStyle(.plain)
                }
            } header: {
                Text("System")
                    .foregroundStyle(.secondary)
                    .accessibilityAddTraits(.isHeader)
            }

            Section {
                Toggle("Enable haptic feedback", isOn: $hapticFeedbackEnabled)
                    .accessibilityLabel("Toggle haptic feedback")
                    .accessibilityHint(
                        "When enabled, your Mac will give haptic feedback when processing starts and completes"
                    )
            } header: {
                Text("Behavior")
                    .foregroundStyle(.secondary)
                    .accessibilityAddTraits(.isHeader)
            }
        }
        .formStyle(.grouped)
        .padding(.top, -20)
        .padding(.horizontal, -10)
        .onAppear {
            // Refresh the state when the view appears
            launchAtLogin = LaunchAtLoginManager.shared.isEnabled()
        }
    }
}

struct DisplayTargetOptionView: View {
    let title: String
    let iconName: String
    let isSelected: Bool

    var body: some View {
        VStack {
            Image(systemName: iconName)
                .font(.system(size: 24))
                .frame(height: 24)
                .foregroundColor(isSelected ? .accentColor : .primary)

            Text(title)
                .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Color(NSColor.controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(
                    isSelected ? Color.accentColor : Color.gray.opacity(0.3),
                    lineWidth: isSelected ? 2 : 1)
        )
        .animation(.easeInOut(duration: 0.15), value: isSelected)
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
                    .accessibilityLabel("Toggle keyboard shortcut")
                    .accessibilityHint(
                        "When enabled, you can use keyboard shortcuts to take screenshots")

                if shortcutEnabled {
                    KeyboardShortcuts.Recorder("Screenshot shortcut:", name: .takeScreenshot)
                        .disabled(!shortcutEnabled)
                        .accessibilityLabel("Screenshot keyboard shortcut recorder")
                        .accessibilityHint(
                            "Press keys to set the keyboard shortcut for taking screenshots")
                }
            } header: {
                Text("Keyboard Shortcut")
                    .foregroundStyle(.secondary)
                    .accessibilityAddTraits(.isHeader)
            }
        }
        .formStyle(.grouped)
        .padding(.top, -20)
        .padding(.horizontal, -10)
    }
}
