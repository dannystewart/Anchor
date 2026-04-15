import Foundation
import Observation

@MainActor
@Observable
final class AppModel {
    static let shared: AppModel = .init()

    private static let taskKey = "currentTask"

    var currentTask: String = UserDefaults.standard.string(forKey: taskKey) ?? "" {
        didSet {
            UserDefaults.standard.set(self.currentTask, forKey: AppModel.taskKey)
        }
    }

    private init() {}
}
