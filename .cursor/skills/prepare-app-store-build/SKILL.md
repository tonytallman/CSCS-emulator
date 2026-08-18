---
name: prepare-app-store-build
description: >-
  Prepares a new Bike Sensor Emulator App Store build: bumps the build number, runs
  unit tests (stops on failure), archives and exports the iOS Release build,
  regenerates screenshots (iPhone and iPad on named Simulators), updates
  "What's New in This Version?" from commits since the last version tag,
  checks tallmansoftware.com for website copy drift (writes an agent-ready brief
  when updates are needed), then commits those changes and tags the commit
  locally without pushing. Use when preparing a new build, preparing a release
  build, or when the user asks for App Store build preparation automation.
disable-model-invocation: true
---

# Prepare App Store Build

Prepare a validated Bike Sensor Emulator build for manual upload to App Store Connect.

## Prerequisites

- Xcode installed with signing configured for team `MYMYAX7K65`
- Active Apple Developer membership
- Run from the repository root
- Named Simulators available (create once in Xcode → Window → Devices and Simulators if missing):
  - **Screenshot iPhone** — 6.5" display (e.g. iPhone 14 Plus) for App Store Connect’s 6.5" slot
  - **Screenshot iPad** — 13" display (e.g. iPad Pro 13-inch M4) for App Store Connect’s 13" iPad slot

## Workflow

Copy this checklist and track progress:

```
Task Progress:
- [ ] Step 1: Bump build number
- [ ] Step 2: Run unit tests (STOP on failure)
- [ ] Step 3: Archive and export (iOS)
- [ ] Step 4: Regenerate screenshots
- [ ] Step 5: Update "What's New in This Version"
- [ ] Step 6: Check tallmansoftware.com for website drift
- [ ] Step 7: Commit and tag (do not push)
- [ ] Step 8: Manual upload, App Review recording, and App Store Connect steps
```

Execute steps in order. Do not skip ahead if a step fails.

### Step 1: Bump build number

```bash
bash scripts/bump-build-number.sh
```

Increments `CURRENT_PROJECT_VERSION` across all targets in `project.pbxproj`. Does **not** change `MARKETING_VERSION` — bump that manually when shipping a new App Store version.

Report the old and new build numbers to the user.

### Step 2: Run unit tests — hard stop on failure

```bash
bash scripts/run-unit-tests.sh
```

Runs `CSCSEmulatorTests` on iOS Simulator.

**If any test fails:**

1. Report the failing tests and error output
2. **Stop the workflow** — do not proceed to archive or screenshots
3. Do not revert the build number bump unless the user asks

### Step 3: Archive and export

```bash
bash scripts/archive-and-export.sh
```

Creates a Release archive and exports an App Store Connect-ready `.ipa`:

| Output | Path |
| --- | --- |
| iOS archive | `build/archives/CSCSEmulator-iOS.xcarchive` |
| iOS export | `build/export/ios/` (`.ipa`) |

Export success validates signing and entitlements locally. Report the exported file paths.

### Step 4: Regenerate screenshots

Simulator screenshots need a **temporary** Bluetooth-availability bypass in `CSCPeripheralManager`. Do **not** leave that change in the committed tree.

1. **Apply the temporary bypass** in `CSCSEmulator/CSCSEmulator/BLE/CSCPeripheralManager.swift`:
   - Add a private `suppressBluetoothAvailabilityCheck` that is `true` under `#if DEBUG && targetEnvironment(simulator)` (else `false`).
   - In `updateAvailability()`, if suppressed, set `availability = .ready` and return.
   - In `peripheralManagerDidUpdateState`, after `updateAvailability()`, if suppressed, return before `BluetoothStateMapper.error` / stop handling.

