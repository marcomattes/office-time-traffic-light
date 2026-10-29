import AppKit
import SwiftUI

/// The colored dot in the menu bar. Drawn as a non-template image, otherwise macOS renders it monochrome.
enum LightIcon {
    static func image(for state: LightState) -> NSImage {
        let color: NSColor = switch state {
        case .gray: .systemGray
        case .red: .systemRed
        case .green: .systemGreen
        }
        let image = NSImage(size: NSSize(width: 14, height: 14), flipped: false) { frame in
            color.setFill()
            NSBezierPath(ovalIn: frame.insetBy(dx: 1.5, dy: 1.5)).fill()
            return true
        }
        image.isTemplate = false
        return image
    }
}

struct MenuView: View {
    let model: OfficeLightModel
    @Environment(\.openSettings) private var openSettings

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(nsImage: LightIcon.image(for: model.state))
                Text(headline).font(.headline)
            }

            Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 4) {
                GridRow {
                    Text("Office time").foregroundStyle(.secondary)
                    Text("\(model.day.officeTime.hoursMinutes) / \(model.settings.dailyGoal.hoursMinutes)")
                        .monospacedDigit()
                }
                if let first = model.day.firstDetection, let last = model.day.lastDetection {
                    GridRow {
                        Text("In the office").foregroundStyle(.secondary)
                        Text("\(first.formatted(date: .omitted, time: .shortened)) – \(last.formatted(date: .omitted, time: .shortened))")
                            .monospacedDigit()
                    }
                }
                GridRow {
                    Text("Network").foregroundStyle(.secondary)
                    Text(model.match?.shortDescription ?? "not on an office network")
                        .help(model.match?.description ?? "")
                }
            }
            .font(.callout)

            if !model.settings.hasOfficeNetwork {
                Notice(text: "No office network configured yet.")
            } else if !model.settings.ssids.isEmpty, !model.network.canReadSSID {
                Notice(text: "No Location Services access: the SSID is unknown, only IP ranges count.")
            }

            Divider()

            HStack {
                Button("Settings…") {
                    NSApp.activate()
                    openSettings()
                }
                Spacer()
                Button("Quit") { NSApp.terminate(nil) }
            }
        }
        .padding(14)
        .frame(width: 300)
        .onAppear { model.check() }
    }

    private var headline: String {
        switch model.state {
        case .gray: "No office time yet today"
        case .red: "\(model.remainingTime.hoursMinutes) left until the daily goal"
        case .green: "Daily goal reached"
        }
    }
}

private struct Notice: View {
    let text: String

    var body: some View {
        Label(text, systemImage: "exclamationmark.triangle")
            .font(.caption)
            .foregroundStyle(.orange)
            .fixedSize(horizontal: false, vertical: true)
    }
}
