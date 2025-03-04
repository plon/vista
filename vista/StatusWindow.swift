import AppKit
import SwiftUI

enum StatusPopupSize: String, CaseIterable {
    case normal = "normal"
    case large = "large"

    var dimensions: (width: CGFloat, height: CGFloat) {
        switch self {
        case .normal:
            return (100, 100)
        case .large:
            return (160, 160)
        }
    }

    var iconSize: CGFloat {
        switch self {
        case .normal: return 32
        case .large: return 48
        }
    }

    var fontSize: CGFloat {
        switch self {
        case .normal: return 12
        case .large: return 14
        }
    }

    var cornerRadius: CGFloat {
        switch self {
        case .normal: return 13
        case .large: return 16
        }
    }

    var verticalSpacing: CGFloat {
        switch self {
        case .normal: return 8
        case .large: return 12
        }
    }
}

class StatusWindowController {
    private var window: NSWindow?
    @AppStorage("popupEnabled") private var popupEnabled = true
    @AppStorage("displayTarget") private var displayTarget = "screenshot"
    @AppStorage("popupSize") private var popupSize = StatusPopupSize.normal.rawValue
    private var lastActiveScreen: NSScreen?

    func setActiveScreen(_ screen: NSScreen?) {
        self.lastActiveScreen = screen
    }

    func show(withStatus status: ProcessingStatus, onCancel: (() -> Void)? = nil) {
        guard popupEnabled else { return }

        if window == nil {
            setupWindow()
        }

        // Get the current popup size
        let size = StatusPopupSize(rawValue: popupSize) ?? .normal
        let windowWidth = size.dimensions.width
        let windowHeight = size.dimensions.height

        let statusView = NSHostingController(
            rootView: StatusWindowView(status: status, size: size)
                .frame(width: windowWidth, height: windowHeight)
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
        let screenFrame = targetScreen.frame
        let screenVisibleFrame = targetScreen.visibleFrame

        let xPosition = screenFrame.origin.x + (screenFrame.width - windowWidth) / 2
        let yPosition = screenVisibleFrame.origin.y + screenVisibleFrame.height * 0.25

        window?.setFrame(
            NSRect(x: xPosition, y: yPosition, width: windowWidth, height: windowHeight),
            display: true)

        // Always ignore mouse events for a standard macOS status popup
        window?.ignoresMouseEvents = true

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
            let duration: TimeInterval = 2.0
            autoHide(after: duration)
        default:
            break
        }
    }

    private func setupWindow() {
        let size = StatusPopupSize(rawValue: popupSize) ?? .normal
        let windowWidth = size.dimensions.width
        let windowHeight = size.dimensions.height

        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: windowWidth, height: windowHeight),
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
    let size: StatusPopupSize

    init(status: ProcessingStatus, size: StatusPopupSize = .normal) {
        self.status = status
        self.size = size
    }

    var body: some View {
        StatusOverlay(status: status, size: size)
    }
}

private struct StatusOverlay: View {
    let status: ProcessingStatus
    let size: StatusPopupSize
    @State private var isAnimating = false

    var body: some View {
        ZStack {
            VStack(spacing: size.verticalSpacing) {
                statusIcon
                    .font(.system(size: size.iconSize))
                    .foregroundStyle(.white)

                if let message = statusMessage {
                    Text(message)
                        .font(.system(size: size.fontSize, weight: .medium))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(width: size.dimensions.width, height: size.dimensions.height)
        .background {
            RoundedRectangle(cornerRadius: size.cornerRadius)
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
