# Native app releases + auto-updates — design

**Date:** 2026-08-03
**Status:** Approved

## Context

The native Swift app (`apps/fictioneer-swift`) will fully replace the Tauri app
— including dropping Windows/Linux support. Distribution stays direct download
(no Mac App Store): notarized artifacts on GitHub Releases, with Sparkle 2
providing in-app auto-updates. Releases are tag-driven. This iteration builds
the release pipeline and update mechanism; the public cutover (landing page,
retiring `publish.yml`) is a deliberate later step.

## Decisions

| Question | Decision |
|---|---|
| Relationship to Tauri app | Native replaces it completely; Win/Linux support ends |
| Channel | Direct download + Sparkle 2 |
| Release trigger | Pushing a `v*` tag (e.g. `v0.2.0`) |
| Scope now | Pipeline + Sparkle; landing-page cutover later |
| Appcast hosting | GitHub Releases asset at `releases/latest/download/appcast.xml` |

## 1. Update feed

`appcast.xml` is uploaded as an asset on every release. The stable URL
`https://github.com/TorstenDittmann/fictioneer/releases/latest/download/appcast.xml`
always resolves to the newest release — the same pattern the Tauri updater
already uses for `latest.json`. No extra hosting infrastructure.

## 2. App-side Sparkle integration

- Sparkle 2 added as an SPM dependency in `project.yml`, pinned to major 2.
- `SPUStandardUpdaterController` wired into `FictioneerApp`, with a
  "Check for Updates…" item in the app menu; automatic background checks on
  Sparkle's default cadence.
- `Info.plist`: `SUFeedURL` (URL above) and `SUPublicEDKey` (EdDSA public key).
- Sandboxing: the app keeps its sandbox. Per Sparkle's sandboxing docs this
  requires `SUEnableInstallerLauncherService: YES` in Info.plist and
  mach-lookup temporary exceptions for `$(PRODUCT_BUNDLE_IDENTIFIER)-spks` /
  `-spki` in the entitlements. The downloader XPC service is not needed
  because the app already has `com.apple.security.network.client`.

## 3. Release workflow (`.github/workflows/release-native.yml`)

Triggered by tags matching `v*`, on `macos-26` (Xcode 26 required — same
reasoning as `native.yml`). Steps:

1. **Tag guard** — fail if the tag version ≠ `CFBundleShortVersionString` in
   `project.yml`.
2. **Build** — `xcodegen`, then `xcodebuild archive` and `-exportArchive` with
   an export options plist (`method: developer-id`, manual signing, hardened
   runtime). Certificate import mirrors `publish.yml` (same
   `APPLE_CERTIFICATE` / `APPLE_CERTIFICATE_PASSWORD` / `KEYCHAIN_PASSWORD`
   secrets).
3. **Notarize the app** — zip, `notarytool submit --wait` (existing
   `APPLE_ID` / `APPLE_PASSWORD` / `APPLE_TEAM_ID` secrets), staple the app.
4. **Package** — `Fictioneer_{v}.zip` (Sparkle update artifact, from the
   stapled app) and `Fictioneer_{v}.dmg` (human download); the DMG is
   notarized and stapled separately.
5. **Sign + appcast** — Sparkle's `sign_update`/`generate_appcast` with the
   `SPARKLE_PRIVATE_KEY` secret produce the EdDSA signature and `appcast.xml`
   whose enclosure URLs point at this release's download path.
6. **Publish** — `gh release create v{v}` with the DMG, zip, and appcast.
   Prerelease tags (e.g. `v0.2.0-test`) are marked prerelease.

Native `v*` tags don't collide with Tauri's `app-v*` tags; both pipelines
coexist during the transition.

## 4. Versioning

`project.yml` is the single source: `CFBundleShortVersionString` and
`CFBundleVersion` both carry the semver (Sparkle compares `CFBundleVersion`).
Release ritual: bump version in `project.yml` → commit → `git tag vX.Y.Z` →
push the tag.

## 5. Keys and secrets

One-time setup: generate the Sparkle EdDSA pair (`generate_keys`), put the
public key in `Info.plist` (`SUPublicEDKey`), store the private key as the
`SPARKLE_PRIVATE_KEY` repo secret. All Apple signing/notarization secrets
already exist from the Tauri pipeline and are reused.

## 6. Out of scope (later cutover)

- Landing page still serves Tauri downloads.
- `publish.yml` untouched.
- Migration story for existing Tauri-on-Mac users.

When ready: point the Mac section of `/download` at the native release and
retire `publish.yml`.

## 7. Verification

- `native-tests` CI stays green with the Sparkle dependency (Debug + Release).
- End-to-end: push a prerelease tag, confirm the workflow produces a
  notarized, stapled DMG/zip and a valid appcast; install the build, then push
  a second prerelease tag and confirm the app offers and installs the update.
- `spctl -a -t exec -vv Fictioneer.app` passes on a released artifact.
