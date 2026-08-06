# Fictioneer: the move to native macOS

*Last updated: 2026-08-07 · branch `fictioneer-swift-mvp` · PR #12*

This document collects the whole plan and history of moving Fictioneer from the
Tauri (Svelte + Rust) desktop app to a native macOS SwiftUI app, the state it
is in today, and what remains before the native app takes over.

## Why native

- **The editor is the product.** An NSTextView-based editor gives real TextKit
  control (temporary attributes for analysis highlights, ghost text that can
  never leak into the document, single-undo accepts) that a webview can only
  approximate.
- **Feel.** Focus mode, typewriter scrolling, quiet native controls, system
  spellcheck, VoiceOver — all first-class instead of emulated.
- **Footprint and simplicity.** No web runtime, no third-party dependencies
  (Sparkle for updates is the sole exception), one `xcodegen && xcodebuild`
  build.

## What the native app is

Lives in `apps/fictioneer-swift`. macOS 15+, Swift 6 strict concurrency,
SwiftUI + an NSTextView editor, XcodeGen project, Swift Testing suite.

```
Fictioneer/
  Models/        Project / Chapter / Scene / Note (@Observable) + manifest DTOs
  Persistence/   ProjectPackage (document package IO), ProjectSession (autosave),
                 RecentProjectsStore (security-scoped bookmarks)
  Services/      IntelligenceClient (streaming), LicenseManager, AppSettings,
                 WordCounter, NoteMatcher, TagSuggestions, FontLoader
  Editor/        RichTextEditor, FictioneerTextView, EditorController,
                 GhostTextController/Presenter, AnalysisCoordinator/Highlighter
  Analysis/      Offline prose analysis (readability, adverbs, passive, clichés)
  Export/        ExportService, EpubBuilder, dependency-free ZipWriter
  Features/      Welcome, Project (sidebar/editors/overview), Settings,
                 Command palette, Progress
```

Projects are native `.fictioneer` document packages (`project.json` manifest +
one archived attributed string per scene/note) — deliberately **not**
compatible with the Tauri app's SQLite `.fictioneer` files.

## The migration in phases

### Phase 1 — MVP (the bulk of PR #12)

Feature parity with the Tauri app: the core writing loop, ⌥-hold AI ghost text
(stream at the caret, Tab accepts as one undo, Esc dismisses), offline prose
analysis with hover cards and a 0–100 score, progress & goals (streaks, 30-day
chart, daily toast), RTF/TXT/EPUB export with three templates, full-text
search, ⌘K command palette, AI rephrase and prompt generation, focus mode
(⌘F), sidebar drag-reordering, project settings with eBook metadata, bundled
example project, licensing against `intelligence.fictioneer.app`.

### Phase 2 — Releases and auto-updates

Sparkle 2 behind "Check for Updates…", tag-driven release automation
(archive → Developer ID signing → notarization → DMG + zip + signed
`appcast.xml` published to a fixed `appcast` GitHub release). Suffixed tags
(`v0.2.0-test1`) are prereleases; the Tauri pipeline keeps `releases/latest`
until the landing-page cutover. See `apps/fictioneer-swift/README.md`.

### Phase 3 — Closing the gaps (this final batch)

Four workstreams, executed and reviewed task-by-task:

**W1 — Parity leftovers**
1. Notes-in-scene detection (`NoteMatcher`, port of Tauri
   `find_notes_by_content`): note tags matched against the scene's plain text
   with case-insensitive `\b`-anchored escaped regexes, recomputed on the
   analysis debounce; a `note.text` icon + count in the running head opens a
   popover that navigates to matching notes.
2. Tag autocompletion chips in the note editor (distinct project tags minus
   applied, filtered by the fragment after the last comma).
3. Spellcheck toggle (Settings → Editor, applied live to the text view).
4. Persisted export defaults (include-toggles, format, EPUB template; seeded on
   open, saved only after a successful export).
5. Help → "Send Feedback…" (`mailto:support@fictioneer.app`).

**W2 — Monetization surface**
- `AppConfig.checkoutURL` / `accountURL` (`fictioneer.app/checkout`, `/account`).
- Quiet first-run license card on the welcome screen (`AI, IN PENCIL` eyebrow;
  Get a license / Enter key / Maybe later with persisted dismissal). No modal.
