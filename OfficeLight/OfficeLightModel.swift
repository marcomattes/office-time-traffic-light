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

    /// Local date as `yyyy-MM-dd`.
    static func dateString(_ date: Date, calendar: Calendar = .current) -> String {
        let parts = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", parts.year ?? 0, parts.month ?? 0, parts.day ?? 0)
    }
}

/// Checks every minute, on every network change and before sleep whether the Mac is on an office network,
/// and keeps today's office time and the office days up to date from that.
@Observable
final class OfficeLightModel {
    let settings = AppSettings()
    let network = NetworkDetection()
    private(set) var day: DayRecord
    private(set) var match: OfficeMatch?
    /// Dates (`yyyy-MM-dd`) on which the daily goal was reached.
    private(set) var officeDays: Set<String>

    @ObservationIgnored private let defaults = UserDefaults.standard
    @ObservationIgnored private var observers: [NSObjectProtocol] = []

    init() {
        day = Self.loadDay(from: defaults) ?? DayRecord(date: DayRecord.dateString(.now))
        officeDays = Set(defaults.stringArray(forKey: Key.officeDays) ?? [])
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

    /// This month's office days against the monthly goal.
    var month: OfficeMonth {
        OfficeMonth(containing: .now, officeDays: officeDays, quotaPercent: settings.monthlyQuotaPercent)
    }

    /// Discards today's record and starts over, e.g. after the Wi-Fi flapped or the Mac stayed in the office overnight.
    /// Today no longer counts as an office day until the daily goal is reached again.
    func resetToday() {
        officeDays.remove(day.date)
        saveOfficeDays()
        day = DayRecord(date: DayRecord.dateString(.now))
        check()
    }

    func check(now: Date = .now) {
        let today = DayRecord.dateString(now)
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

        if state == .green {
            if officeDays.insert(day.date).inserted {
                saveOfficeDays()
            }
            if !day.notificationSent {
                day.notificationSent = true
                Notifications.dailyGoalReached(officeTime: day.officeTime)
            }
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
            defaults.set(data, forKey: Key.today)
        }
    }

    private func saveOfficeDays() {
        defaults.set(officeDays.sorted(), forKey: Key.officeDays)
    }

    private static func loadDay(from defaults: UserDefaults) -> DayRecord? {
        guard let data = defaults.data(forKey: Key.today) else { return nil }
        return try? JSONDecoder().decode(DayRecord.self, from: data)
    }

    private enum Key {
        static let today = "today"
        static let officeDays = "officeDays"
    }
}

extension TimeInterval {
    /// `h:mm`, e.g. `6:24`.
    var hoursMinutes: String {
        let minutes = Int(self / 60)
        return String(format: "%d:%02d", minutes / 60, minutes % 60)
    }
}
