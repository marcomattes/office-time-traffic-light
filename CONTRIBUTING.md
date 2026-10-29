# Contributing

Thanks for your interest. Office Light is a small, single-purpose tool, so contributions that keep it small are the most welcome.

## Before you start

- Open an issue for anything beyond a bug fix or a small improvement, so we can agree on the direction first.
- Features that are intentionally out of scope: history and statistics, multi-user support, holiday or work calendars, and an early warning before the daily goal.

## Building

Open `OfficeLight.xcodeproj` in Xcode 27 or later and run the `OfficeLight` scheme, or use `scripts/install.sh`. See the README for signing and permissions.

## Code

- Swift 6 with `MainActor` as the default actor isolation and approachable concurrency enabled. Mark delegate callbacks that arrive on other threads `nonisolated` and hop back with `Task { @MainActor in … }`.
- No third-party dependencies.
- Use the terms from `GLOSSARY.md` for names in code and UI, and avoid the listed alternatives.
- Comments explain *why*, not *what*. Keep them in English.
- There are no automated tests at the moment. If you add logic that is easy to test in isolation (such as `IPv4Range`), tests are welcome.

## Pull requests

- Keep each pull request focused on one change.
- Describe what changed and why, and how you verified it on your Mac.
- Don't commit your development team ID or other signing settings into `project.pbxproj`.
