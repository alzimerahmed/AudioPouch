# AudioPouch — Rules for AI Agents

## Project

AudioPouch = open-source podcast app for iOS (standalone fork of Automattic's Pocket Casts iOS, MPL-2.0; repo: https://github.com/alzimerahmed/AudioPouch, owner: Alzimer Ahmed). Inherits the full Pocket Casts feature set: player with effects, Up Next queue, filters, discover, chapters, transcripts, Watch/TV/widget/extensions. Differentiation: privacy-first telemetry, account-free onboarding, community governance.

**License:** MPL-2.0. License text in `LICENSE.md` is preserved intact; our copyright notice is added per Exhibit A. Upstream attribution (Automattic) must remain in LICENSE and git history.

**Scope:** Native Apple-platform app only (iOS + Watch + TV + App Clip + widget/share/notification/intent extensions). No Android, no web. All verification is CI-only (see Build/Verify).

## How It Works (domain constraints — read before touching the engine)

- **Modules are the architecture** (`Modules/` — local Swift packages: PocketCastsModels, PocketCastsServer, PocketCastsAnalytics, PocketCastsUtils, PocketCastsUI, PocketCastsFeatures, PocketCastsMedia, PocketCastsTracking). New reusable logic goes into the right module, not the app target. App code imports modules; modules never import the app.
- **Main app target** is `podcasts/` (UIKit + SwiftUI hybrid — SwiftUI for new screens, UIKit when extending existing .xib screens). It is large; do not add god-files.
- **Playback engine**: `EffectsPlayer`, `DefaultPlayer`, `PlaybackManager`, `DownloadManager` — mature, delicate, under-tested. Changes need extra care and tests.
- **Data layer**: FMDB-based local database + server sync via `PocketCastsServer`. Episode/podcast status changes go through the managers (`EpisodeManager`, `PodcastManager`, `ServerSyncManager`), never raw SQL from UI.
- **Feature flags** live in `PocketCastsFeatures` — fence risky changes behind flags.
- **Theming**: every screen must work in all `AppTheme` cases; use the `Themeable` family and semantic `ThemeColor` tokens — see `docs/design/design-system.md` (local) and `podcasts/Theme/`.
- **Strings**: all user-facing strings in Localizable.strings / `.xcstrings` (many languages). Never hardcode.

## Tech Stack & Conventions (do not fight it)

- **Language**: Swift, Xcode 27 toolchain. Swift 5.
- **Project**: single `podcasts.xcodeproj`; shared schemes in `podcasts.xcodeproj/xcshareddata/xcschemes` (main scheme: `pocketcasts`).
- **Lint**: SwiftLint (`.swiftlint.yml`), run `--strict` in CI.
- **Tests**: XCTest — `PocketCastsTests/UnitTests.xctestplan`. Prefer module-level tests in `Modules/*/Tests`.
- **Dependencies**: SPM via `Modules/Package.swift` (upstream package URLs are dependencies, not ownership — do not rename). Ruby/fastlane via Bundler (`make install_dependencies`).
- **Credentials**: `make external_contributor` generates `LocalApiCredentials.swift` from the template — CI runs it; never commit real API keys.

## Build / Verify

```bash
# CI (GitHub Actions, .github/workflows/ci.yml — push/PR to main):
#   1. SwiftLint --strict
#   2. xcodebuild test -project podcasts.xcodeproj -scheme pocketcasts \
#      -testPlan UnitTests -destination 'platform=iOS Simulator,name=iPhone 16' \
#      CODE_SIGNING_ALLOWED=NO
```

**Remote-first verification (mandatory):** we do NOT build or test locally — this workspace is Windows and all builds/tests run in GitHub Actions (macOS runners). Local work is edit-only: static review while iterating. Push and let CI verify; a CI green check counts as the gate.

**Signing:** `config/*.xcconfig` retain upstream DEVELOPMENT_TEAM values for local builds; CI overrides with `CODE_SIGNING_ALLOWED=NO`. Never hardcode new team IDs.

## Gotchas

- **Windows checkout**: avoid `git clean -fdx`; some upstream asset paths can be Windows-hostile.
- **`pocket-casts-ios-fingerprint` package is pinned by branch** (`trunk`) — if upstream breaks it, SPM resolution breaks; consider vendoring.
- **No local build safety net** — grep all references (storyboards, .xib, .xcstrings keys, asset names) before deleting or renaming anything.
- **Product branding is still "Pocket Casts"** — full rebrand is Phase 3 (see `docs/plan.md`). Do not rename targets/schemes/bundle IDs ad hoc.
- **Upstream sync**: history is preserved so upstream updates can be fetched; keep merge attribution.

## Agent Guidelines & Constraints

### Do's
- **Write tests** for new module behavior (XCTest, behavior not implementation).
- **Conventional Commits**: `type(scope): description`.
- **Respect module boundaries** — new reusable logic goes into `Modules/`.
- **Plan discipline** — `docs/plan.md` must contain a Quality Gate phase and a Release phase. Every `idea.md` Feature Gap entry maps to a phase or is explicitly deferred. When a phase answers an open question in `docs/research.md`, close it there in the same change.

### Don'ts
- **NO local builds or test runs** — verification is CI-only (user directive; Windows host has no Xcode).
- **NO secrets in code** — API keys via the Credentials template + CI secrets only.
- **NO new heavy dependencies** without a decision record in `docs/research.md` (license must stay MPL-compatible).
- **NO deleting resources** without grepping all reference types (plists, xcconfigs, .xcstrings, asset catalogs, storyboards, .xib).
- **NO renaming targets/schemes/bundle IDs ad hoc** — that is Phase 3, CI-verified.

## Agent Guidelines & Workflow (this repo's .devin system)

### Resource Discipline (mandatory, non-trivial tasks)
Before any non-trivial task:
1. Read `docs/toolset.md` intent-map (task type → resources)
2. Invoke every skill + sub-agent in that row
3. Read every rule for that task type (`.devin/rules/`)
4. At task end: `code-reviewer` sub-agent on final diff (non-negotiable)
5. Append learnings via `/ce-compound` if durable lesson

Phase implementations (task completes a docs/plan.md row): follow `.devin/prompt/phase.md`.

Skip all this for single-line edits, pure Q&A, reading files.

### Project-Type Filter (Apple-platform podcast app)
Per `docs/toolset.md` intent-map:
- **Skip web-only/non-Apple:** pwa-engineer, seo-specialist, css-architect, playwright-design-clone, payment-integrator, email-engineer, monorepo-manager, web-scraper, search-optimization, backend-architect (no server).
- **Keep universal:** code-reviewer, debugger, test-engineer, security-auditor, performance-engineer, git-master, migration-specialist, docs-writer, build-optimizer, caveman-compressor, vibe-coding-auditor, type-safety-engineer, state-manager, i18n-specialist (strings files/RTL), media-optimizer, animation-engineer, frontend-designer (SwiftUI taste), content-writer, accessibility.
- **Quality gates:** CI-only — SwiftLint + unsigned build + UnitTests test plan on GitHub Actions. No local builds.

## Communication Style

Default **caveman-lite** (lightly compressed, readable, technically accurate). `/caveman` skill for full/ultra/wenyan modes.

## Quick Task Flow

Quick tasks: `.devin/prompt/quick.md` (commandments) + `.devin/prompt/rules.md` (scoping, verification, escalation). Phased work: `.devin/prompt/phase.md`.

## Key References

> Note: `docs/*.md` files below are the private knowledge layer (gitignored) — they exist only in the local workspace, not for external cloners.

- `docs/toolset.md` — intent map (task type → skills, sub-agents, rules)
- `docs/plan.md` — phased plan + status
- `docs/project.md` — project state/structure
- `docs/tools-log.md` — .devin resources invoked per session
- `docs/CONCEPTS.md` — project vocabulary
- `docs/research.md` — research, ADRs, gotchas, open questions
- `docs/idea.md` — competitive analysis + Feature Gap List
- `docs/design/design-system.md` — UI tokens + rules
