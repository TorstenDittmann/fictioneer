# Fictioneer (native macOS)

Native SwiftUI version of Fictioneer — the focused writing app — at feature
parity with the Tauri app: the core writing loop, ⌥-hold AI ghost text,
offline prose analysis (readability, adverb/passive/cliché highlights, 0–100
score), progress & goals (streaks, 30-day chart, daily toast), RTF/TXT/EPUB
export (three EPUB templates, dependency-free zip writer), full-text search,
a ⌘K command palette, AI rephrase and prompt generation, focus mode (⌘F),
sidebar drag-reordering, project settings with eBook metadata, and the
bundled example project.

- macOS 15+, Swift 6 (strict concurrency), SwiftUI + an NSTextView-based editor.
- No dependencies. The Xcode project is generated with [XcodeGen](https://github.com/yonaskolb/XcodeGen).
- Projects are stored as native `.fictioneer` document packages (`project.json`
  manifest + one archived attributed string per scene/note). This format is
  **not** compatible with the Tauri app's `.fictioneer` SQLite files.

## Build & run

```sh
cd apps/fictioneer-swift
xcodegen                                            # generates Fictioneer.xcodeproj
xcodebuild -scheme Fictioneer -derivedDataPath build build
open build/Build/Products/Debug/Fictioneer.app
```

## Tests

```sh
xcodebuild -scheme Fictioneer -derivedDataPath build -destination 'platform=macOS' test
```

CI runs the same suite on pull requests and pushes to `main` that touch this
app (`.github/workflows/native.yml`, macOS 26 runner, Xcode 26). Failed runs
upload the `.xcresult` bundle as an artifact.

## iCloud

Projects are `NSDocument`s, so iCloud Drive sync, version history and the
conflict panel ("select which versions to keep") come from AppKit. New
projects are created in iCloud Drive ▸ Fictioneer when iCloud is available;
otherwise a save panel picks a local folder.

Default builds are ad-hoc signed and run **without** iCloud. iCloud needs an
active Apple Developer Program team (personal teams can't use the capability):

```sh
xcodebuild -scheme Fictioneer -derivedDataPath build \
  -xcconfig Config/iCloud.xcconfig -allowProvisioningUpdates build
```

The first such build registers the `iCloud.app.fictioneer` container.
`Config/Fictioneer-iCloud.entitlements` must stay in sync with the entitlements
in `project.yml` (it is that set plus the iCloud keys). Release builds signed
with Developer ID additionally need a Developer ID provisioning profile with
iCloud enabled.

## AI ghost text

The signature interaction: **hold ⌥** in a scene to stream a ~36-word
continuation as muted inline text at the caret — **Tab** accepts it as a single
undoable edit, **Esc** dismisses, releasing ⌥ fades it out and aborts the
request. Suggestions only fire with an empty selection and at least 10
characters before the caret, and never run concurrently.

It requires a verified license key (Settings → AI). The server URL defaults to
`https://intelligence.fictioneer.app` in release builds; debug builds default
to `http://localhost:3001` for local development. Either can be overridden
per-user in Settings (see `AppConfig` for the compile-time defaults).

### Manual end-to-end test

1. `cd apps/intelligence && bun run dev` (listens on port 3001; needs its own
   `.env` with provider keys — see that app's README).
2. Run the app, open Settings → AI, enter a license key, hit Verify.
3. Open a scene, write a sentence or two, hold ⌥: animated dots → streaming
   ghost text → "⇥ Tab" hint.
4. Press Tab: the suggestion becomes real text; ⌘Z undoes it in one step.
5. Quit and reopen — the saved scene contains no ghost text.

## Releasing

Releases are tag-driven and fully automated (`.github/workflows/release-native.yml`):

1. Bump `CFBundleShortVersionString` and `CFBundleVersion` (same semver) in `project.yml`; commit.
2. `git tag vX.Y.Z && git push origin vX.Y.Z`.
3. CI archives, signs with Developer ID, notarizes, staples, and publishes a
   GitHub release with a DMG (download), a zip (Sparkle update artifact), and
   a signed `appcast.xml`. The stable feed the app polls is the `appcast.xml`
   asset on the fixed `appcast` release.

Tags with a suffix (e.g. `v0.2.0-test1`) are marked prerelease; the suffix
must extend the `project.yml` version. Until the landing-page cutover, all
native releases stay prereleases so the Tauri pipeline keeps owning
`releases/latest`. The Sparkle EdDSA private key lives in the
`SPARKLE_PRIVATE_KEY` secret (backup in the maintainer's login Keychain).

## Layout

```
Fictioneer/
  Models/        Project / Chapter / Scene / Note (@Observable) + manifest DTOs
  Persistence/   ProjectPackage (document package IO), ProjectSession (autosave),
                 RecentProjectsStore (security-scoped bookmarks)
  Services/      IntelligenceClient (streaming), LicenseManager, AppSettings,
                 WordCounter, FontLoader
  Editor/        RichTextEditor (NSViewRepresentable), FictioneerTextView,
                 EditorController (formatting), EditorTheme,
                 GhostTextController (state machine) + GhostTextPresenter
  Features/      Welcome, Project (sidebar/editor/notes/overview), Settings
  Resources/     Assets, bundled fonts (iA Writer Duo S, Quattrocento — SIL OFL)
FictioneerTests/ Swift Testing suites (persistence round-trip, ghost state
                 machine, streaming client against a URLProtocol stub)
```
