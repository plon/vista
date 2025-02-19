import SwiftUI

struct MenuBarView: View {
    @AppStorage("selectedModel") private var selectedModel = GeminiModel.flash
    @StateObject private var screenshotManager = ScreenshotManager()
    @StateObject private var keyboardManager: KeyboardShortcutManager

    init() {
        // Create manager first without StateObject wrapper
        let manager = ScreenshotManager()
        // Then initialize keyboardManager with that instance
        _keyboardManager = StateObject(
            wrappedValue: KeyboardShortcutManager(screenshotManager: manager))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button("Take Screenshot (⌘⇧2)") {
                screenshotManager.initiateScreenshot()
            }

            Divider()

            Picker("Model", selection: $selectedModel) {
                ForEach(GeminiModel.allCases, id: \.self) { model in
                    Text(model.displayName).tag(model)
                }
            }
            .onChange(of: selectedModel) { _ in
                // Update the model in screenshotManager
                screenshotManager.updateModel(selectedModel)
            }

            Divider()

            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
        }
        .padding()
        .frame(width: 300)
    }
}

#Preview {
    MenuBarView()
}