2. **Capture screenshots:**

   ```bash
   bash scripts/capture-screenshots.sh
   ```

   Writes App Store screenshots to `documentation/screenshots/`:

   | Device | Capture method |
   | --- | --- |
   | iPhone | Simulator **Screenshot iPhone** (6.5") |
   | iPad | Simulator **Screenshot iPad** (13") |

   Launch modes use `CSCS_SCREENSHOT_MODE=configuration|running` (via `SIMCTL_CHILD_CSCS_SCREENSHOT_MODE` for Simulator). The script resizes iPhone captures to **1284 × 2778** for App Store Connect’s 6.5" slot.

3. **Undo the temporary bypass** immediately after capture succeeds (or fails — always restore):

   ```bash
   git restore --source=HEAD --staged --worktree \
     CSCSEmulator/CSCSEmulator/BLE/CSCPeripheralManager.swift
   ```

   If the file had other legitimate uncommitted edits, restore only the bypass hunks instead of a full restore. Confirm `git status` / `git diff` shows **no** remaining `suppressBluetoothAvailabilityCheck` changes.

4. Visually confirm configuration shots show the in-app Configuration UI (not the SpringBoard home screen) and that no Bluetooth warning callout appears.

### Step 5: Update "What's New in This Version"

Update [documentation/APP_STORE_SUBMISSION.md](../../documentation/APP_STORE_SUBMISSION.md) so App Store Connect release notes are ready to paste.

1. Resolve the latest version tag (tags look like `1.0(1)`, `1.1(3)`):

   ```bash
   git tag -l --sort=-v:refname | head -1
   ```

2. List commits since that tag (or since the previous marketing-version tag if preparing a new `MARKETING_VERSION`):

   ```bash
   git log '<tag>..HEAD' --pretty=format:'%s'
   ```

   If `HEAD` is already at the latest tag with no newer commits, use commits since the **previous** tag (`git tag -l --sort=-v:refname | sed -n '2p'`) so the notes still reflect what shipped in the current version.

3. Draft user-facing **What's New in This Version?** copy from those commits:
   - Write for App Store customers (short bullets or short paragraphs), not raw commit subjects
   - Emphasize user-visible changes (features, fixes, naming, UI); skip internal-only work (test-only, DI, build scripts, screenshot automation) unless it affects users
   - Omit meta commits such as “App Store submission …”, build-number bumps, and merge noise
   - Stay within App Store Connect’s 4000-character limit (aim much shorter)
   - For the first release / no prior tag: use a brief first-release blurb instead of an empty section

4. Write the draft into the **What's New in This Version?** section of `documentation/APP_STORE_SUBMISSION.md` (create the section if missing — place it after **Promotional Text**). Also sync the same bullet in each `documentation/app-store/*.md` localization file. Sync **Version** and **Build** in the App Identity table from `MARKETING_VERSION` / `CURRENT_PROJECT_VERSION` in `project.pbxproj`.

5. Show the drafted notes in the final summary so the user can review before pasting into App Store Connect.

### Step 6: Check tallmansoftware.com for website drift

Compare the live Tallman Software website to this app repo. If the site is missing Bike Sensor Emulator content or copy is stale, write a self-contained brief for a **separate website agent** that will edit the tallmansoftware.com repo.

**Do not hard-stop** the workflow on website drift — report findings and continue to Step 7.

#### Fetch live pages

Use `WebFetch` on (do **not** use the preview worker):

| URL | Purpose |
| --- | --- |
| `https://www.tallmansoftware.com/` | Featured project section |
| `https://www.tallmansoftware.com/projects/` | Bike Sensor Emulator project listing |
| `https://www.tallmansoftware.com/projects/bike-sensor-emulator` | Case study |

Treat HTTP 404 or a missing Featured project section as findings. Do not fall back to preview URLs.

#### Compare against this repo

Extract **factual claims** only (ignore marketing tone). Verify against:

- [README.md](../../README.md) — name, platforms, features, BLE advertised name, architecture
- Code — `AppInfo.title`, `CFBundleDisplayName`, `CSCSIdentifiers.advertisedLocalName`, `SimulatorRanges`, Random-mode behavior, type names (`CSCPeripheralManager`, `SimulationEngine`, `AppContainer`, etc.)
- [documentation/PRIVACY_POLICY.md](../../documentation/PRIVACY_POLICY.md) — free / no data collected
- Step 5 **What's New** — user-visible changes the site copy does not yet reflect

Typical claim buckets: product name, platforms, App Store vs BLE name (“CSC Emulator” / “CSCS Emulator”), slider ranges (0–50 mph, 0–200 rpm), Random ~90 rpm, one central, background advertising, architecture type names, privacy.

#### Write the brief (only when updates are needed)

If the site matches the app, report **no updates needed** and do **not** create a file.

If updates are needed, write [documentation/WEBSITE_UPDATES.md](../../documentation/WEBSITE_UPDATES.md) (not gitignored) so it appears as a new/changed file in Git. The website agent will **not** have this iOS repo — put correct facts and proposed copy in the file itself. Do not write “see README” or “see `SimulatorRanges.swift`.”

If `WEBSITE_UPDATES.md` already exists from a prior run and the current check is clean, leave it (do not delete).

Required document structure:

1. **Instructions for the website agent** — short block at the top:
   - You are updating [tallmansoftware.com](https://www.tallmansoftware.com/) so Bike Sensor Emulator copy matches the shipping app.
   - Apply only the tasks below. Do not redesign unrelated pages or invent features.
   - Preserve the live site’s voice and layout; change facts, names, ranges, platforms, and missing sections — not marketing tone.
   - Prefer the **Proposed copy** blocks; adapt only to match surrounding voice.

2. **Canonical facts** — source-of-truth table (no repo references). Include at least:
   - Product name (`Bike Sensor Emulator`), home-screen name (`Bike Sensor`), BLE advertised name (localized; English `CSCS Emulator`; **CSCS** never translated)
   - App Store listing name if it still differs from the product name
   - Platforms (iPhone, iPad, Apple Silicon Mac via iPad app)
   - Slider ranges (0–50 mph, 0–200 rpm), Random mode (~90 rpm, speed derived)
   - One BLE central, background advertising on iPhone/iPad
   - Free / no data collected
   - App Store URL and GitHub URL if known from this repo
   - Marketing version and build checked (`MARKETING_VERSION` / `CURRENT_PROJECT_VERSION` from `project.pbxproj`)

3. **Scope** — URLs to touch; explicitly out of scope (home services/about, contact, unrelated projects).

4. **Per-page tasks** — one subsection each for `/`, `/projects/`, `/projects/bike-sensor-emulator`:
   - **Status:** live and current / live but stale / missing (404 or section absent)
   - **Current copy:** verbatim quotes from the fetch (or “page not found”)
   - **Task:** Create | Update | No change
   - **Proposed copy:** paste-ready text (card title, tagline, blurb, platforms line, CTAs). For the case study, section-level proposed paragraphs (What is it, How it behaves, Result, etc.).
   - **Must include / must not claim:** bullet facts for that page (e.g. must mention iPad-on-Mac; must not claim ANT+ or multiple sensors)

5. **What's New that the site should reflect** — user-visible changes from Step 5 as website copy implications, not commit subjects.

6. **Assets** — if the case study or cards use screenshots, note that fresh App Store shots are in `documentation/screenshots/` (human attaches them). Do not embed binaries.

Copy quality:

- Match the live site’s voice (if project pages 404, match other live home copy rather than inventing a new register).
- Keep home and `/projects/` cards short; put detail on the case study only.
- Do not dump internal type names unless the live case study already uses them; if it does, keep names accurate.

Report whether the brief was written in the final summary.

### Step 7: Commit and tag (do not push)

This step is authorized by the skill — do not ask for extra confirmation. **Never push** the commit or the tag (`git push`, `git push --tags`, or equivalent).

1. Confirm the Bluetooth bypass is gone (`git diff` / `git status` show no `suppressBluetoothAvailabilityCheck`). If it is still present, restore `CSCPeripheralManager.swift` and do not commit until it is gone.

2. Read `MARKETING_VERSION` and `CURRENT_PROJECT_VERSION` from `project.pbxproj`. The tag name is `MARKETING_VERSION(CURRENT_PROJECT_VERSION)` (e.g. `1.1(5)`). The commit message is `version MARKETING_VERSION (BUILD)` (e.g. `version 1.1 (5)`).

3. If that tag already exists, **stop** — report it and do not overwrite with `-f`.

4. Stage **only** files produced by Steps 1–6 of this run. Typical paths:
   - `CSCSEmulator/CSCSEmulator.xcodeproj/project.pbxproj` (build number)
   - `documentation/app-store/*.md` (What's New)
   - `documentation/WEBSITE_UPDATES.md` if this run created or updated it

   Leave unrelated uncommitted work unstaged. Do not stage the Bluetooth bypass, `build/` artifacts, or gitignored paths (`documentation/screenshots/`, `documentation/APP_STORE_SUBMISSION.md`).

5. Commit with a HEREDOC (do not skip hooks):

   ```bash
   git commit -m "$(cat <<'EOF'
   version 1.1 (5)

   EOF
   )"
   ```

   Substitute the actual marketing version and build. If the commit is rejected by a hook, fix the issue and create a **new** commit; do not amend.

6. Create an annotated tag on that commit (quote the tag name):

   ```bash
   git tag -a '1.1(5)' -m 'version 1.1 (5)'
   ```

7. Verify with `git status`, `git log -1`, and `git tag -l --sort=-v:refname | head -3`. Report the commit and tag in the final summary. Do not push.

### Step 8: Manual upload and App Store Connect

After automation completes, direct the user to [documentation/APP_STORE_SUBMISSION.md](../../documentation/APP_STORE_SUBMISSION.md) for:

- Uploading `.ipa` via Xcode Organizer or Transporter
- Running **Validate App** in Organizer (contacts App Store Connect)
- Uploading screenshots from `documentation/screenshots/`
- Pasting **What's New in This Version?** from the submission doc into App Store Connect
- Recording and attaching the **App Review screen recording** manually (see [App Review Information](../../documentation/APP_STORE_SUBMISSION.md#app-review-information))
- Pasting review notes and submitting for review

Do **not** run `scripts/capture-recording.sh` as part of this workflow — App Review recordings are captured by hand.

## Final summary template

When all automated steps succeed, report:

```markdown
## App Store build ready

- **Build number:** [old] → [new]
- **Unit tests:** passed (iOS Simulator)
- **iOS export:** build/export/ios/*.ipa
- **Screenshots:** documentation/screenshots/ (Screenshot iPhone + Screenshot iPad Simulators)
- **Bluetooth bypass:** temporary Simulator patch in `CSCPeripheralManager` applied for screenshots, then restored
- **What's New:** [1–3 sentence summary or bullet list drafted into APP_STORE_SUBMISSION.md]
- **Website:** documentation/WEBSITE_UPDATES.md (brief for website agent) | no updates needed
- **Git:** committed and tagged `[MARKETING_VERSION(BUILD)]` locally (not pushed)

**Next:** Upload via Organizer/Transporter, validate, paste What's New, complete App Store Connect metadata, record and attach App Review screen recording manually, submit for review. Push the commit and tag when ready. If `WEBSITE_UPDATES.md` exists, hand it to the website agent as the starting brief.
```

## Script reference

| Script | Purpose |
| --- | --- |
| `scripts/bump-build-number.sh` | Increment build number |
| `scripts/run-unit-tests.sh` | Unit tests (iOS Simulator) |
| `scripts/archive-and-export.sh` | iOS Release archive + export |
| `scripts/capture-screenshots.sh` | App Store screenshots (Screenshot iPhone / Screenshot iPad Simulators) |
| `scripts/ExportOptions-iOS.plist` | iOS export options |

## Screenshot workarounds

These are required for reliable Simulator captures. Only the capture-script settle/launch mitigations are permanent; the Bluetooth bypass must be temporary.

### Bluetooth gating on Simulator (temporary — do not commit)

The Simulator has no usable BLE peripheral stack, so real Bluetooth availability checks show the orange warning and disable **Start Emulator**.

**During Step 4 only**, temporarily patch `CSCPeripheralManager` so Debug Simulator builds treat availability as `.ready` and skip Bluetooth state error handling (`#if DEBUG && targetEnvironment(simulator)`). After `capture-screenshots.sh` finishes (success or failure), **undo** that patch so it is never committed or left in the working tree.

Release and device builds must keep real Bluetooth gating.

### Simulator launch / settle

`simctl launch` can return before the UI is foregrounded; a short settle often captures SpringBoard instead of the app (especially for `configuration`). Mitigations used by the capture script:

1. Boot the device, open Simulator with `-CurrentDeviceUDID`, then install
2. Terminate any existing app process before relaunch
3. Launch with `--terminate-running-process`
4. Pass mode via `SIMCTL_CHILD_CSCS_SCREENSHOT_MODE` (required for env vars under `simctl`)
5. Default settle of **6 seconds** (`SCREENSHOT_SETTLE_SECONDS`, overridable)
6. Build once with `-destination 'generic/platform=iOS Simulator'` so the app installs on Screenshot devices regardless of their runtime (do not pin a specific phone/OS for the Simulator build)

### iPhone dimensions

Resize iPhone PNGs to **1284 × 2778** with `sips` so they match App Store Connect’s 6.5" slot (Screenshot iPhone / iPhone 14 Plus class already matches that size).

## Troubleshooting

**Signing errors during archive/export:** Confirm team `MYMYAX7K65` is selected in Xcode and the App ID `com.tallmansoftware.csc-emulator` is registered with Bluetooth capability.

**Screenshot Simulator not found:** Create devices named exactly `Screenshot iPhone` and `Screenshot iPad` in Xcode. Verify with `xcrun simctl list devices available | rg Screenshot`.

**Configuration screenshot shows home screen:** Increase settle time (`SCREENSHOT_SETTLE_SECONDS=8 bash scripts/capture-screenshots.sh`) and re-run; ensure launch uses `--terminate-running-process` and `SIMCTL_CHILD_CSCS_SCREENSHOT_MODE`.

**Configuration screenshot shows Bluetooth warning:** Re-apply the temporary Simulator bypass in `CSCPeripheralManager` before capturing, then undo it after. Confirm the Debug Simulator build used for capture included the bypass.

**Bluetooth bypass left in working tree:** Run `git restore --source=HEAD --staged --worktree CSCSEmulator/CSCSEmulator/BLE/CSCPeripheralManager.swift` (or manually remove `suppressBluetoothAvailabilityCheck`). Never commit that bypass.

**Unit-test Simulator not found:** `scripts/run-unit-tests.sh` may pin a specific device/OS. Install that runtime in Xcode → Settings → Platforms, or update the destination in the script.

**Build number already uploaded:** App Store Connect rejects duplicate build numbers. Re-run `bump-build-number.sh` before archiving again.

**No version tags / empty What's New:** Tags use the form `MARKETING_VERSION(CURRENT_PROJECT_VERSION)` (e.g. `1.1(3)`). If none exist, draft a first-release blurb. If `HEAD` matches the latest tag, use commits from the previous tag so notes cover the current version’s changes.

**Website fetch fails:** Report the error and continue the workflow. If partial fetches succeed, write `WEBSITE_UPDATES.md` from what was retrieved and note which URLs could not be checked.

**Stale `WEBSITE_UPDATES.md` after a clean check:** Leave the existing file; report that the current check found no updates needed.

**Tag already exists:** Do not force-update (`-f`). Stop, report the existing tag, and wait for the user.

**Do not push:** This workflow never runs `git push` or `git push --tags`. The local commit and tag stay on the machine until the user pushes.

**Bluetooth bypass staged for commit:** Restore `CSCPeripheralManager.swift` and unstage it. Never commit `suppressBluetoothAvailabilityCheck`.
