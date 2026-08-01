# Fictioneer (native macOS)

Native SwiftUI MVP of Fictioneer — the focused writing app — covering the core
writing loop plus the ⌥-hold AI ghost-text continuation, backed by the existing
`apps/intelligence` service.

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

## AI ghost text

The signature interaction: **hold ⌥** in a scene to stream a ~36-word
continuation as muted inline text at the caret — **Tab** accepts it as a single
undoable edit, **Esc** dismisses, releasing ⌥ fades it out and aborts the
request. Suggestions only fire with an empty selection and at least 10
characters before the caret, and never run concurrently.

It requires a verified license key (Settings → AI). The server URL defaults to
`http://localhost:3001` — the production URL is not in the repo (it lives in a
GitHub Actions variable); set it in `AppConfig.defaultIntelligenceBaseURL` or
per-user in Settings.

### Manual end-to-end test

1. `cd apps/intelligence && bun run dev` (listens on port 3001; needs its own
   `.env` with provider keys — see that app's README).
2. Run the app, open Settings → AI, enter a license key, hit Verify.
3. Open a scene, write a sentence or two, hold ⌥: animated dots → streaming
   ghost text → "⇥ Tab" hint.
4. Press Tab: the suggestion becomes real text; ⌘Z undoes it in one step.
5. Quit and reopen — the saved scene contains no ghost text.

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
