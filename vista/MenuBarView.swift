import SwiftUI

struct MenuBarView: View {
    @AppStorage("shortcutEnabled") private var shortcutEnabled = true
    @AppStorage("selectedModel") private var selectedModel = GeminiModel.flash
    @ObservedObject var screenshotManager: ScreenshotManager
    @ObservedObject var keyboardManager: KeyboardShortcutManager

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
                ForEach(Array(GeminiModel.allCases.enumerated()), id: \.element) { index, model in
                    if index > 0 {
                        Divider()
                    }
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
                SettingsWindow.shared.show(keyboardManager: keyboardManager)
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
