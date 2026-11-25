# Changelog

## Unreleased

- Break (default 45 min) in Settings; it is added to the daily goal because office time includes it.
- Office days: the menu shows how many days this month the daily goal was reached, against a monthly goal of working days (Monday to Friday) × monthly quota (default 50 %).

## 0.1.0 – 2026-10-29

First release.

- Menu bar light: gray (no office time yet today), red (daily goal not reached), green (daily goal reached).
- Office network detection by Wi-Fi SSID or IPv4 range; VPN tunnels are ignored.
- Office time as the span from the first to the last detection today; resets at midnight.
- Daily goal from scheduled hours × quota, with a one-time notification when it is reached.
- Menu shows today's office time, the time the daily goal will be reached, and the matched network.
- "Reset today's office time" in Settings for days where the detection went wrong.
- Launch at login via `SMAppService`.
- English and German UI.
- Runs on macOS 14 or later.
