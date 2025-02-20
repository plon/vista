import SwiftUI
import Carbon

struct ShortcutRecorder: View {
    @Binding var shortcut: KeyboardShortcut?
    @State private var isRecording = false
    @State private var displayText = ""
    
    var body: some View {
        Button(action: {
            isRecording = true
            displayText = "Recording..."
        }) {
            Text(displayText.isEmpty ? (shortcut?.displayString ?? "Click to record") : displayText)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color(.textBackgroundColor))
                )
        }
        .buttonStyle(.plain)
        .onAppear {
            if let shortcut = shortcut {
                displayText = shortcut.displayString
            }
        }
        .background(
            ShortcutRecorderRepresentable(
                isRecording: $isRecording,
                shortcut: $shortcut,
                displayText: $displayText
            )
        )
    }
}

struct KeyboardShortcut: Codable, Equatable {
    var keyCode: UInt16
    var modifierFlags: UInt32
    
    var displayString: String {
        var str = ""
        let flags = modifierFlags
        
        if flags & UInt32(cmdKey) != 0 { str += "⌘" }
        if flags & UInt32(shiftKey) != 0 { str += "⇧" }
        if flags & UInt32(optionKey) != 0 { str += "⌥" }
        if flags & UInt32(controlKey) != 0 { str += "⌃" }
        
        str += keyCodeToString(keyCode)
        return str
    }
    
    private func keyCodeToString(_ keyCode: UInt16) -> String {
        let keyMap: [UInt16: String] = [
            0x00: "A", 0x01: "S", 0x02: "D", 0x03: "F", 0x04: "H", 0x05: "G",
            0x06: "Z", 0x07: "X", 0x08: "C", 0x09: "V", 0x0B: "B", 0x0C: "Q",
            0x0D: "W", 0x0E: "E", 0x0F: "R", 0x10: "Y", 0x11: "T", 0x12: "1",
            0x13: "2", 0x14: "3", 0x15: "4", 0x16: "6", 0x17: "5", 0x18: "=",
            0x19: "9", 0x1A: "7", 0x1B: "-", 0x1C: "8", 0x1D: "0", 0x1E: "]",
            0x1F: "O", 0x20: "U", 0x21: "[", 0x22: "I", 0x23: "P", 0x25: "L",
            0x26: "J", 0x27: "'", 0x28: "K", 0x29: ";", 0x2A: "\\", 0x2B: ",",
            0x2C: "/", 0x2D: "N", 0x2E: "M", 0x2F: ".", 0x32: "`",
            0x24: "↩", 0x30: "Tab", 0x31: "Space", 0x33: "⌫", 0x35: "Esc",
            0x7B: "←", 0x7C: "→", 0x7D: "↓", 0x7E: "↑"
        ]
        return keyMap[keyCode] ?? "?"
    }
}

struct ShortcutRecorderRepresentable: NSViewRepresentable {
    @Binding var isRecording: Bool
    @Binding var shortcut: KeyboardShortcut?
    @Binding var displayText: String
    
    func makeNSView(context: Context) -> NSView {
        let view = RecorderView()
        view.delegate = context.coordinator
        return view
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {
        if let view = nsView as? RecorderView {
            view.isRecording = isRecording
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject {
        var parent: ShortcutRecorderRepresentable
        
        init(_ parent: ShortcutRecorderRepresentable) {
            self.parent = parent
        }
        
        func didRecordShortcut(keyCode: UInt16, modifierFlags: UInt32) {
            let newShortcut = KeyboardShortcut(keyCode: keyCode, modifierFlags: modifierFlags)
            parent.shortcut = newShortcut
            parent.displayText = newShortcut.displayString
            parent.isRecording = false
        }
    }
}

class RecorderView: NSView {
    var isRecording = false {
        didSet {
            if isRecording {
                window?.makeFirstResponder(self)
            }
        }
    }
    
    weak var delegate: ShortcutRecorderRepresentable.Coordinator?
    
    override var acceptsFirstResponder: Bool { true }
    
    override func keyDown(with event: NSEvent) {
        guard isRecording else { return }
        
        // Filter out standalone modifier key presses
        if !isModifierKeyCode(event.keyCode) {
            // Convert NSEvent modifiers to Carbon modifiers
            var carbonFlags: UInt32 = 0
            let flags = event.modifierFlags
            
            if flags.contains(.command) { carbonFlags |= UInt32(cmdKey) }
            if flags.contains(.shift) { carbonFlags |= UInt32(shiftKey) }
            if flags.contains(.option) { carbonFlags |= UInt32(optionKey) }
            if flags.contains(.control) { carbonFlags |= UInt32(controlKey) }
            
            // Require at least one modifier key
            if carbonFlags != 0 {
                delegate?.didRecordShortcut(
                    keyCode: UInt16(event.keyCode),
                    modifierFlags: carbonFlags
                )
            }
        }
    }
    
    private func isModifierKeyCode(_ keyCode: UInt16) -> Bool {
        let modifierKeyCodes: Set<UInt16> = [0x37, 0x38, 0x3A, 0x3B, 0x3C, 0x3D, 0x3E, 0x3F]
        return modifierKeyCodes.contains(keyCode)
    }
}

#Preview {
    @State var shortcut: KeyboardShortcut? = KeyboardShortcut(keyCode: 0x13, modifierFlags: UInt32(cmdKey | shiftKey))
    
    return ShortcutRecorder(shortcut: $shortcut)
        .padding()
        .frame(width: 200)
} 