import Foundation

/// The office days of one calendar month, measured against the monthly goal.
struct OfficeMonth: Equatable {
    /// Days in this month on which the daily goal was reached.
    let officeDays: Int
    /// Monday to Friday in this month. Holidays and vacation are unknown to the app, so they count as working days.
    let workingDays: Int
    /// Office days needed this month: working days × monthly quota, rounded up.
    let monthlyGoal: Int

    var isReached: Bool { officeDays >= monthlyGoal }

    /// - Parameter officeDays: Dates as `yyyy-MM-dd`, see `DayRecord.dateString`; days of other months are ignored.
    init(containing date: Date, officeDays: Set<String>, quotaPercent: Int, calendar: Calendar = .current) {
        let prefix = String(DayRecord.dateString(date, calendar: calendar).prefix(8)) // "yyyy-MM-"
        self.officeDays = officeDays.filter { $0.hasPrefix(prefix) }.count

        var workingDays = 0
        if let month = calendar.dateInterval(of: .month, for: date) {
            var day = month.start
            while day < month.end {
                if !calendar.isDateInWeekend(day) { workingDays += 1 }
                guard let next = calendar.date(byAdding: .day, value: 1, to: day) else { break }
                day = next
            }
        }
        self.workingDays = workingDays
        monthlyGoal = (workingDays * quotaPercent + 99) / 100
    }
}
