import Foundation
import Observation

/// Office networks, scheduled hours and quota. Stored in the app's UserDefaults.
@Observable
final class AppSettings {
    var ssids: [String] {
        didSet { defaults.set(ssids, forKey: Key.ssids) }
    }

    /// IPv4 ranges in CIDR notation, e.g. `10.20.0.0/16`.
    var ipRanges: [String] {
        didSet { defaults.set(ipRanges, forKey: Key.ipRanges) }
    }

    var scheduledMinutes: Int {
        didSet { defaults.set(scheduledMinutes, forKey: Key.scheduledMinutes) }
    }

    var quotaPercent: Int {
        didSet { defaults.set(quotaPercent, forKey: Key.quotaPercent) }
    }

    @ObservationIgnored private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        ssids = defaults.stringArray(forKey: Key.ssids) ?? []
        ipRanges = defaults.stringArray(forKey: Key.ipRanges) ?? []
        scheduledMinutes = defaults.object(forKey: Key.scheduledMinutes) as? Int ?? 8 * 60
        quotaPercent = defaults.object(forKey: Key.quotaPercent) as? Int ?? 80
    }

    /// Daily goal = scheduled hours × quota.
    var dailyGoal: TimeInterval {
        TimeInterval(scheduledMinutes * 60 * quotaPercent) / 100
    }

    var hasOfficeNetwork: Bool {
        !ssids.isEmpty || !ipRanges.isEmpty
    }

    /// Checks whether the network state is an office network: a configured SSID **or** an address in a configured IP range.
    func match(in state: NetworkState) -> OfficeMatch? {
        if let ssid = state.ssid, ssids.contains(ssid) {
            return .ssid(ssid)
        }
        for text in ipRanges {
            guard let range = IPv4Range(text) else { continue }
            if let address = state.addresses.first(where: { range.contains($0.value) }) {
                return .ipRange(text, address)
            }
        }
        return nil
    }

    private enum Key {
        static let ssids = "ssids"
        static let ipRanges = "ipRanges"
        static let scheduledMinutes = "scheduledMinutes"
        static let quotaPercent = "quotaPercent"
    }
}

enum OfficeMatch: Equatable {
    case ssid(String)
    case ipRange(String, InterfaceAddress)

    /// Without the SSID; that only appears in `description` (tooltip).
    var shortDescription: String {
        switch self {
        case .ssid: "Wi-Fi “*****”"
        case .ipRange: description
        }
    }

    var description: String {
        switch self {
        case .ssid(let ssid): "Wi-Fi “\(ssid)”"
        case .ipRange(let range, let address): "\(address.text) (\(address.interface)) in \(range)"
        }
    }
}

/// An IPv4 range in CIDR notation.
struct IPv4Range {
    let network: UInt32
    let prefixLength: Int

    init?(_ text: String) {
        let parts = text.trimmingCharacters(in: .whitespaces).split(separator: "/")
        guard parts.count == 2,
              let network = IPv4Range.address(String(parts[0])),
              let prefixLength = Int(parts[1]), (0...32).contains(prefixLength)
        else { return nil }
        self.network = network
        self.prefixLength = prefixLength
    }

    func contains(_ address: UInt32) -> Bool {
        let mask: UInt32 = prefixLength == 0 ? 0 : ~UInt32(0) << (32 - prefixLength)
        return address & mask == network & mask
    }

    static func address(_ text: String) -> UInt32? {
        let octets = text.split(separator: ".", omittingEmptySubsequences: false).compactMap { UInt8($0) }
        guard octets.count == 4 else { return nil }
        return octets.reduce(0) { $0 << 8 | UInt32($1) }
    }

    /// The /24 network around an address, for "use current network".
    static func slash24(around address: UInt32) -> String {
        "\(InterfaceAddress.text(address & 0xFFFF_FF00))/24"
    }
}
