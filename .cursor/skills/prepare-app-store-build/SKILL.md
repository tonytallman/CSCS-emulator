---
name: prepare-app-store-build
description: >-
  Prepares a new Bike Sensor Emulator App Store build: bumps the build number, runs
  unit tests (stops on failure), archives and exports iOS/macOS Release builds,
  and regenerates screenshots (iPhone on a physical device). Use when preparing
  a new build, preparing a release build, or when the user asks for App Store
  build preparation automation.
disable-model-invocation: true
---

# Prepare App Store Build

Prepare a validated Bike Sensor Emulator build for manual upload to App Store Connect.

## Prerequisites

- Xcode installed with signing configured for team `MYMYAX7K65`
- Active Apple Developer membership
- Run from the repository root
- For iPhone screenshots: a connected, unlocked physical iPhone with Bluetooth permission granted for Bike Sensor Emulator

## Workflow

Copy this checklist and track progress:

```
Task Progress:
- [ ] Step 1: Bump build number
- [ ] Step 2: Run unit tests (STOP on failure)
- [ ] Step 3: Archive and export (iOS + macOS)
- [ ] Step 4: Regenerate screenshots
- [ ] Step 5: Manual upload, App Review recording, and App Store Connect steps
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

Runs `CSCSEmulatorTests` on iOS Simulator and macOS.

**If any test fails:**

1. Report the failing tests and error output
2. **Stop the workflow** — do not proceed to archive or screenshots
3. Do not revert the build number bump unless the user asks

### Step 3: Archive and export

```bash
bash scripts/archive-and-export.sh
```

Creates Release archives and exports App Store Connect-ready artifacts:

| Output | Path |
| --- | --- |
| iOS archive | `build/archives/CSCSEmulator-iOS.xcarchive` |
| macOS archive | `build/archives/CSCSEmulator-macOS.xcarchive` |
| iOS export | `build/export/ios/` (`.ipa`) |
| macOS export | `build/export/macos/` (`.pkg`) |

Export success validates signing and entitlements locally. Report the exported file paths.

### Step 4: Regenerate screenshots

```bash
bash scripts/capture-screenshots.sh
```

Writes App Store screenshots to `documentation/screenshots/`:

| Device | Capture method |
| --- | --- |
| iPhone | **Physical device** (required — Simulator cannot represent Bluetooth permission UI) |
| iPad | iOS Simulator (`iPad Pro 13-inch (M4)`) |
| Mac | Debug build PNG export |

Before running, connect and unlock the iPhone and grant Bluetooth access for Bike Sensor Emulator (Settings → Bike Sensor → Bluetooth, or accept the system prompt on first launch). Override the device if auto-detection fails:

```bash
IOS_DEVICE=00008110-001225620E32401E bash scripts/capture-screenshots.sh
```

**Note:** The script resizes iPhone captures to 1284 × 2778 for App Store Connect’s 6.5" slot. A larger iPhone (Pro Max class) yields sharper results than upscaling from a smaller device.

### Step 5: Manual upload and App Store Connect

After automation completes, direct the user to [documentation/APP_STORE_SUBMISSION.md](../../documentation/APP_STORE_SUBMISSION.md) for:

- Uploading `.ipa` / `.pkg` via Xcode Organizer or Transporter
- Running **Validate App** in Organizer (contacts App Store Connect)
- Uploading screenshots from `documentation/screenshots/`
- Recording and attaching the **App Review screen recording** manually (see [App Review Information](../../documentation/APP_STORE_SUBMISSION.md#app-review-information))
- Pasting review notes and submitting for review

Do **not** run `scripts/capture-recording.sh` as part of this workflow — App Review recordings are captured by hand.

## Final summary template

When all automated steps succeed, report:

```markdown
## App Store build ready

- **Build number:** [old] → [new]
- **Unit tests:** passed (iOS + macOS)
- **iOS export:** build/export/ios/*.ipa
- **macOS export:** build/export/macos/*.pkg
- **Screenshots:** documentation/screenshots/ (iPhone from physical device, iPad Simulator, Mac export)

**Next:** Upload via Organizer/Transporter, validate, complete App Store Connect metadata, record and attach App Review screen recording manually, submit for review.
```

## Script reference

| Script | Purpose |
| --- | --- |
| `scripts/bump-build-number.sh` | Increment build number |
| `scripts/run-unit-tests.sh` | Unit tests (iOS + macOS) |
| `scripts/archive-and-export.sh` | Release archive + export |
| `scripts/capture-screenshots.sh` | App Store screenshots (iPhone: physical device; iPad: Simulator; Mac: export) |
| `scripts/ExportOptions-iOS.plist` | iOS export options |
| `scripts/ExportOptions-macOS.plist` | macOS export options |

## Troubleshooting

**Signing errors during archive/export:** Confirm team `MYMYAX7K65` is selected in Xcode and the App ID `com.tallmansoftware.csc-emulator` is registered with Bluetooth capability.

**Simulator not found (unit tests / iPad screenshots):** Scripts pin `iPhone 16 Pro Max` to iOS 18.5 for the Simulator build used by iPad captures. Install that runtime in Xcode → Settings → Platforms, or update the device name/OS in the scripts.

**iPhone screenshots show permission errors or launch fails:** iPhone captures require a connected, unlocked physical device with Bluetooth permission granted. Re-run after unlocking the device and enabling access in Settings → Bike Sensor. Override auto-detection with `IOS_DEVICE=<udid>`.

**Build number already uploaded:** App Store Connect rejects duplicate build numbers. Re-run `bump-build-number.sh` before archiving again.
