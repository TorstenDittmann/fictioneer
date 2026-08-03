# Native App Releases + Sparkle Updates Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Tag-driven, signed, notarized GitHub releases for the native Swift app with Sparkle 2 in-app auto-updates.

**Architecture:** A `release-native.yml` workflow fires on `v*` tags: archive → export with Developer ID → notarize/staple → package zip (Sparkle) + DMG (humans) → EdDSA-sign and generate `appcast.xml` → publish GitHub release and clobber the appcast asset on a fixed `appcast` pseudo-release. The app embeds Sparkle 2 via SPM with `SPUStandardUpdaterController` and a stable feed URL.

**Tech Stack:** Sparkle 2 (SPM), xcodegen, xcodebuild archive/exportArchive, notarytool, GitHub Actions `macos-26`, `gh` CLI.

## Global Constraints

- Runner for all native jobs: `macos-26` (project requires Xcode 26 / Swift 6.2 settings; older toolchains fail strict concurrency — see `.github/workflows/native.yml`).
- Feed URL (exact): `https://github.com/TorstenDittmann/fictioneer/releases/download/appcast/appcast.xml`
- Native release tags: `v*` (never `app-v*`, which belongs to the Tauri pipeline).
- Native releases are marked **prerelease** until the landing-page cutover, so they never become the repo's "latest" release (the landing page depends on `releases/latest/download/latest.json` from the Tauri pipeline).
- `project.yml` is the single version source: `CFBundleShortVersionString` and `CFBundleVersion` both carry the same semver.
- Existing repo secrets reused: `APPLE_CERTIFICATE`, `APPLE_CERTIFICATE_PASSWORD`, `KEYCHAIN_PASSWORD`, `APPLE_ID`, `APPLE_PASSWORD`, `APPLE_TEAM_ID`. New secret: `SPARKLE_PRIVATE_KEY`.

---

### Task 1: Sparkle EdDSA keys + repo secret

**Files:**
- No repo files. Produces the `SPARKLE_PRIVATE_KEY` GitHub secret and a public key string consumed by Task 2.

**Interfaces:**
- Produces: `SPARKLE_PRIVATE_KEY` repo secret (file format produced by `generate_keys -x`, consumed by `generate_appcast --ed-key-file`); the base64 public key string (32 bytes decoded) for `SUPublicEDKey` in Task 2.

- [ ] **Step 1: Download Sparkle tools locally**

```bash
cd /tmp
curl -sL -o sparkle.tar.xz https://github.com/sparkle-project/Sparkle/releases/download/2.7.0/Sparkle-2.7.0.tar.xz
mkdir -p sparkle-dist && tar -xf sparkle.tar.xz -C sparkle-dist
ls sparkle-dist/bin/   # expect: generate_keys, sign_update, generate_appcast
```

