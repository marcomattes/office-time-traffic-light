# Office Light

A tiny macOS menu bar app that shows whether you have spent enough time in the office today.

It detects the office by network (Wi-Fi SSID or IPv4 range), measures today's office time and shows it as a colored dot in the menu bar:

| Light | Meaning |
|-------|---------|
| ⚪ gray | no office time yet today |
| 🔴 red | daily goal not reached yet |
| 🟢 green | daily goal reached |

When the daily goal is reached you get a single macOS notification. Click the dot for today's office time, the remaining time and which network matched.

## How it works

- **Office network**: a Wi-Fi SSID or an IPv4 range (CIDR) you configure. Several of each are allowed; any match counts.
- **Office time**: the span from the first to the last detection on an office network today. It resets at midnight.
- **Daily goal**: scheduled hours × quota. Defaults are 8 h × 80 % = 6:24.
- The app checks once a minute, on every network change, before sleep and after wake.
- Only today is kept (it survives a restart). There is no history.
- VPN tunnels (`utun`, `ipsec`, `ppp`) are ignored on purpose, so a VPN session from home with an office IP doesn't count.

See [GLOSSARY.md](GLOSSARY.md) for the terms used in the code and UI.

## Requirements

- macOS 27 or later
- Xcode 27 or later to build

## Build and install

```sh
scripts/install.sh
```

This builds the Release configuration and copies `OfficeLight.app` to `~/Applications`, then launches it.

By default the app is ad-hoc signed. That works, but macOS ties the Location Services permission to the code signature, so it asks again after every rebuild. To sign with your own Apple Development certificate, pass your team ID:

```sh
DEVELOPMENT_TEAM=ABCDE12345 scripts/install.sh
```

Or open `OfficeLight.xcodeproj` in Xcode, pick your team under *Signing & Capabilities* and run it from there.

## Permissions

The app asks for three things on first launch or in Settings:

- **Location Services**: macOS only reveals the Wi-Fi SSID to apps with location access. Your location itself is never read. Without this permission only the IP ranges are used.
- **Notifications**: for the one-time "daily goal reached" message.
- **Launch at login** (optional): toggled in Settings, registered via `SMAppService`.

## Privacy

Everything stays on your Mac. The app makes no network requests and stores its settings and today's record in its own `UserDefaults`. The SSID is masked in the menu (shown as `*****`) and only revealed in the tooltip, so it doesn't leak during screen sharing.

## Limitations

- IPv4 only.
- No history or statistics, no calendar awareness (on weekends the light simply stays gray).
- Time zone changes during a day are not handled.

## Project layout

```
OfficeLight/
  OfficeLightApp.swift    App entry: menu bar extra and Settings scene
  OfficeLightModel.swift  Today's record, light state, periodic checks
  AppSettings.swift       Settings, office network matching, IPv4 ranges
  NetworkDetection.swift  SSID (CoreWLAN) and IPv4 addresses (getifaddrs), change events
  MenuView.swift          Menu bar icon and popover
  SettingsView.swift      Settings window
  Notifications.swift     Daily goal notification
Support/Info.plist        Usage descriptions for Location Services
scripts/install.sh        Build and install to ~/Applications
```

## License

[MIT](LICENSE)
