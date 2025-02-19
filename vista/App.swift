import SwiftUI

@main
struct VistaApp: App {
    var body: some Scene {
        MenuBarExtra("vista", systemImage: "mountain.2.fill") {
            MenuBarView()
        }
    }
}
