import SwiftUI

struct MenuBarLabel: View {
    let task: String

    var body: some View {
        HStack(spacing: 5) {
            if !self.task.isEmpty {
                Text(self.task)
                    .font(.system(size: 14))
                    .lineLimit(1)
            }
            Image(systemName: "sailboat.fill")
                .font(.system(size: 12))
                .offset(y: 1)
        }
        .offset(y: -1)
    }
}
