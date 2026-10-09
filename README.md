# AudioPouch — an account-optional podcast app for Apple platforms

<div align="center">

[![Platform](https://img.shields.io/badge/platform-iOS%20%7C%20watchOS%20%7C%20tvOS-lightgrey?logo=apple)](https://github.com/alzimerahmed/AudioPouch)
[![Language](https://img.shields.io/badge/language-Swift-orange?logo=swift)](https://github.com/alzimerahmed/AudioPouch)
[![UI](https://img.shields.io/badge/UI-UIKit%20%2B%20SwiftUI-blue)](https://github.com/alzimerahmed/AudioPouch)
[![License](https://img.shields.io/badge/license-MPL--2.0-black)](LICENSE.md)
[![CI](https://github.com/alzimerahmed/AudioPouch/actions/workflows/ci.yml/badge.svg)](https://github.com/alzimerahmed/AudioPouch/actions/workflows/ci.yml)

*AudioPouch is an open-source podcast player for listeners who want local playback and account-free onboarding, with optional sync when they need it.*

[Features](#features) • [Building](#quick-start--building) • [Usage](#usage) • [Contributing](#contributing)

</div>

---

## Features

- Playback speed, trim silence, volume boost, chapters, bookmarks, and transcripts
- Up Next queue, filters, playlists, listening history, and downloads
- Podcast discovery, subscriptions, and OPML import
- Account-free onboarding and local-first listening statistics
- Custom light and dark themes with contrast validation
- Apple Watch app, widgets, Siri shortcuts, CarPlay, and share extensions
- Optional account sync across devices

## Screenshots

Screenshots will be added after the first public iOS build is available.

## Tech Stack

| Layer | Technology |
|---|---|
| Language | Swift 5 |
| Platforms | iOS, watchOS, tvOS, App Clip, and app extensions |
| UI | UIKit and SwiftUI |
| Architecture | Local Swift packages in `Modules/` |
| Data | FMDB and GRDB-backed local storage, with optional server sync |
| Build and tests | Xcode, XCTest, SwiftLint, and GitHub Actions on macOS |
| License | MPL-2.0 |

## Project Structure

```text
├── podcasts/                    # Main iOS app and resources
├── Modules/                     # Shared local Swift packages and tests
├── PocketCastsTests/             # App-level XCTest suite
├── NotificationContent/         # Notification content extension
├── NotificationExtension/       # Notification service extension
├── Share Extension/             # Share extension
├── WidgetExtension/             # Home-screen widgets
├── Pocket Casts Watch App/       # watchOS app
├── Pocket Casts TV App/          # tvOS app
├── Pocket Casts App Clip/        # App Clip
├── PodcastsIntents(UI)/          # Siri intents
├── fastlane/                     # Release automation and store metadata
└── scripts/                      # Build and contributor helpers
```

## Quick Start / Building

AudioPouch is developed on macOS with Xcode. Builds and tests run in GitHub Actions; local builds are not supported from this Windows workspace.

1. Install the repository dependencies: `make install_dependencies`
2. For an external-contributor configuration, run: `make external_contributor`
3. Open `podcasts.xcodeproj` in Xcode and run the `pocketcasts` scheme.

## Usage

Open the Podcasts tab to browse or subscribe to a show. Add episodes to Up Next, download them for offline listening, or import an OPML subscription list from onboarding or Settings. An account is optional; signing in enables server sync.

## FAQ / Troubleshooting

**Can I build the app on Windows?** No. Xcode and the Apple SDKs are required. Pull requests are built and tested by the macOS GitHub Actions workflow.

**Do I need an account to listen?** No. Local subscriptions, playback, and listening history work without signing in; account sync is optional.

## Contributing

Fork the repository, create a focused branch, and open a pull request against `main`. Follow the Swift conventions in `AGENTS.md`; include XCTest coverage for behavior changes and wait for the required GitHub Actions checks before merging.

## Roadmap

- [x] Account-free onboarding and local-first listening statistics
- [x] Privacy-first local analytics and expanded theme support
- [ ] Complete AudioPouch bundle, signing, and distribution identity
- [ ] Verify and publish the first signed iOS release

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for release history.

## License

AudioPouch is distributed under the Mozilla Public License 2.0. See [LICENSE.md](LICENSE.md). The project preserves its Pocket Casts upstream attribution and history.
