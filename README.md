# AudioPouch — a powerful open-source podcast app for iOS

<div align="center">

[![platform](https://img.shields.io/badge/platform-ios%20%7C%20watchos-lightgrey?logo=apple)](https://github.com/alzimerahmed/AudioPouch)
[![Swift](https://img.shields.io/badge/language-Swift-orange?logo=swift)](https://github.com/alzimerahmed/AudioPouch)
[![license](https://img.shields.io/badge/license-MPL--2.0-black)](https://github.com/alzimerahmed/AudioPouch/blob/main/LICENSE.md)
[![Xcode](https://img.shields.io/badge/Xcode-v27.0%2B-informational?logo=xcode)](https://github.com/alzimerahmed/AudioPouch)

*A podcast app by listeners, for listeners — forked from Pocket Casts iOS and built in the open.*

[Features](#features) • [Tech Stack](#tech-stack) • [Building](#quick-start--building)

</div>

---

## Features

- Full podcast player with playback effects (speed, trim silence, volume boost)
- Up Next queue with automatic reordering and episode priorities
- Filters, playlists, starred episodes, and listening history
- Discover catalogue, podcast subscriptions, and episode downloads
- Chapters, bookmarks, transcripts, and clips
- Apple Watch app, widgets, Siri shortcuts, CarPlay, and Share/Notification extensions
- Cloud sync across devices

## Screenshots

Coming soon — will be added as the app ships TestFlight builds.

## Tech Stack

| Layer | Technology |
|---|---|
| Language | Swift (UIKit + SwiftUI hybrid) |
| Platform | iOS, Apple Watch, widgets, extensions |
| Architecture | Feature modules as local Swift packages (`Modules/`) |
| Audio | Custom playback engine (`EffectsPlayer`, `DownloadManager`) |
| Analytics | Local-first, pluggable adapters |
| CI | GitHub Actions (macOS runners) |
| License | MPL-2.0 |

## Project Structure

```
├── podcasts/                  # Main iOS app target
├── Modules/                   # Local Swift packages (data, server, analytics, utils)
├── PocketCastsTests/          # Test targets
├── NotificationContent/       # Notification content extension
├── NotificationExtension/     # Notification service extension
├── Share Extension/           # Share extension
├── WidgetExtension/           # Home-screen widgets
├── Pocket Casts Watch App/    # watchOS app
├── Pocket Casts TV App/       # tvOS app
├── Pocket Casts App Clip/     # App clip
├── PodcastsIntents(UI)/       # Siri intents
├── fastlane/                  # Release automation
└── scripts/                   # Build helper scripts
```

## Quick Start / Building

1. Install dependencies: `gem install bundler && make install_dependencies`
2. External contributors: run `make external_contributor`
3. Open `podcasts.xcodeproj` in Xcode and run the `podcasts` scheme

> Note: the project is developed on macOS with Xcode; all automated builds and tests run in GitHub Actions.

## Contributing

Fork the repo, create a branch, and open a PR — see [CONTRIBUTING.md](CONTRIBUTING.md).

## Roadmap

- [ ] Full AudioPouch rebrand (UI strings, bundle IDs, assets)
- [ ] CI test gates on GitHub Actions
- [ ] Feature pipeline from the competitive analysis

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for the history inherited from upstream.
