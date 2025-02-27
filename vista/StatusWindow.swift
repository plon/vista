import AppKit
import SwiftUI

class StatusWindowController {
    private var window: NSWindow?
    @AppStorage("popupEnabled") private var popupEnabled = true
    @AppStorage("displayTarget") private var displayTarget = "screenshot"
    private var lastActiveScreen: NSScreen?

    func setActiveScreen(_ screen: NSScreen?) {
        self.lastActiveScreen = screen
    }

    func show(withStatus status: ProcessingStatus) {
        guard popupEnabled else { return }

        if window == nil {
            setupWindow()
        }

        let statusView = NSHostingController(
            rootView: StatusWindowView(status: status)
                .frame(width: 100, height: 100)
        )

        window?.contentViewController = statusView

        // Determine which screen to use
        let targetScreen: NSScreen
        if displayTarget == "screenshot", let activeScreen = lastActiveScreen {
            targetScreen = activeScreen
        } else {
            targetScreen = NSScreen.main ?? NSScreen.screens.first!
        }

        // Calculate position in the lower quarter of the target screen
        // Important: In macOS, screen coordinates are flipped - (0,0) is at bottom left
        // And the frame origin is in global coordinates
        let windowWidth: CGFloat = 100
        let windowHeight: CGFloat = 100

        let screenFrame = targetScreen.frame
        let screenVisibleFrame = targetScreen.visibleFrame

        let xPosition = screenFrame.origin.x + (screenFrame.width - windowWidth) / 2
        // Position 25% up from bottom of visible area
        let yPosition = screenVisibleFrame.origin.y + screenVisibleFrame.height * 0.25

        window?.setFrameOrigin(NSPoint(x: xPosition, y: yPosition))

        window?.orderFront(nil)

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.2
            window?.animator().alphaValue = 1
        }

        switch status {
        case .success:
            autoHide(after: 1.0)
        case .cancelled:
            autoHide(after: 1.0)
        case .error(let message):
            print("Error occurred: \(message)")
            let duration = message.contains("No text detected") ? 2.0 : 2.0
            autoHide(after: duration)
        default:
            break
        }
    }

    private func setupWindow() {
        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 100, height: 100),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )

        window?.backgroundColor = .clear
        window?.isOpaque = false
        window?.hasShadow = false
        window?.level = .statusBar
        window?.isReleasedWhenClosed = false
        window?.ignoresMouseEvents = true
        window?.collectionBehavior = [.transient, .ignoresCycle]
        window?.alphaValue = 0
    }

    func hide() {
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.2
            window?.animator().alphaValue = 0
        } completionHandler: {
            self.window?.orderOut(nil)
        }
    }

    private func autoHide(after seconds: TimeInterval) {
        DispatchQueue.main.asyncAfter(deadline: .now() + seconds) { [weak self] in
            self?.hide()
        }
    }
}

private struct StatusWindowView: View {
    let status: ProcessingStatus

    var body: some View {
        StatusOverlay(status: status)
    }
}

private struct StatusOverlay: View {
    let status: ProcessingStatus
    @State private var isAnimating = false

    var body: some View {
        ZStack {
            VStack(spacing: 8) {
                statusIcon
                    .font(.system(size: 32))
                    .foregroundStyle(.white)

                if let message = statusMessage {
                    Text(message)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(width: 100, height: 100)
        .background {
            RoundedRectangle(cornerRadius: 13)
                .fill(.regularMaterial)
        }
    }

    private var statusMessage: String? {
        switch status {
        case .error(let message):
            return message
        case .processing:
            return "Processing"
        case .success:
            return "Copied"
        case .cancelled:
            return "Cancelled"
        case .none:
            return nil
        }
    }

    private var statusIcon: some View {
        Group {
            switch status {
            case .processing:
                Image(systemName: "arrow.triangle.2.circlepath")
                    .rotationEffect(.degrees(isAnimating ? 360 : 0))
                    .onAppear {
                        withAnimation(
                            .linear(duration: 1)
                                .repeatForever(autoreverses: false)
                        ) {
                            isAnimating = true
                        }
                    }
            case .success:
                Image(systemName: "doc.on.clipboard")
            case .cancelled:
                Image(systemName: "xmark")
                    .foregroundStyle(.secondary)
            case .error(let message):
                if message.contains("No text detected") {
                    Image(systemName: "text.magnifyingglass")
                        .foregroundStyle(.orange)
                } else {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.red)
                }
            case .none:
                EmptyView()
            }
        }
    }
}

#Preview {
    Group {
        StatusWindowView(status: .processing)
        StatusWindowView(status: .success)
        StatusWindowView(status: .error("Error occurred"))
        StatusWindowView(status: .error("No text detected in image"))
    }
}
