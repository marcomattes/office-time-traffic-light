# Contributing

Thanks for your interest. Office Light is a small, single-purpose tool, so contributions that keep it small are the most welcome.

## Before you start

- Open an issue for anything beyond a bug fix or a small improvement, so we can agree on the direction first.
- Features that are intentionally out of scope: history and statistics, multi-user support, holiday or work calendars, and an early warning before the daily goal.

## Building

Open `OfficeLight.xcodeproj` in Xcode 26 or later and run the `OfficeLight` scheme, or use `scripts/install.sh`. See the README for signing and permissions.

## Tests

Unit tests live in `OfficeLightTests` and use Swift Testing. The test target compiles the app's source files directly (everything except the entry point and resources), so the tests run without launching the app or asking for permissions:

```sh
xcodebuild test -project OfficeLight.xcodeproj -scheme OfficeLight -destination 'platform=macOS'
```

Logic that is easy to test in isolation, such as `IPv4Range`, `DayRecord` or the settings matching, belongs there. Anything that needs CoreWLAN, Location Services or the menu bar is verified by hand on a Mac. CI runs the tests on every push and pull request.

## Code

- Swift 6 with `MainActor` as the default actor isolation and approachable concurrency enabled. Mark delegate callbacks that arrive on other threads `nonisolated` and hop back with `Task { @MainActor in … }`.
- No third-party dependencies.
- Use the terms from `GLOSSARY.md` for names in code and UI, and avoid the listed alternatives.
- Comments explain *why*, not *what*. Keep them in English.
- UI strings are plain English literals in SwiftUI views and `String(localized:)` elsewhere. Add the German translation for every new string to `OfficeLight/Localizable.xcstrings`.
- Keep the deployment target at macOS 14 unless a feature really needs a newer API.

## Pull requests

- Keep each pull request focused on one change.
- Describe what changed and why, and how you verified it on your Mac.
- Add a line to `CHANGELOG.md` under the unreleased version.
- Don't commit your development team ID or other signing settings into `project.pbxproj`.
