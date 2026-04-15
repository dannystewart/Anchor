import SwiftUI

@main
struct AnchorApp: App {
    @State private var appModel: AppModel = .init()

    var body: some Scene {
        MenuBarExtra {
            MenuBarView()
                .environment(self.appModel)
        } label: {
            HStack(spacing: 5) {
                Image(systemName: "sailboat.fill")
                    .imageScale(.small)

                if !self.appModel.currentTask.isEmpty {
                    Text(self.appModel.currentTask)
                        .lineLimit(1)
                }
            }
        }
        .menuBarExtraStyle(.menu)

        Window("Set Current Task", id: "set-task") {
            SetTaskView()
                .environment(self.appModel)
        }
        .windowResizability(.contentSize)
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 380, height: 160)
    }

    init() {
        NSApplication.shared.setActivationPolicy(.accessory)
    }
}
