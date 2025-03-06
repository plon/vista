import SwiftUI

struct MenuBarView: View {
    @AppStorage("shortcutEnabled") private var shortcutEnabled = true
    @AppStorage("selectedModelType") private var selectedModelType = OCRModelType.default
    @ObservedObject var screenshotManager: ScreenshotManager
    @ObservedObject var keyboardManager: KeyboardShortcutManager

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Conditional button based on processing state
            if screenshotManager.isProcessing {
                Button {
                    screenshotManager.cancelProcessing()
                } label: {
                    Label("Cancel Processing", systemImage: "xmark.circle.fill")
                        .foregroundColor(.red)
                }
                .labelStyle(.titleAndIcon)
                .keyboardShortcut(.escape, modifiers: [])
            } else {
                Button {
                    screenshotManager.initiateScreenshot()
                } label: {
                    Label("Take Screenshot", systemImage: "camera.fill")
                }
                .labelStyle(.titleAndIcon)
                .keyboardShortcut("2", modifiers: [.command, .shift])
            }

            Divider()

            Text("Configure:")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Picker(selection: $selectedModelType) {
                ForEach(Array(OCRModelType.allCases.enumerated()), id: \.element) { index, model in
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
            .onChange(of: selectedModelType) { _ in
                screenshotManager.updateModel(selectedModelType)
            }

            Divider()

            Text("Version: 0.1.0-alpha")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Button("Settings...") {
                SettingsWindow.shared.show(keyboardManager: keyboardManager, screenshotManager: screenshotManager)
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
