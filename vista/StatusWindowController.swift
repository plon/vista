import AppKit
import SwiftUI

class StatusWindowController {
    private var window: NSWindow?
    private var statusView: NSHostingController<StatusWindowView>?

    func show(withStatus status: ProcessingStatus) {

        if case .error(let message) = status {
            print("Status Window Error: \(message)")
        }
        if window == nil {
            // Create the window
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 200, height: 100),
                styleMask: [.borderless],
                backing: .buffered,
                defer: false
            )

            // Configure window properties
            window.backgroundColor = .clear
            window.isOpaque = false
            window.hasShadow = true
            window.level = .statusBar  // Change to make it float above other windows
            window.isReleasedWhenClosed = false
            window.ignoresMouseEvents = true  // Make it non-interactive

            self.window = window
        }

        // Create or update the status view
        let statusView = NSHostingController(
            rootView: StatusWindowView(status: status)
        )

        window?.contentViewController = statusView
        self.statusView = statusView

        // Position window in center of main screen
        if let screen = NSScreen.main {
            let rect = screen.frame
            let x = rect.midX - 100
            let y = rect.midY - 50
            window?.setFrameOrigin(NSPoint(x: x, y: y))
        }

        window?.orderFront(nil)

        // Auto-hide after delay for success/error states
        if case .success = status {
            autoHide(after: 2.0)
        } else if case .error = status {
            autoHide(after: 3.0)
        }
    }

    func hide() {
        window?.orderOut(nil)
    }

    private func autoHide(after seconds: TimeInterval) {
        DispatchQueue.main.asyncAfter(deadline: .now() + seconds) { [weak self] in
            self?.hide()
        }
    }
}

// Wrapper view that combines StatusOverlay with visual effects
struct StatusWindowView: View {
    let status: ProcessingStatus

    var body: some View {
        StatusOverlay(status: .constant(status))
            .frame(width: 300, height: 120)  // Made larger to accommodate error messages
            .background(VisualEffectView())
    }
}

// Visual effect view for blur background
struct VisualEffectView: NSViewRepresentable {
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.blendingMode = .behindWindow
        view.state = .active
        view.material = .hudWindow
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {}
}
