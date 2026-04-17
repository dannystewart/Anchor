import SwiftUI

struct SetTimerView: View {
    enum Field { case hours, minutes }

    static let popoverWidth: CGFloat = 200

    @Environment(AppModel.self) private var appModel
    @State private var hoursText = ""
    @State private var minutesText = ""
    @FocusState private var focusedField: Field?

    private var isValid: Bool {
        let h = Int(self.hoursText) ?? 0
        let m = Int(self.minutesText) ?? 0
        return h + m > 0
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Start a Timer")
                .font(.headline)

            HStack(spacing: 6) {
                TextField("0", text: self.$hoursText)
                    .textFieldStyle(.roundedBorder)
                    .focused(self.$focusedField, equals: .hours)
                    .frame(width: 52)
                    .multilineTextAlignment(.trailing)
                    .onChange(of: self.hoursText) {
                        self.hoursText = String(self.hoursText.filter(\.isNumber).prefix(2))
                    }
                    .onSubmit { self.focusedField = .minutes }

                Text("h")
                    .foregroundStyle(.secondary)

                TextField("25", text: self.$minutesText)
                    .textFieldStyle(.roundedBorder)
                    .focused(self.$focusedField, equals: .minutes)
                    .frame(width: 52)
                    .multilineTextAlignment(.trailing)
                    .onChange(of: self.minutesText) {
                        self.minutesText = String(self.minutesText.filter(\.isNumber).prefix(2))
                    }
                    .onSubmit { self.save() }

                Text("m")
                    .foregroundStyle(.secondary)
            }

            HStack {
                Spacer()
                Button("Cancel") { self.closeWindow() }
                    .keyboardShortcut(.escape, modifiers: [])
                Button("Start Timer") { self.save() }
                    .buttonStyle(.borderedProminent)
                    .keyboardShortcut(.return, modifiers: [])
                    .disabled(!self.isValid)
            }
        }
        .padding(16)
        .frame(width: SetTimerView.popoverWidth)
        .onAppear {
            if self.appModel.isTimerRunning {
                let h = self.appModel.timeRemaining / 3600
                let m = (self.appModel.timeRemaining % 3600) / 60
                if h > 0 { self.hoursText = "\(h)" }
                if m > 0 { self.minutesText = "\(m)" }
            }
            DispatchQueue.main.async {
                self.focusedField = .minutes
            }
        }
    }

    private func save() {
        let h = Int(self.hoursText) ?? 0
        let m = Int(self.minutesText) ?? 0
        guard h + m > 0 else { return }
        self.appModel.startTimer(hours: h, minutes: m)
        self.closeWindow()
    }

    private func closeWindow() {
        NSApp.keyWindow?.close()
    }
}
