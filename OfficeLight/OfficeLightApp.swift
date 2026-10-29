import SwiftUI

@main
struct OfficeLightApp: App {
    @State private var model = OfficeLightModel()

    var body: some Scene {
        MenuBarExtra {
            MenuView(model: model)
        } label: {
            Image(nsImage: LightIcon.image(for: model.state))
                .accessibilityLabel("Office Light: \(model.state.label)")
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView(model: model)
        }
    }
}
