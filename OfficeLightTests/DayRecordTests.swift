import Foundation
import Testing

@Suite struct DayRecordTests {
    private let first = Date(timeIntervalSince1970: 1_700_000_000)

    @Test func noDetectionMeansNoOfficeTime() {
        #expect(DayRecord(date: "2026-10-29").officeTime == 0)
        #expect(DayRecord(date: "2026-10-29", firstDetection: first).officeTime == 0)
    }

    @Test func officeTimeIsTheSpanFromFirstToLastDetection() {
        let day = DayRecord(date: "2026-10-29", firstDetection: first, lastDetection: first + 3 * 3600)
        #expect(day.officeTime == 3 * 3600)
    }

    @Test func officeTimeIsNeverNegative() {
        let day = DayRecord(date: "2026-10-29", firstDetection: first, lastDetection: first - 60)
        #expect(day.officeTime == 0)
    }

    @Test func dailyGoalTimeIsFirstDetectionPlusGoal() {
        let day = DayRecord(date: "2026-10-29", firstDetection: first, lastDetection: first)
        #expect(day.dailyGoalTime(dailyGoal: 6 * 3600 + 24 * 60) == first + 6 * 3600 + 24 * 60)
    }

    @Test func dailyGoalTimeIsUnknownBeforeTheFirstDetection() {
        #expect(DayRecord(date: "2026-10-29").dailyGoalTime(dailyGoal: 3600) == nil)
    }

    @Test func survivesACodableRoundTrip() throws {
        let day = DayRecord(date: "2026-10-29", firstDetection: first, lastDetection: first + 60, notificationSent: true)
        let data = try JSONEncoder().encode(day)
        #expect(try JSONDecoder().decode(DayRecord.self, from: data) == day)
    }
}

@Suite struct HoursMinutesFormattingTests {
    nonisolated static let cases: [(seconds: TimeInterval, expected: String)] = [
        (0, "0:00"),
        (59, "0:00"),
        (60, "0:01"),
        (23_040, "6:24"),
        (36_000, "10:00"),
        (29_159, "8:05"),
    ]

    @Test(arguments: cases)
    func formatsAsHoursAndMinutes(seconds: TimeInterval, expected: String) {
        #expect(seconds.hoursMinutes == expected)
    }
}
