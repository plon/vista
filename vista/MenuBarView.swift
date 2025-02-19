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
                Text("Take Screenshot")
            }
            .keyboardShortcut("2", modifiers: [.command, .shift])

            Divider()

            Picker("Vision Model", selection: $selectedModel) {
                ForEach(GeminiModel.allCases, id: \.self) { model in
                    Text(model.displayName).tag(model)
                }
            }
            .onChange(of: selectedModel) { _ in
                screenshotManager.updateModel(selectedModel)
            }

            Divider()

            Button("Settings...") {
                SettingsWindow.shared.show()
            }
            .keyboardShortcut(",", modifiers: .command)

            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q", modifiers: .command)
        }
        .padding()
        .frame(width: 300)
    }
}
