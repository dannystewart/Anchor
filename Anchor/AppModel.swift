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

    // MARK: - Timer

    private(set) var timeRemaining: Int = 0 // seconds; 0 means no active timer

    private var timerEndDate: Date? = nil
    private var timerTask: Task<Void, Never>? = nil

    var isTimerRunning: Bool { self.timeRemaining > 0 }

    var timerDisplayString: String? {
        guard self.timeRemaining > 0 else { return nil }
        let h = self.timeRemaining / 3600
        let m = (self.timeRemaining % 3600) / 60
        let s = self.timeRemaining % 60
        if h > 0 {
            return String(format: "%d:%02d:%02d", h, m, s)
        } else {
            return String(format: "%d:%02d", m, s)
        }
    }

    private init() {}

    func startTimer(hours: Int, minutes: Int) {
        let totalSeconds = hours * 3600 + minutes * 60
        guard totalSeconds > 0 else { return }

        self.timerEndDate = Date().addingTimeInterval(TimeInterval(totalSeconds))
        self.timeRemaining = totalSeconds

        self.timerTask?.cancel()
        self.timerTask = Task { @MainActor in
            while !Task.isCancelled {
                // Sleep in short increments so we respond quickly to cancellation
                try? await Task.sleep(for: .milliseconds(500))
                guard !Task.isCancelled, let endDate = self.timerEndDate else { break }

                let remaining = Int(endDate.timeIntervalSinceNow.rounded(.up))
                if remaining <= 0 {
                    self.timeRemaining = 0
                    self.timerEndDate = nil
                    break
                }
                self.timeRemaining = remaining
            }
        }
    }

    func stopTimer() {
        self.timerTask?.cancel()
        self.timerTask = nil
        self.timerEndDate = nil
        self.timeRemaining = 0
    }
}
