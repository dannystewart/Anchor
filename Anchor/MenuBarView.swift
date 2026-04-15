import SwiftUI

struct MenuBarView: View {
    @Environment(AppModel.self) private var appModel
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        Button(self.appModel.currentTask.isEmpty ? "Set Current Task…" : "Change Task…") {
            self.openWindow(id: "set-task")
            NSApp.activate(ignoringOtherApps: true)
        }

        if !self.appModel.currentTask.isEmpty {
            Button("Clear Task") {
                self.appModel.currentTask = ""
            }
        }

        Divider()

        Button("Quit Anchor") {
            NSApplication.shared.terminate(nil)
        }
    }
}
