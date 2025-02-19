import AppKit
import SwiftUI

class StatusWindowController {
    private var window: NSWindow?

    func show(withStatus status: ProcessingStatus) {
        @AppStorage("popupEnabled") var popupEnabled = true
        guard popupEnabled else { return }

        if window == nil {
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
        }

        let statusView = NSHostingController(
            rootView: StatusWindowView(status: status)
                .frame(width: 100, height: 100)
        )

        window?.contentViewController = statusView

        if let screen = NSScreen.main {
            let rect = screen.frame
            let point = NSPoint(
                x: rect.midX - 50,
                y: rect.midY - 50
            )
            window?.setFrameOrigin(point)
        }

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.2
            window?.animator().alphaValue = 1
        }
        window?.orderFront(nil)

        switch status {
        case .success:
            autoHide(after: 1.0)
        case .error:
            autoHide(after: 2.0)
        default:
            break
        }
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
            statusIcon
                .font(.system(size: 32))
                .symbolEffect(.bounce, value: status)
        }
        .frame(width: 100, height: 100)
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.2), radius: 4, y: 2)
        }
        .transition(.opacity)
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
                    .foregroundStyle(.secondary)
            case .success:
                Image(systemName: "doc.on.clipboard")
                    .foregroundStyle(.secondary)
            case .error:
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.red)
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
        StatusWindowView(status: .error("Error"))
    }
}
