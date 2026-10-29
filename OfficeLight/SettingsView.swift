import AppKit
import ServiceManagement
import SwiftUI

struct SettingsView: View {
    @Bindable var model: OfficeLightModel
    @State private var newSSID = ""
    @State private var newRange = ""
    @State private var launchAtLogin = SMAppService.mainApp.status == .enabled
    @State private var launchAtLoginError: String?

    private var settings: AppSettings { model.settings }

    var body: some View {
        @Bindable var settings = settings

        Form {
            Section("Office Wi-Fi networks (SSID)") {
                EntryList(entries: $settings.ssids)
                HStack {
                    TextField("SSID", text: $newSSID)
                    Button("Add") {
                        add(newSSID, to: &settings.ssids)
                        newSSID = ""
                    }
                    .disabled(newSSID.trimmingCharacters(in: .whitespaces).isEmpty)
                }
                Button("Use current Wi-Fi") {
                    if let ssid = model.network.state.ssid {
                        add(ssid, to: &settings.ssids)
                    }
                }
                .disabled(model.network.state.ssid == nil)
                if !model.network.canReadSSID {
                    HStack {
                        Text("Without Location Services access the SSID can't be read.")
                            .font(.caption).foregroundStyle(.secondary)
                        Button("Open System Settings") {
                            NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_LocationServices")!)
                        }
                    }
                }
            }

            Section("Office IP ranges (IPv4, CIDR)") {
                EntryList(entries: $settings.ipRanges)
                HStack {
                    TextField("e.g. 10.20.0.0/16", text: $newRange)
                    Button("Add") {
                        add(newRange, to: &settings.ipRanges)
                        newRange = ""
                    }
                    .disabled(IPv4Range(newRange) == nil)
                }
                ForEach(model.network.state.addresses, id: \.interface) { address in
                    Button("Use \(IPv4Range.slash24(around: address.value)) (\(address.interface): \(address.text))") {
                        add(IPv4Range.slash24(around: address.value), to: &settings.ipRanges)
                    }
                }
            }

            Section("Daily goal") {
                Stepper(value: $settings.scheduledMinutes, in: 60...(12 * 60), step: 15) {
                    LabeledContent("Scheduled hours", value: TimeInterval(settings.scheduledMinutes * 60).hoursMinutes)
                }
                Stepper(value: $settings.quotaPercent, in: 10...100, step: 5) {
                    LabeledContent("Quota", value: "\(settings.quotaPercent) %")
                }
                LabeledContent("Daily goal", value: settings.dailyGoal.hoursMinutes)
            }

            Section("Startup") {
                Toggle("Launch at login", isOn: Binding(
                    get: { launchAtLogin },
                    set: { setLaunchAtLogin($0) }
                ))
                if let launchAtLoginError {
                    Text(launchAtLoginError).font(.caption).foregroundStyle(.red)
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 460)
        .onChange(of: settings.ssids) { model.check() }
        .onChange(of: settings.ipRanges) { model.check() }
        .onAppear { model.network.refresh() }
    }

    private func add(_ text: String, to list: inout [String]) {
        let entry = text.trimmingCharacters(in: .whitespaces)
        if !entry.isEmpty, !list.contains(entry) {
            list.append(entry)
        }
    }

    private func setLaunchAtLogin(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
            launchAtLoginError = nil
        } catch {
            launchAtLoginError = error.localizedDescription
        }
        launchAtLogin = SMAppService.mainApp.status == .enabled
    }
}

private struct EntryList: View {
    @Binding var entries: [String]

    var body: some View {
        ForEach(entries, id: \.self) { entry in
            HStack {
                Text(entry)
                Spacer()
                Button {
                    entries.removeAll { $0 == entry }
                } label: {
                    Image(systemName: "minus.circle")
                }
                .buttonStyle(.borderless)
            }
        }
    }
}
