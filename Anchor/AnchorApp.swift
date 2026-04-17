import AppKit
import SwiftUI

// MARK: - AnchorApp

@main
struct AnchorApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}