(If 2.7.0's asset name 404s, check `gh release list -R sparkle-project/Sparkle --limit 5` and use the newest 2.x.)

- [ ] **Step 2: Generate the key pair (stored in the login Keychain as backup) and export the private key**

```bash
./sparkle-dist/bin/generate_keys           # prints the public key; stores private key in Keychain
./sparkle-dist/bin/generate_keys -x /tmp/sparkle_private_key
```

If a key already exists in the Keychain, `generate_keys` prints the existing public key — reuse it, don't force-regenerate.

- [ ] **Step 3: Store the private key as a repo secret, then delete the export**

```bash
gh secret set SPARKLE_PRIVATE_KEY < /tmp/sparkle_private_key
rm /tmp/sparkle_private_key
```

- [ ] **Step 4: Verify and record the public key**

```bash
./sparkle-dist/bin/generate_keys -p   # prints public key only
```

Verify it's 32 bytes: `./sparkle-dist/bin/generate_keys -p | base64 -d | wc -c` → `32`. Save the string for Task 2.

---

### Task 2: App-side Sparkle integration

**Files:**
- Modify: `apps/fictioneer-swift/project.yml`
- Modify: `apps/fictioneer-swift/Fictioneer/FictioneerApp.swift`
- Test: `apps/fictioneer-swift/FictioneerTests/UpdaterConfigurationTests.swift` (create)

**Interfaces:**
- Consumes: public key string from Task 1.
- Produces: an app bundle whose Info.plist carries `SUFeedURL`/`SUPublicEDKey`/`SUEnableInstallerLauncherService`, entitlements with the Sparkle mach-lookup exceptions, and a "Check for Updates…" menu item. Task 3's appcast must serve the URL in `SUFeedURL`.

- [ ] **Step 1: Write the failing test**

`apps/fictioneer-swift/FictioneerTests/UpdaterConfigurationTests.swift` (the test target uses the app as `TEST_HOST`, so `Bundle.main` is the app bundle):

```swift
import Foundation
import Testing

struct UpdaterConfigurationTests {
    @Test func feedURLPointsAtTheFixedAppcastRelease() {
        let info = Bundle.main.infoDictionary ?? [:]
        #expect(
            info["SUFeedURL"] as? String
                == "https://github.com/TorstenDittmann/fictioneer/releases/download/appcast/appcast.xml"
        )
    }

    @Test func publicEdDSAKeyIsPresentAndWellFormed() {
        let info = Bundle.main.infoDictionary ?? [:]
        let key = info["SUPublicEDKey"] as? String ?? ""
        #expect(Data(base64Encoded: key)?.count == 32)
    }

    @Test func installerLauncherServiceEnabledForSandbox() {
        let info = Bundle.main.infoDictionary ?? [:]
        #expect(info["SUEnableInstallerLauncherService"] as? Bool == true)
    }
}
```

- [ ] **Step 2: Run to verify it fails**

```bash
cd apps/fictioneer-swift && xcodegen && xcodebuild -scheme Fictioneer -derivedDataPath build -destination 'platform=macOS' test 2>&1 | tail -20
```

Expected: the three new tests FAIL (keys absent from Info.plist).

- [ ] **Step 3: Add Sparkle to project.yml**

In `apps/fictioneer-swift/project.yml`, add a top-level `packages:` block and the target dependency:

```yaml
packages:
  Sparkle:
    url: https://github.com/sparkle-project/Sparkle
    from: 2.7.0
```

Under `targets: → Fictioneer:` add:

```yaml
    dependencies:
      - package: Sparkle
```

In `targets: → Fictioneer: → info: → properties:` add (public key from Task 1):

```yaml
        SUFeedURL: "https://github.com/TorstenDittmann/fictioneer/releases/download/appcast/appcast.xml"
        SUPublicEDKey: "<public key from Task 1>"
        SUEnableInstallerLauncherService: true
```

In `targets: → Fictioneer: → entitlements: → properties:` add (Sparkle sandboxing requirement):

```yaml
        com.apple.security.temporary-exception.mach-lookup.global-name:
          - "$(PRODUCT_BUNDLE_IDENTIFIER)-spks"
          - "$(PRODUCT_BUNDLE_IDENTIFIER)-spki"
```

(The downloader XPC service is not needed — the app already has `com.apple.security.network.client`.)

- [ ] **Step 4: Wire the updater in FictioneerApp.swift**

Add `import Sparkle` and the controller as a stored property of `FictioneerApp`:

```swift
    private let updaterController = SPUStandardUpdaterController(
        startingUpdater: true,
        updaterDelegate: nil,
        userDriverDelegate: nil
    )
```

Add a command group inside `.commands { … }` (next to `AppCommands(appModel: appModel)`):

```swift
            CommandGroup(after: .appInfo) {
                Button("Check for Updates…") {
                    updaterController.checkForUpdates(nil)
                }
            }
```

- [ ] **Step 5: Run tests to verify everything passes**

```bash
cd apps/fictioneer-swift && xcodegen && xcodebuild -scheme Fictioneer -derivedDataPath build -destination 'platform=macOS' test 2>&1 | tail -5
```

Expected: full suite passes (146 tests). If SPM resolution of Sparkle `from: 2.7.0` fails, bump to the newest 2.x from `gh release list -R sparkle-project/Sparkle`.

- [ ] **Step 6: Launch the app and confirm the menu item exists**

```bash
pkill -x Fictioneer; open apps/fictioneer-swift/build/Build/Products/Debug/Fictioneer.app
```

Ask the user to confirm "Check for Updates…" appears in the Fictioneer app menu (checking it will report an error until an appcast exists — that's expected).

- [ ] **Step 7: Commit**

```bash
git add apps/fictioneer-swift/project.yml apps/fictioneer-swift/Fictioneer/FictioneerApp.swift apps/fictioneer-swift/FictioneerTests/UpdaterConfigurationTests.swift
git commit -m "Add Sparkle 2 auto-updates behind a Check for Updates menu item"
```

---

### Task 3: Release workflow

**Files:**
- Create: `.github/workflows/release-native.yml`
- Modify: `docs/superpowers/specs/2026-08-03-native-releases-design.md` (amend §1: fixed `appcast` release instead of `releases/latest`, with rationale)
- Modify: `apps/fictioneer-swift/README.md` (add "Releasing" section)

**Interfaces:**
- Consumes: `SPARKLE_PRIVATE_KEY` (Task 1); app config (Task 2); Apple secrets (existing).
- Produces: on `v*` tag push — a GitHub release `vX.Y.Z[-suffix]` with `Fictioneer_{version}.dmg`, `Fictioneer_{version}.zip`, `appcast.xml`; and the `appcast` pseudo-release's `appcast.xml` asset replaced.

- [ ] **Step 1: Write `.github/workflows/release-native.yml`**

```yaml
name: "release-native"

on:
    push:
        tags:
            - "v*"

jobs:
    release:
        # Xcode 26+ required — see .github/workflows/native.yml.
        runs-on: macos-26
        permissions:
            contents: write
        env:
            APP_DIR: apps/fictioneer-swift
        steps:
            - name: Checkout code
              uses: actions/checkout@v4

            - name: Derive and verify version from tag
              id: version
              run: |
                  TAG="${GITHUB_REF_NAME}"
                  VERSION="${TAG#v}"
                  BASE_VERSION="${VERSION%%-*}"
                  PLIST_VERSION=$(grep 'CFBundleShortVersionString' "$APP_DIR/project.yml" | sed 's/.*"\(.*\)".*/\1/')
                  if [ "$BASE_VERSION" != "$PLIST_VERSION" ]; then
                      echo "Tag $TAG (base $BASE_VERSION) does not match project.yml version $PLIST_VERSION" >&2
                      exit 1
                  fi
                  echo "version=$VERSION" >> "$GITHUB_OUTPUT"
                  if [ "$VERSION" != "$BASE_VERSION" ]; then
                      echo "prerelease=true" >> "$GITHUB_OUTPUT"
                  else
                      echo "prerelease=false" >> "$GITHUB_OUTPUT"
                  fi

            - name: Install XcodeGen
              run: brew install xcodegen

            - name: Import Apple Developer Certificate
              env:
                  APPLE_CERTIFICATE: ${{ secrets.APPLE_CERTIFICATE }}
                  APPLE_CERTIFICATE_PASSWORD: ${{ secrets.APPLE_CERTIFICATE_PASSWORD }}
                  KEYCHAIN_PASSWORD: ${{ secrets.KEYCHAIN_PASSWORD }}
              run: |
                  echo $APPLE_CERTIFICATE | base64 --decode > certificate.p12
                  security create-keychain -p "$KEYCHAIN_PASSWORD" build.keychain
                  security default-keychain -s build.keychain
                  security unlock-keychain -p "$KEYCHAIN_PASSWORD" build.keychain
                  security set-keychain-settings -t 3600 -u build.keychain
                  security import certificate.p12 -k build.keychain -P "$APPLE_CERTIFICATE_PASSWORD" -T /usr/bin/codesign
                  security set-key-partition-list -S apple-tool:,apple:,codesign: -s -k "$KEYCHAIN_PASSWORD" build.keychain
                  CERT_INFO=$(security find-identity -v -p codesigning build.keychain | grep "Developer ID Application")
                  CERT_ID=$(echo "$CERT_INFO" | awk -F'"' '{print $2}')
                  echo "CERT_ID=$CERT_ID" >> $GITHUB_ENV

            - name: Generate Xcode project
              run: xcodegen
              working-directory: apps/fictioneer-swift

            - name: Archive
              run: |
                  xcodebuild -scheme Fictioneer -configuration Release \
                      -derivedDataPath build \
                      -archivePath build/Fictioneer.xcarchive \
                      archive
              working-directory: apps/fictioneer-swift

            - name: Export with Developer ID
              env:
                  APPLE_TEAM_ID: ${{ secrets.APPLE_TEAM_ID }}
              run: |
                  cat > export-options.plist <<EOF
                  <?xml version="1.0" encoding="UTF-8"?>
                  <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
                  <plist version="1.0">
                  <dict>
                      <key>method</key>
                      <string>developer-id</string>
                      <key>signingStyle</key>
                      <string>manual</string>
                      <key>signingCertificate</key>
                      <string>${CERT_ID}</string>
                      <key>teamID</key>
                      <string>${APPLE_TEAM_ID}</string>
                  </dict>
                  </plist>
                  EOF
                  xcodebuild -exportArchive \
                      -archivePath build/Fictioneer.xcarchive \
                      -exportPath build/export \
                      -exportOptionsPlist export-options.plist
              working-directory: apps/fictioneer-swift

            - name: Notarize and staple the app
              env:
                  APPLE_ID: ${{ secrets.APPLE_ID }}
                  APPLE_PASSWORD: ${{ secrets.APPLE_PASSWORD }}
                  APPLE_TEAM_ID: ${{ secrets.APPLE_TEAM_ID }}
              run: |
                  ditto -c -k --keepParent build/export/Fictioneer.app notarize.zip
                  xcrun notarytool submit notarize.zip \
                      --apple-id "$APPLE_ID" --password "$APPLE_PASSWORD" --team-id "$APPLE_TEAM_ID" \
                      --wait
                  xcrun stapler staple build/export/Fictioneer.app
              working-directory: apps/fictioneer-swift

            - name: Package zip and DMG
              env:
                  VERSION: ${{ steps.version.outputs.version }}
                  APPLE_ID: ${{ secrets.APPLE_ID }}
                  APPLE_PASSWORD: ${{ secrets.APPLE_PASSWORD }}
                  APPLE_TEAM_ID: ${{ secrets.APPLE_TEAM_ID }}
              run: |
                  mkdir -p dist
                  ditto -c -k --keepParent build/export/Fictioneer.app "dist/Fictioneer_${VERSION}.zip"
                  hdiutil create -volname Fictioneer -srcfolder build/export/Fictioneer.app -ov -format UDZO "dist/Fictioneer_${VERSION}.dmg"
                  codesign --sign "$CERT_ID" --timestamp "dist/Fictioneer_${VERSION}.dmg"
                  xcrun notarytool submit "dist/Fictioneer_${VERSION}.dmg" \
                      --apple-id "$APPLE_ID" --password "$APPLE_PASSWORD" --team-id "$APPLE_TEAM_ID" \
                      --wait
                  xcrun stapler staple "dist/Fictioneer_${VERSION}.dmg"
              working-directory: apps/fictioneer-swift

            - name: Generate signed appcast
              env:
                  SPARKLE_PRIVATE_KEY: ${{ secrets.SPARKLE_PRIVATE_KEY }}
                  VERSION: ${{ steps.version.outputs.version }}
              run: |
                  curl -sL -o sparkle.tar.xz https://github.com/sparkle-project/Sparkle/releases/download/2.7.0/Sparkle-2.7.0.tar.xz
                  mkdir -p sparkle-dist && tar -xf sparkle.tar.xz -C sparkle-dist
                  printf '%s' "$SPARKLE_PRIVATE_KEY" > private_key
                  mkdir -p updates
                  cp "apps/fictioneer-swift/dist/Fictioneer_${VERSION}.zip" updates/
                  ./sparkle-dist/bin/generate_appcast \
                      --ed-key-file private_key \
                      --download-url-prefix "https://github.com/TorstenDittmann/fictioneer/releases/download/v${VERSION}/" \
                      -o appcast.xml \
                      updates
                  rm private_key
                  cat appcast.xml

            - name: Publish release and update the appcast feed
              env:
                  GH_TOKEN: ${{ github.token }}
                  VERSION: ${{ steps.version.outputs.version }}
                  PRERELEASE: ${{ steps.version.outputs.prerelease }}
              run: |
                  FLAGS="--generate-notes"
                  if [ "$PRERELEASE" = "true" ]; then FLAGS="$FLAGS --prerelease"; fi
                  gh release create "v${VERSION}" \
                      "apps/fictioneer-swift/dist/Fictioneer_${VERSION}.dmg" \
                      "apps/fictioneer-swift/dist/Fictioneer_${VERSION}.zip" \
                      appcast.xml \
                      --title "Fictioneer ${VERSION}" $FLAGS
                  # The fixed 'appcast' pseudo-release serves the stable feed URL.
                  if ! gh release view appcast >/dev/null 2>&1; then
                      gh release create appcast --title "Sparkle update feed" --prerelease \
                          --notes "Holds appcast.xml at a stable URL for the in-app updater. Do not delete."
                  fi
                  gh release upload appcast appcast.xml --clobber
```

- [ ] **Step 2: Validate YAML**

```bash
ruby -ryaml -e "YAML.load_file('.github/workflows/release-native.yml'); puts 'yaml ok'"
```

- [ ] **Step 3: Amend the spec's §1 (feed hosting)**

In `docs/superpowers/specs/2026-08-03-native-releases-design.md`, replace §1's `releases/latest/download/appcast.xml` approach with the fixed `appcast` pseudo-release (asset clobbered each release), noting the two reasons: GitHub's "latest" excludes prereleases (transition releases are prereleases), and a native release becoming "latest" would 404 the landing page's `latest.json` fetch and break `/download`.

- [ ] **Step 4: Add a "Releasing" section to `apps/fictioneer-swift/README.md`**

```markdown
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
```

- [ ] **Step 5: Commit**

```bash
git add .github/workflows/release-native.yml docs/superpowers/specs/2026-08-03-native-releases-design.md apps/fictioneer-swift/README.md
git commit -m "Add tag-driven release workflow for the native app"
git push
```

---

### Task 4: End-to-end release validation

**Files:**
- Modify: `apps/fictioneer-swift/project.yml` (version bumps only)

**Interfaces:**
- Consumes: everything above. No code changes beyond version bumps.

- [ ] **Step 1: Bump version for the test release**

In `apps/fictioneer-swift/project.yml`: `CFBundleShortVersionString: "0.1.1"` and `CFBundleVersion: "0.1.1"`. Commit (`Bump native app to 0.1.1`), push.

- [ ] **Step 2: Tag and watch the workflow**

```bash
git tag v0.1.1-test1 && git push origin v0.1.1-test1
gh run watch --exit-status $(gh run list --workflow release-native --limit 1 --json databaseId -q '.[0].databaseId')
```

Expected: workflow succeeds; release `v0.1.1-test1` (prerelease) exists with 3 assets; the `appcast` release's `appcast.xml` was updated.

- [ ] **Step 3: Verify the released artifact locally**

```bash
cd /tmp && gh release download v0.1.1-test1 --pattern '*.dmg'
hdiutil attach Fictioneer_0.1.1-test1.dmg
spctl -a -t exec -vv /Volumes/Fictioneer/Fictioneer.app   # expect: accepted, Notarized Developer ID
cp -R /Volumes/Fictioneer/Fictioneer.app /Applications/Fictioneer-test.app && hdiutil detach /Volumes/Fictioneer
```

Also fetch the feed and confirm it parses and points at the release:
`curl -sL https://github.com/TorstenDittmann/fictioneer/releases/download/appcast/appcast.xml`

- [ ] **Step 4: Publish a second test release**

Bump `project.yml` to `0.1.2`/`0.1.2`, commit, push, then `git tag v0.1.2-test1 && git push origin v0.1.2-test1`; watch as in Step 2.

- [ ] **Step 5: User-assisted update check**

Launch `/Applications/Fictioneer-test.app` (the 0.1.1 build) and ask the user to run "Check for Updates…" — Sparkle should offer 0.1.2, download, and relaunch into it. (GUI verification is the user's; do not screen-record.)

- [ ] **Step 6: Clean up test artifacts**

```bash
gh release delete v0.1.1-test1 --cleanup-tag --yes
gh release delete v0.1.2-test1 --cleanup-tag --yes
rm -rf /Applications/Fictioneer-test.app
```

(The `appcast` release stays — it's the permanent feed. Its `appcast.xml` will point at a deleted test release until the first real release replaces it; acceptable pre-cutover.)
