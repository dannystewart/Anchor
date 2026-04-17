import SwiftUI

struct SetTaskView: View {
    static let popoverWidth: CGFloat = 330

    @Environment(AppModel.self) private var appModel
    @State private var taskText = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("What should you be working on right now?")
                .font(.headline)

            TextField("e.g. Finish the TPS reports", text: self.$taskText)
                .textFieldStyle(.roundedBorder)
                .focused(self.$isFocused)
                .onSubmit { self.save() }

            HStack {
                Spacer()
                Button("Cancel") { self.closeWindow() }
                    .keyboardShortcut(.escape, modifiers: [])
                Button("Set Task") { self.save() }
                    .buttonStyle(.borderedProminent)
                    .keyboardShortcut(.return, modifiers: [])
                    .disabled(self.taskText.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .padding(16)
        .frame(width: SetTaskView.popoverWidth)
        .onAppear {
            self.taskText = self.appModel.currentTask
            self.isFocused = true
        }
    }

    private func save() {
        let trimmed = self.taskText.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        self.appModel.currentTask = trimmed
        self.closeWindow()
    }

    private func closeWindow() {
        NSApp.keyWindow?.close()
    }
}
