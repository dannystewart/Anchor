import Foundation
import Observation

@MainActor
@Observable
final class AnchorModel {
    static let shared: AnchorModel = .init()

    private static let taskKey = "currentTask"
    private static let timerEndDateKey = "timerEndDate"

    var currentTask: String = UserDefaults.standard.string(forKey: taskKey) ?? "" {
        didSet {
            UserDefaults.standard.set(self.currentTask, forKey: AnchorModel.taskKey)
        }
    }

    // MARK: - Timer

    private(set) var timeRemaining: Int = 0 // seconds; 0 means no active timer
    private(set) var isTimerExpired: Bool = false
    private(set) var timerFlashVisible: Bool = true

    private var timerEndDate: Date?
    private var timerTask: Task<Void, Never>?
    private var flashTask: Task<Void, Never>?

    var isTimerRunning: Bool { self.timeRemaining > 0 }

    var timerDisplayString: String? {
        if self.timeRemaining > 0 {
            let h = self.timeRemaining / 3600
            let m = (self.timeRemaining % 3600) / 60
            let s = self.timeRemaining % 60
            if h > 0 {
                return String(format: "%d:%02d:%02d", h, m, s)
            } else {
                return String(format: "%d:%02d", m, s)
            }
        } else if self.isTimerExpired {
            return self.timerFlashVisible ? "0:00" : nil
        }
        return nil
    }

    private init() {
        // Restore a timer that was running before the app quit
        if
            let savedEndDate = UserDefaults.standard.object(forKey: AnchorModel.timerEndDateKey) as? Date,
            savedEndDate.timeIntervalSinceNow > 0
        {
            self.timerEndDate = savedEndDate
            self.timeRemaining = Int(savedEndDate.timeIntervalSinceNow.rounded(.up))
            self.startTimerLoop(endDate: savedEndDate)
        }
    }

    func startTimer(hours: Int, minutes: Int) {
        let totalSeconds = hours * 3600 + minutes * 60
        guard totalSeconds > 0 else { return }

        self.cancelFlash()

        let endDate = Date().addingTimeInterval(TimeInterval(totalSeconds))
        // Round up to the next whole second boundary so timer ticks align with the system clock
        let alignedEndDate = Date(timeIntervalSinceReferenceDate: ceil(endDate.timeIntervalSinceReferenceDate))
        self.timerEndDate = alignedEndDate
        self.timeRemaining = Int(alignedEndDate.timeIntervalSinceNow.rounded(.up))
        UserDefaults.standard.set(alignedEndDate, forKey: AnchorModel.timerEndDateKey)

        self.startTimerLoop(endDate: alignedEndDate)
    }

    func stopTimer() {
        self.timerTask?.cancel()
        self.timerTask = nil
        self.cancelFlash()
        self.timerEndDate = nil
        self.timeRemaining = 0
        UserDefaults.standard.removeObject(forKey: AnchorModel.timerEndDateKey)
    }

    // MARK: - Private

    private func cancelFlash() {
        self.flashTask?.cancel()
        self.flashTask = nil
        self.isTimerExpired = false
        self.timerFlashVisible = true
    }

    private func startExpiredFlash() {
        self.isTimerExpired = true
        self.timerFlashVisible = true
        self.flashTask = Task { @MainActor in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                guard !Task.isCancelled else { break }
                self.timerFlashVisible.toggle()
            }
        }
    }

    private func startTimerLoop(endDate: Date) {
        self.timerTask?.cancel()
        self.timerTask = Task { @MainActor in
            while !Task.isCancelled {
                let remaining = Int(endDate.timeIntervalSinceNow.rounded(.up))
                if remaining <= 0 {
                    self.timeRemaining = 0
                    self.timerEndDate = nil
                    UserDefaults.standard.removeObject(forKey: AnchorModel.timerEndDateKey)
                    self.startExpiredFlash()
                    break
                }
                if remaining != self.timeRemaining {
                    self.timeRemaining = remaining
                }

                // Sleep until the next exact second boundary to stay aligned with the system clock
                let now = Date()
                let currentTime = now.timeIntervalSinceReferenceDate
                let nextSecond = floor(currentTime) + 1
                let sleepSeconds = nextSecond - currentTime
                let sleepNanos = UInt64(sleepSeconds * 1_000_000_000)
                try? await Task.sleep(nanoseconds: max(sleepNanos, 1))
                guard !Task.isCancelled, self.timerEndDate != nil else { break }
            }
        }
    }
}
