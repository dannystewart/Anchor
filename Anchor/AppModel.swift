import Foundation

@MainActor
@Observable
final class AppModel {
    private static let taskKey = "currentTask"

    var currentTask: String = UserDefaults.standard.string(forKey: taskKey) ?? "" {
        didSet {
            UserDefaults.standard.set(self.currentTask, forKey: AppModel.taskKey)
        }
    }
}
