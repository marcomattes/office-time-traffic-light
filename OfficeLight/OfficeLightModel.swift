import AppKit
import Foundation
import Observation

enum LightState {
    case gray, red, green

    var label: String {
        switch self {
        case .gray: String(localized: "no office time yet today")
        case .red: String(localized: "daily goal not reached")
        case .green: String(localized: "daily goal reached")
        }
    }
}

/// Today's record: first and last detection on an office network. Discarded at midnight.
struct DayRecord: Codable, Equatable {
    /// Local date as `yyyy-MM-dd`.
    var date: String
    var firstDetection: Date?
    var lastDetection: Date?
    var notificationSent = false

    var officeTime: TimeInterval {
        guard let first = firstDetection, let last = lastDetection else { return 0 }
        return max(0, last.timeIntervalSince(first))
    }

    /// When the daily goal will be reached if the Mac stays on an office network; `nil` before the first detection.
    func dailyGoalTime(dailyGoal: TimeInterval) -> Date? {
        firstDetection.map { $0.addingTimeInterval(dailyGoal) }
    }
}

/// Checks every minute, on every network change and before sleep whether the Mac is on an office network,
/// and keeps today's office time up to date from that.
@Observable
final class OfficeLightModel {
    let settings = AppSettings()
    let network = NetworkDetection()
    private(set) var day: DayRecord
    private(set) var match: OfficeMatch?

    @ObservationIgnored private let defaults = UserDefaults.standard
    @ObservationIgnored private var observers: [NSObjectProtocol] = []

    init() {
        day = Self.loadDay(from: defaults) ?? DayRecord(date: Self.dateString(.now))
        network.onChange = { [weak self] in self?.check() }
        observeSystem()
        startTimer()
        Notifications.requestAuthorization()
        network.start()
        check()
    }

    var state: LightState {
        guard day.firstDetection != nil else { return .gray }
        return day.officeTime >= settings.dailyGoal ? .green : .red
    }

    var remainingTime: TimeInterval {
        max(0, settings.dailyGoal - day.officeTime)
    }

    /// When the daily goal will be reached if the Mac stays on an office network.
    var dailyGoalTime: Date? {
        day.dailyGoalTime(dailyGoal: settings.dailyGoal)
    }

    /// Discards today's record and starts over, e.g. after the Wi-Fi flapped or the Mac stayed in the office overnight.
    func resetToday() {
        day = DayRecord(date: Self.dateString(.now))
        check()
    }

    func check(now: Date = .now) {
        let today = Self.dateString(now)
        if day.date != today {
            day = DayRecord(date: today)
        }

        network.refresh()
        match = settings.match(in: network.state)
        if match != nil {
            if day.firstDetection == nil {
                day.firstDetection = now
            }
            day.lastDetection = now
        }

        if state == .green, !day.notificationSent {
            day.notificationSent = true
            Notifications.dailyGoalReached(officeTime: day.officeTime)
        }

        saveDay()
    }

    private func startTimer() {
        Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(60), tolerance: .seconds(5))
                self?.check()
            }
        }
    }

    private func observeSystem() {
        let workspace = NSWorkspace.shared.notificationCenter
        // Check once more before sleep so the last detection isn't up to a minute too early.
        for name in [NSWorkspace.willSleepNotification, NSWorkspace.didWakeNotification] {
            observers.append(workspace.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in
                MainActor.assumeIsolated { self?.check() }
            })
        }
        observers.append(NotificationCenter.default.addObserver(forName: .NSCalendarDayChanged, object: nil, queue: .main) { [weak self] _ in
            MainActor.assumeIsolated { self?.check() }
        })
    }

    private func saveDay() {
        if let data = try? JSONEncoder().encode(day) {
            defaults.set(data, forKey: "today")
        }
    }

    private static func loadDay(from defaults: UserDefaults) -> DayRecord? {
        guard let data = defaults.data(forKey: "today") else { return nil }
        return try? JSONDecoder().decode(DayRecord.self, from: data)
    }

    private static func dateString(_ date: Date) -> String {
        let parts = Calendar.current.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", parts.year ?? 0, parts.month ?? 0, parts.day ?? 0)
    }
}

extension TimeInterval {
    /// `h:mm`, e.g. `6:24`.
    var hoursMinutes: String {
        let minutes = Int(self / 60)
        return String(format: "%d:%02d", minutes / 60, minutes % 60)
    }
}