- Settings → AI: "Get a license…" and "Manage account…" links.
- Command palette: "Manage Account" (Tauri parity).

**W3 — Quality pass**
- Decision: analysis **hover cards** are the shipping affordance; the disabled
  margin-pills path was deleted wholesale.
- Edge-to-edge focus mode (`ManuscriptPage.isChromeless`): no running head, no
  chrome, paper full-bleed into the titlebar area; Esc restores the sheet.
- VoiceOver labels on all custom controls (toolbar buttons, score ring
  "Prose score N of 100", rephrase bar, hover cards, goal toast).
- ~100k-word analysis performance regression test.

**W4 — Ship readiness** — see “Where things stand” below.

## The hardening pass

Before ship-readiness sign-off, the full PR diff (126 files, ~13k insertions)
was reviewed by area (editor hot paths, features UI, core/persistence, tests).
The resulting fix wave closed 21 findings, most notably:

- **Ghost text could delete typed text**: typing during the ghost fade-out
  deleted a stale cached range. The ghost is now located by its `.ghostText`
  attribute marker before removal.
- **A pasted hyperlink could permanently brick a project**: the archive
  decoder's secure-coding allowlist rejected `NSURL` (and lists, attachments…)
  on read. Allowlist widened; a corrupt scene archive now degrades to an empty
  scene instead of failing the whole project open.
- Failed saves on close/quit now surface an alert (retry / close anyway; quit
  can be cancelled) instead of silently discarding work.
- A bad persisted export-default can no longer wipe the whole settings blob
  (including the license key) on decode.
- Ghost text works with Caps Lock on; formatting shortcuts work in focus mode;
  analysis no longer drops sentences after abbreviations ("no."); highlight
  ranges are Unicode-safe; regex tables are compiled once; Progress no longer
  crashes on duplicate day entries from sync conflicts; EPUB output is
  validated by parsing (zip central directory + XML) and strips XML-illegal
  characters; streaming-client error paths are tested.

Test suite: **146 → 209 tests** (41 suites), all green.

## Where things stand (2026-08-07)

Done and pushed to PR #12:
- All four workstreams implemented, task-reviewed, and hardened.
- Post-review UI polish from live testing: sidebar row layout (indent +
  truncation priorities), focus-mode top inset, running-head overlap.

Open — needs a human decision or hand:
1. **Merge PR #12** (review gate is clear; merge is the maintainer's call).
2. **Release workflow files** — `.github/workflows/native.yml` and
   `release-native.yml` are deleted in the working tree (uncommitted). The
   README's tag-driven release flow depends on them; resolve before tagging.
   Known gap if restored: the version gate checks `CFBundleShortVersionString`
   only, but Sparkle orders updates by `CFBundleVersion` — the gate should
   assert both.
3. **License key storage** — currently plaintext in `UserDefaults`; moving it
   to the Keychain is recommended post-merge hardening.
4. **Release** — bump `project.yml` to `0.2.0`, tag `v0.2.0-test1`
   (prerelease), verify the `appcast` asset resolves and Check for Updates
   stops 404ing, then decide the real `v0.2.0`.
5. **Production smoke test** — license verify + ghost text + rephrase against
   `https://intelligence.fictioneer.app` in a Release build.
6. **Manual checks** — VoiceOver announcements (especially the rephrase bar),
   focus-mode ⌘B/⌘I via the hidden shortcut buttons, upsell-card flow.

Known deferred minors (tracked, deliberately not blocking): command-palette
"New Scene" no-ops without a chapter; sidebar disclosure state only persists
on close; export re-generates a fresh EPUB identifier each time; autosave
debounce has no ceiling during nonstop typing; `NoteMatcher` recompiles
regexes per pass and `\b` can't match punctuation-edged tags (`#hero`);
a stuck analysis spinner edge after an undo-to-identical-text race; streak
counting treats duplicate same-day entries as separate days.

## After the cutover

- Landing page switches downloads to the native DMG; the native pipeline takes
  over `releases/latest`; Tauri releases stop.
- The Tauri app (`apps/fictioneer`) remains in-tree as the parity reference
  until the native app has fully replaced it, then can be retired.
- No data migration is planned between the two `.fictioneer` formats; the
  native app ships with its own example project and users start fresh.
