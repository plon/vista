import SwiftUI

@main
struct VistaApp: App {
    var body: some Scene {
        MenuBarExtra("Vista", systemImage: "text.viewfinder") {
            MenuBarView()
        }
    }
}
