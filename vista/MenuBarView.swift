import SwiftUI

struct MenuBarView: View {
    @AppStorage("shortcutEnabled") private var shortcutEnabled = true
    @AppStorage("selectedModel") private var selectedModel = GeminiModel.flash
    @StateObject private var screenshotManager = ScreenshotManager()
    @StateObject private var keyboardManager: KeyboardShortcutManager

    init() {
        let manager = ScreenshotManager()
        _keyboardManager = StateObject(
            wrappedValue: KeyboardShortcutManager(screenshotManager: manager))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button {
                screenshotManager.initiateScreenshot()
            } label: {
                Label("Take Screenshot", systemImage: "camera.fill")
            }
            .labelStyle(.titleAndIcon)
            .keyboardShortcut("2", modifiers: [.command, .shift])

            Divider()

            Text("Configure:")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Picker(selection: $selectedModel) {
                ForEach(GeminiModel.allCases, id: \.self) { model in
                    Label(model.displayName, systemImage: model.iconName)
                        .tag(model)
                }
            } label: {
                Label("Vision Model", systemImage: "sparkles")
            }
            .labelStyle(.titleAndIcon)
            .onChange(of: selectedModel) { _ in
                screenshotManager.updateModel(selectedModel)
            }

            Divider()

            Text("Version: 0.1.0-alpha")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Button("Settings...") {
                SettingsWindow.shared.show()
            }
            .keyboardShortcut(",", modifiers: .command)

            Divider()

            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q", modifiers: .command)
        }
        .padding()
        .frame(width: 300)
    }
}
