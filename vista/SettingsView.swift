import AppKit
import SwiftUI

class SettingsWindow: NSObject, NSWindowDelegate {
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

            // Add toolbar configuration
            let toolbar = NSToolbar(identifier: "SettingsToolbar")
            toolbar.showsBaselineSeparator = false
            toolbar.allowsUserCustomization = false
            toolbar.autosavesConfiguration = false
            window.toolbar = toolbar

            window.delegate = self
            window.titlebarAppearsTransparent = true
            window.title = ""
            window.toolbarStyle = .unified
            window.contentView = NSHostingView(rootView: SettingsContainerView())
            window.isReleasedWhenClosed = false
            window.center()

            windowController = NSWindowController(window: window)
        }

        windowController?.window?.center()
        windowController?.showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    // MARK: - NSWindowDelegate

    func windowDidBecomeKey(_ notification: Notification) {
        guard let window = notification.object as? NSWindow else { return }

        DispatchQueue.main.async {
            if let contentView = window.contentView,
                let splitView = self.findSplitView(in: contentView),
                let splitViewController = splitView.delegate as? NSSplitViewController
            {
                splitViewController.splitViewItems.first?.isCollapsed = false
                splitViewController.splitViewItems.first?.canCollapse = false
                splitViewController.splitViewItems.first?.holdingPriority = .defaultHigh
                splitViewController.splitViewItems.first?.minimumThickness = 200
                splitViewController.splitViewItems.first?.maximumThickness = 200
            }
        }
    }

    private func findSplitView(in view: NSView) -> NSSplitView? {
        if let splitView = view as? NSSplitView {
            return splitView
        }
        for subview in view.subviews {
            if let found = findSplitView(in: subview) {
                return found
            }
        }
        return nil
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
    @AppStorage("autoStartOnBoot") private var autoStartOnBoot = false
    @AppStorage("showInMenuBar") private var showInMenuBar = true
    @AppStorage("soundEffects") private var soundEffects = true

    var body: some View {
        Form {
            Section {
                Toggle("Show status popup", isOn: $popupEnabled)
                Toggle("Open at login", isOn: $autoStartOnBoot)
                Toggle("Show in Menu Bar", isOn: $showInMenuBar)
                Toggle("Sound effects", isOn: $soundEffects)
            }
        }
        .formStyle(.grouped)
        .padding(.top, -20)
        .padding(.horizontal, -10)
    }
}

struct ShortcutSettingsView: View {
    @AppStorage("shortcutEnabled") private var shortcutEnabled = true

    var body: some View {
        Form {
            Toggle("Enable keyboard shortcut (⌘⇧2)", isOn: $shortcutEnabled)
        }
        .formStyle(.grouped)
        .padding(.top, -20)
        .padding(.horizontal, -10)
    }
}

#Preview {
    SettingsContainerView()
}
