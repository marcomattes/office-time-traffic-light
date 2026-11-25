import Foundation
import Testing

@Suite struct OfficeMonthTests {
    private let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Berlin")!
        calendar.locale = Locale(identifier: "de_DE")
        return calendar
    }()

    private func date(_ year: Int, _ month: Int, _ day: Int) throws -> Date {
        try #require(calendar.date(from: DateComponents(year: year, month: month, day: day, hour: 12)))
    }

    @Test func countsMondayToFridayAsWorkingDays() throws {
        // November 2026 starts on a Sunday and has 30 days: 21 working days.
        let month = OfficeMonth(containing: try date(2026, 11, 25), officeDays: [], quotaPercent: 50, calendar: calendar)
        #expect(month.workingDays == 21)
        // February 2026 has exactly four full weeks.
        #expect(OfficeMonth(containing: try date(2026, 2, 1), officeDays: [], quotaPercent: 50, calendar: calendar).workingDays == 20)
    }

    @Test func monthlyGoalRoundsUp() throws {
        let november = try date(2026, 11, 25)
        #expect(OfficeMonth(containing: november, officeDays: [], quotaPercent: 50, calendar: calendar).monthlyGoal == 11)
        #expect(OfficeMonth(containing: november, officeDays: [], quotaPercent: 100, calendar: calendar).monthlyGoal == 21)
        #expect(OfficeMonth(containing: try date(2026, 2, 10), officeDays: [], quotaPercent: 50, calendar: calendar).monthlyGoal == 10)
    }

    @Test func countsOnlyOfficeDaysOfTheSameMonth() throws {
        let days: Set<String> = ["2026-10-30", "2026-11-02", "2026-11-03", "2026-11-25", "2026-12-01", "2025-11-03"]
        let month = OfficeMonth(containing: try date(2026, 11, 25), officeDays: days, quotaPercent: 50, calendar: calendar)
        #expect(month.officeDays == 3)
        #expect(!month.isReached)
    }

    @Test func isReachedAtTheMonthlyGoal() throws {
        let days = Set((2...12).map { String(format: "2026-11-%02d", $0) })
        let month = OfficeMonth(containing: try date(2026, 11, 25), officeDays: days, quotaPercent: 50, calendar: calendar)
        #expect(month.officeDays == 11)
        #expect(month.isReached)
    }

    @Test func dateStringIsZeroPadded() throws {
        #expect(DayRecord.dateString(try date(2026, 3, 7), calendar: calendar) == "2026-03-07")
    }
}
