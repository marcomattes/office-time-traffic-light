import CoreLocation
import CoreWLAN
import Darwin
import Foundation
import notify
import Observation

struct InterfaceAddress: Equatable {
    let interface: String
    let value: UInt32

    var text: String { InterfaceAddress.text(value) }

    static func text(_ value: UInt32) -> String {
        "\(value >> 24).\(value >> 16 & 0xFF).\(value >> 8 & 0xFF).\(value & 0xFF)"
    }
}

struct NetworkState: Equatable {
    /// `nil` means "unknown" (no Wi-Fi or no Location Services access), not "not in the office".
    var ssid: String?
    var addresses: [InterfaceAddress]
}

/// Reads the SSID (CoreWLAN) and IPv4 addresses (`getifaddrs`) and reports debounced network changes via `onChange`.
@Observable
final class NetworkDetection: NSObject {
    private(set) var state = NetworkState(ssid: nil, addresses: [])
    private(set) var locationAuthorization: CLAuthorizationStatus = .notDetermined

    @ObservationIgnored var onChange: (() -> Void)?

    @ObservationIgnored private let wifi = CWWiFiClient.shared()
    @ObservationIgnored private let location = CLLocationManager()
    @ObservationIgnored private var notifyToken: Int32 = 0
    @ObservationIgnored private var debounce: Task<Void, Never>?

    var canReadSSID: Bool {
        locationAuthorization == .authorizedAlways || locationAuthorization == .authorized
    }

    func start() {
        location.delegate = self
        locationAuthorization = location.authorizationStatus
        if locationAuthorization == .notDetermined {
            location.requestWhenInUseAuthorization()
        }

        wifi.delegate = self
        try? wifi.startMonitoringEvent(with: .ssidDidChange)
        try? wifi.startMonitoringEvent(with: .linkDidChange)

        // kNotifySCNetworkChange; Swift doesn't import the constant.
        notify_register_dispatch("com.apple.system.config.network_change", &notifyToken, .main) { [weak self] _ in
            MainActor.assumeIsolated { self?.reportChange() }
        }

        refresh()
    }

    func refresh() {
        state = NetworkState(ssid: wifi.interface()?.ssid(), addresses: Self.ipv4Addresses())
    }

    /// Network changes often arrive several times in quick succession, so evaluate only after 2 s of quiet.
    private func reportChange() {
        debounce?.cancel()
        debounce = Task { [weak self] in
            try? await Task.sleep(for: .seconds(2))
            guard !Task.isCancelled else { return }
            self?.onChange?()
        }
    }

    /// IPv4 addresses of all active interfaces, excluding loopback, link-local and VPN tunnels.
    /// VPN deliberately doesn't count; otherwise a VPN session from home with an office IP would count as office time.
    private static func ipv4Addresses() -> [InterfaceAddress] {
        var head: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&head) == 0, let first = head else { return [] }
        defer { freeifaddrs(head) }

        var result: [InterfaceAddress] = []
        for pointer in sequence(first: first, next: { $0.pointee.ifa_next }) {
            let entry = pointer.pointee
            let flags = Int32(entry.ifa_flags)
            guard flags & IFF_UP != 0, flags & IFF_RUNNING != 0, flags & IFF_LOOPBACK == 0,
                  let sockaddr = entry.ifa_addr, sockaddr.pointee.sa_family == UInt8(AF_INET)
            else { continue }

            let name = String(cString: entry.ifa_name)
            guard !["utun", "ipsec", "ppp"].contains(where: name.hasPrefix) else { continue }

            let value = sockaddr.withMemoryRebound(to: sockaddr_in.self, capacity: 1) {
                UInt32(bigEndian: $0.pointee.sin_addr.s_addr)
            }
            guard value >> 16 != 0xA9FE else { continue } // 169.254.0.0/16
            result.append(InterfaceAddress(interface: name, value: value))
        }
        return result
    }
}

extension NetworkDetection: CWEventDelegate {
    nonisolated func ssidDidChangeForWiFiInterface(withName interfaceName: String) {
        Task { @MainActor in self.reportChange() }
    }

    nonisolated func linkDidChangeForWiFiInterface(withName interfaceName: String) {
        Task { @MainActor in self.reportChange() }
    }
}

extension NetworkDetection: CLLocationManagerDelegate {
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        Task { @MainActor in
            self.locationAuthorization = status
            self.onChange?()
        }
    }
}
