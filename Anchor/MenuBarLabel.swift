import SwiftUI

struct MenuBarLabel: View {
    let task: String
    let timerString: String?

    private var displayText: String {
        switch (!self.task.isEmpty, self.timerString != nil) {
        case (true, true): "\(self.task) • \(self.timerString!)"
        case (true, false): self.task
        case (false, true): self.timerString!
        case (false, false): ""
        }
    }

    init(task: String, timerString: String? = nil) {
        self.task = task
        self.timerString = timerString
    }

    var body: some View {
        HStack(spacing: 5) {
            if !self.displayText.isEmpty {
                Text(self.displayText)
                    .font(.system(size: 14).monospacedDigit())
                    .lineLimit(1)
            }
            Image(systemName: "sailboat.fill")
                .font(.system(size: 12))
                .offset(y: 1)
        }
        .offset(y: -1)
    }
}
