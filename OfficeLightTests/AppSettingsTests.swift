import Foundation
import Testing

/// Uses a throwaway UserDefaults suite so the tests never touch the real settings.
@Suite final class AppSettingsTests {
    private let suiteName = "de.marcomattes.OfficeLightTests.\(UUID().uuidString)"
    private let defaults: UserDefaults
    private let settings: AppSettings

    init() {
        defaults = UserDefaults(suiteName: suiteName)!
        settings = AppSettings(defaults: defaults)
    }

    deinit {
        // A deinit is nonisolated, so hop back to the main actor to drop the throwaway suite.
        let suiteName = suiteName
        Task { @MainActor in
            UserDefaults(suiteName: suiteName)?.removePersistentDomain(forName: suiteName)
        }
    }

    @Test func defaultsAreEightHoursAtEightyPercent() {
        #expect(settings.scheduledMinutes == 8 * 60)
        #expect(settings.quotaPercent == 80)
        #expect(settings.dailyGoal == 6 * 3600 + 24 * 60)
        #expect(!settings.hasOfficeNetwork)
    }

    @Test func dailyGoalFollowsScheduledHoursAndQuota() {
        settings.scheduledMinutes = 10 * 60
        settings.quotaPercent = 50
        #expect(settings.dailyGoal == 5 * 3600)
    }

    @Test func settingsPersistAcrossInstances() {
        settings.ssids = ["Office"]
        settings.ipRanges = ["10.20.0.0/16"]
        settings.scheduledMinutes = 7 * 60
        settings.quotaPercent = 60

        let reloaded = AppSettings(defaults: defaults)
        #expect(reloaded.ssids == ["Office"])
        #expect(reloaded.ipRanges == ["10.20.0.0/16"])
        #expect(reloaded.scheduledMinutes == 7 * 60)
        #expect(reloaded.quotaPercent == 60)
    }

    @Test func matchesAConfiguredSSID() {
        settings.ssids = ["Office"]
        #expect(settings.match(in: NetworkState(ssid: "Office", addresses: [])) == .ssid("Office"))
        #expect(settings.match(in: NetworkState(ssid: "Home", addresses: [])) == nil)
        #expect(settings.match(in: NetworkState(ssid: nil, addresses: [])) == nil)
    }

    @Test func matchesAnAddressInAConfiguredRange() throws {
        settings.ipRanges = ["10.20.0.0/16"]
        let inside = InterfaceAddress(interface: "en0", value: try #require(IPv4Range.address("10.20.1.2")))
        let outside = InterfaceAddress(interface: "en1", value: try #require(IPv4Range.address("192.168.1.2")))

        #expect(settings.match(in: NetworkState(ssid: nil, addresses: [outside, inside])) == .ipRange("10.20.0.0/16", inside))
        #expect(settings.match(in: NetworkState(ssid: nil, addresses: [outside])) == nil)
    }

    @Test func ssidWinsOverIPRange() throws {
        settings.ssids = ["Office"]
        settings.ipRanges = ["10.20.0.0/16"]
        let inside = InterfaceAddress(interface: "en0", value: try #require(IPv4Range.address("10.20.1.2")))
        #expect(settings.match(in: NetworkState(ssid: "Office", addresses: [inside])) == .ssid("Office"))
    }

    @Test func invalidRangesAreSkipped() throws {
        settings.ipRanges = ["not a range", "10.20.0.0/16"]
        let inside = InterfaceAddress(interface: "en0", value: try #require(IPv4Range.address("10.20.1.2")))
        #expect(settings.match(in: NetworkState(ssid: nil, addresses: [inside])) == .ipRange("10.20.0.0/16", inside))
    }

    @Test func theSSIDStaysOutOfTheShortDescription() {
        let match = OfficeMatch.ssid("Secret Office")
        #expect(!match.shortDescription.contains("Secret Office"))
        #expect(match.description.contains("Secret Office"))
    }
}
