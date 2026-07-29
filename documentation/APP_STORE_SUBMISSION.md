# App Store Submission Guide — Bike Sensor Emulator

This document contains everything needed to submit **Bike Sensor Emulator** to the App Store. The build and upload steps require your Apple Developer account and must be completed manually in Xcode and App Store Connect.

---

## App Identity

| Field | Value |
| --- | --- |
| **App Name** | Bike Sensor Emulator |
| **Subtitle** | Virtual Cycling Sensor |
| **Bundle ID** | `com.tallmansoftware.csc-emulator` |
| **SKU** | `csc-emulator` (suggested; any unique string is fine) |
| **Primary Language** | English (U.S.) |
| **Version** | 1.0 |
| **Build** | 1 |
| **Category** | Developer Tools |
| **LSApplicationCategoryType** | `public.app-category.developer-tools` |
| **Display Name (home screen)** | Bike Sensor |
| **In-app screen title** | Bike Sensor Emulator (header on all platforms; macOS window/toolbar title only) |
| **Development Team** | `MYMYAX7K65` |
| **Supported Platforms** | iPhone, iPad, Mac |
| **Minimum OS** | iOS 17.6, macOS 14.6 |
| **Price** | Free (recommended) |

---

## URLs

| Field | URL |
| --- | --- |
| **Support URL** | https://github.com/tonytallman/CSCS-emulator |
| **Marketing URL** | https://github.com/tonytallman/CSCS-emulator |
| **Privacy Policy URL** | https://github.com/tonytallman/CSCS-emulator/blob/main/documentation/PRIVACY_POLICY.md |

---

## Promotional Text (170 char max)

> A virtual BLE cycling sensor for iPhone, iPad, and Mac. Simulate speed and cadence in three modes — no hardware required.

(118 characters — can be updated anytime without a new review)

---

## Description

```
Turn your iPhone, iPad, or Mac into a Bluetooth Low Energy cycling sensor — no hardware required.

Bike Sensor Emulator advertises as a standard Cycling Speed and Cadence (CSCS) peripheral. Any app or bike computer that supports the Bluetooth SIG CSCS specification can connect and receive simulated data.

SIMULATION MODES

Pedaling — set speed (0–50 mph) and cadence (0–200 rpm) in real time using on-screen sliders.

Coasting — simulates a rider who has stopped pedaling. Cadence drops to zero immediately; speed decays gradually to a stop.

Random — cadence follows a natural random walk centered around 90 rpm, with speed derived automatically.

FEATURES

• Configure speed, cadence, or both before each session
• Advertises the standard Bluetooth SIG CSCS service
• Accepts one BLE connection at a time
• On iPhone and iPad, continues broadcasting while the app runs in the background
• Graceful error handling for Bluetooth unavailability and permission denials
• Runs on iPhone, iPad, and Mac with a single native app

Ideal for developers building cycling apps, QA teams verifying BLE sensor integrations, cyclists evaluating CSCS-compatible apps before purchasing a sensor, and anyone who needs a controllable CSCS signal without dedicated hardware.
```

---

## Keywords (100 char max, comma-separated)

```
BLE,cycling,cadence,speed,CSCS,Bluetooth,bike,peripheral,emulator,sensor,simulator
```

(82 characters)

---

## Export Compliance

**Does your app use encryption?** Yes (HTTPS/TLS is exempt)

**Is your app exempt from export compliance documentation?** Yes

The project sets `ITSAppUsesNonExemptEncryption = NO` in Info.plist. When uploading, answer:

- **Uses encryption:** Yes
- **Exempt from export compliance documentation:** Yes (standard Apple encryption only / exempt)

---

## Age Rating

Complete the questionnaire in App Store Connect. Expected answers for this app:

| Category | Answer |
| --- | --- |
| Cartoon or Fantasy Violence | None |
| Realistic Violence | None |
| Sexual Content or Nudity | None |
| Profanity or Crude Humor | None |
| Alcohol, Tobacco, or Drug Use | None |
| Mature/Suggestive Themes | None |
| Gambling | None |
| Horror/Fear Themes | None |
| Medical/Treatment Information | None |
| Unrestricted Web Access | No |
| Gambling and Contests | No |

**Expected rating:** 4+

---

## Privacy Nutrition Label

In App Store Connect → App Privacy:

| Question | Answer |
| --- | --- |
| Do you or your third-party partners collect data from this app? | **No, we do not collect data from this app** |
| Tracking | **No** |

The app includes `PrivacyInfo.xcprivacy` declaring no tracking, no collected data, and no required-reason APIs.

---

## Screenshot Requirements

Screenshots are stored in `documentation/screenshots/`. Upload the appropriate sizes in App Store Connect.

**Captured automatically:**

| File | Dimensions | Target requirement | Source |
| --- | --- | --- | --- |
| `iphone-configuration.png` | 1284 × 2778 | 1284 × 2778 (6.5" iPhone) | Physical iPhone |
| `iphone-running.png` | 1284 × 2778 | 1284 × 2778 (6.5" iPhone) | Physical iPhone |
| `ipad-configuration.png` | 2064 × 2752 | 2048 × 2732 (12.9" iPad) | iOS Simulator |
| `ipad-running.png` | 2064 × 2752 | 2048 × 2732 (12.9" iPad) | iOS Simulator |
| `mac-configuration.png` | 1280 × 2027 | 1280 × 800 minimum (Mac) | Debug export |
| `mac-running.png` | 1280 × 2027 | 1280 × 800 minimum (Mac) | Debug export |

**iPhone screenshots** require a connected physical device — the Simulator cannot represent Bluetooth permission UI correctly. Grant Bluetooth access for Bike Sensor Emulator on the device before running the script. **Mac screenshots** are exported by the Debug build itself (no Screen Recording permission required). Regenerate all with:

```bash
bash scripts/capture-screenshots.sh
```

Or Mac only:

```bash
# from repo root, after building Debug for macOS
MAC_APP="$(find ~/Library/Developer/Xcode/DerivedData -path '*/Debug/CSCSEmulator.app' -maxdepth 6 | head -1)"
OUT="documentation/screenshots"
for mode in configuration running; do
  output="$(CSCS_SCREENSHOT_MODE="$mode" "$MAC_APP/Contents/MacOS/CSCSEmulator" 2>&1)"
  exported="$(printf '%s\n' "$output" | rg 'CSCS_SCREENSHOT_EXPORT=' | cut -d= -f2-)"
  cp "$exported" "$OUT/mac-$mode.png"
  sips -z 2027 1280 "$OUT/mac-$mode.png" --out "$OUT/mac-$mode.png" >/dev/null
done
```

### iPhone (6.5" display — iPhone 14 Pro Max class)

Required: **1284 × 2778 px** (portrait) or **2778 × 1284 px** (landscape). Also accepted: **1242 × 2688 px** / **2688 × 1242 px**.

The capture script installs on a **physical iPhone** (Bluetooth permission must be granted), resizes to 1284 × 2778 for App Store Connect, and uses the iPad Pro 13-inch (M4) simulator for iPad captures.

| File | Screen |
| --- | --- |
| `iphone-configuration.png` | Configuration screen |
| `iphone-running.png` | Running screen |

### iPad (12.9" display — iPad Pro class)

Required: **2048 × 2732 px** (portrait) or **2732 × 2048 px** (landscape)

| File | Screen |
| --- | --- |
| `ipad-configuration.png` | Configuration screen |
| `ipad-running.png` | Running screen |

### Mac

Required: **1280 × 800 px** minimum (one of 1280×800, 1440×900, 2560×1600, or 2880×1800)

| File | Screen |
| --- | --- |
| `mac-configuration.png` | Configuration screen |
| `mac-running.png` | Running screen |

**Note:** iPhone captures must come from a physical device for correct Bluetooth permission UI. iPad Simulator captures may not match exact pixel dimensions. Resize or re-capture on the target device class if App Store Connect rejects them.

### Regenerating screenshots

Set the `CSCS_SCREENSHOT_MODE` environment variable when launching in Debug:

```bash
# Configuration screen
CSCS_SCREENSHOT_MODE=configuration

# Running screen
CSCS_SCREENSHOT_MODE=running
```

---

## Automated Pre-Submission

Most pre-upload steps can be run from the repository root. In Cursor, invoke the **`prepare-app-store-build`** skill to orchestrate the full workflow; or run the scripts individually:

| Step | Script | Output |
| --- | --- | --- |
| Bump build number | `bash scripts/bump-build-number.sh` | Updates `CURRENT_PROJECT_VERSION` in `project.pbxproj` |
| Run unit tests | `bash scripts/run-unit-tests.sh` | **Stops on failure** — do not proceed if tests fail |
| Archive and export | `bash scripts/archive-and-export.sh` | `build/export/ios/*.ipa`, `build/export/macos/*.pkg` |
| Screenshots | `bash scripts/capture-screenshots.sh` | `documentation/screenshots/` (iPhone: physical device; iPad: Simulator; Mac: export) |

After automation, upload the exported `.ipa` and `.pkg` via Xcode Organizer or Transporter, run **Validate App**, record the App Review screen recording manually, then complete the manual App Store Connect steps below.

---

## Manual Checklist

Complete these steps in order:

### 1. Apple Developer Portal

- [ ] Sign in at [developer.apple.com](https://developer.apple.com)
- [ ] Register App ID: `com.tallmansoftware.csc-emulator`
- [ ] Enable **Bluetooth** capability (and any other capabilities Xcode requests)
- [ ] Confirm team `MYMYAX7K65` has an active membership

### 2. App Store Connect

- [ ] Sign in at [appstoreconnect.apple.com](https://appstoreconnect.apple.com)
- [ ] Create a new app:
  - Platform: iOS (Mac is included via universal purchase / Mac Catalyst or native Mac target)
  - Name: **Bike Sensor Emulator**
  - Primary language: English (U.S.)
  - Bundle ID: `com.tallmansoftware.csc-emulator`
  - SKU: `csc-emulator`
- [ ] Under **Pricing and Availability**, set price (Free recommended) and territories
- [ ] Paste **Promotional Text**, **Description**, and **Keywords** from this document
- [ ] Set **Support URL**, **Marketing URL**, and **Privacy Policy URL**
- [ ] Set category to **Developer Tools**
- [ ] Complete **App Privacy** (Data Not Collected)
- [ ] Complete **Age Rating** questionnaire (4+ expected)
- [ ] Upload screenshots for iPhone, iPad, and Mac

### 3. Build and Upload (Xcode)

**Automated (recommended):** Run `bash scripts/archive-and-export.sh` after unit tests pass (see [Automated Pre-Submission](#automated-pre-submission)). Upload the exported artifacts from `build/export/`.

**Manual alternative:**

- [ ] Open `CSCSEmulator/CSCSEmulator.xcodeproj` in Xcode
- [ ] Select **Any iOS Device (arm64)** or a connected device for archive (not Simulator)
- [ ] Product → Archive
- [ ] In Organizer: **Validate App** → fix any issues
- [ ] **Distribute App** → App Store Connect → Upload
- [ ] For Mac: ensure the Mac target is included in the archive or create a separate Mac archive if needed

### 4. Submit for Review

- [ ] In App Store Connect, select the uploaded build
- [ ] Answer export compliance (exempt — see above)
- [ ] Record a **screen recording** on a physical device (see [App Review Information](#app-review-information) below)
- [ ] Paste the full **Review Notes** template into App Store Connect → **App Review Information** → **Notes** (fill in device list and attach recording)
- [ ] Submit for review

---

## App Review Information

Apple may reject new submissions under **Guideline 2.1 — Information Needed** if the **Notes** field in App Store Connect does not include enough detail for reviewers to understand and test the app. Include all seven items below in every submission.

### Screen recording (item 1)

Capture on a **physical device** running the **latest OS**. Begin at app launch and show the typical user flow:

1. Launch Bike Sensor Emulator
2. Bluetooth permission prompt (if shown on first launch)
3. Configuration screen: enable Speed and/or Cadence
4. Tap **Start Emulator**
5. Running screen: switch between Pedaling, Coasting, and Random modes
6. Adjust speed/cadence sliders (Pedaling mode)
7. Tap **Stop Emulator**

**Not applicable to this app** (none of these features exist): account registration/login/deletion, paid content or subscriptions, user-generated content, location/contacts/camera/App Tracking Transparency prompts.

The only sensitive capability requested is Bluetooth (`NSBluetoothAlwaysUsageDescription`: "Advertises a simulated cycling speed and cadence sensor.").

Optional second-device verification: any CSCS-compatible app on another phone, tablet, or bike computer can scan for a peripheral named **Bike Sensor Emulator** and connect. This is not required to verify the app itself functions correctly.

**Important:** App Review testing of BLE requires a **physical device**. The Simulator cannot advertise as a BLE peripheral.

### Review Notes template (items 1–7)

Paste into App Store Connect → **App Review Information** → **Notes**. Replace the device list placeholder with your actual test hardware. The Notes field has a **4000 character limit**; this template is kept under that limit.

```
Bike Sensor Emulator is a developer/testing utility that turns an iPhone, iPad, or Mac into
a virtual Bluetooth Low Energy (BLE) Cycling Speed and Cadence (CSCS) sensor. No
account, network access, or data collection is involved.

1. SCREEN RECORDING
Attached, captured on a physical device on the latest OS, starting at app launch:
launch app -> Bluetooth permission prompt (first launch) -> Configuration screen,
enable Speed/Cadence -> "Start Emulator" -> Running screen, switch Pedaling/
Coasting/Random modes, adjust sliders -> "Stop Emulator".

2. DEVICES AND OS TESTED
- iPhone SE (3rd generation), iOS 26.5
- Mac mini, macOS 26.5.2 

3. PURPOSE AND AUDIENCE
Developers, QA engineers, and cyclists testing CSCS-compatible apps or bike
computers often lack a physical sensor. Bike Sensor Emulator provides a controllable,
standards-compliant CSCS peripheral without hardware. Audience: iOS/macOS
developers building cycling/fitness apps, QA teams verifying BLE integrations, and
cyclists evaluating apps before buying a sensor. It simulates speed (0-50 mph) and
cadence (0-200 rpm) via three modes (Pedaling, Coasting, Random) and advertises the
standard Bluetooth SIG CSCS service. Free, no account required.

4. SETUP AND TESTING
No credentials or sample files needed. On a physical iPhone/iPad (BLE peripheral
mode is unavailable in Simulator): launch app, grant Bluetooth permission if
prompted, enable Speed and/or Cadence, tap "Start Emulator", try each mode
(Pedaling: adjust sliders; Coasting: cadence drops to 0 and speed decays; Random:
cadence/speed vary automatically), then tap "Stop Emulator".
Optional interoperability check: on a second iOS device, use nRF Connect for Mobile 
(generic BLE central) to scan for service 0x1816 / peripheral name 'Bike Sensor Emulator', 
connect, and enable notifications on characteristic 0x2A5B. Measurement packets 
update as speed/cadence change in the emulator UI. No third-party account or paid 
app is required for review.

5. EXTERNAL SERVICES
None. Fully self-contained, on-device only: no network calls, servers,
authentication, payments, analytics, crash reporting, ads, or AI services. Uses
only Apple frameworks: CoreBluetooth (BLE peripheral/GATT) and SwiftUI, plus the
standard Bluetooth SIG Cycling Speed and Cadence Service (0x1816).

6. REGIONAL DIFFERENCES
None. The app functions identically in all App Store territories with no
region-specific features, content, or restrictions.

7. REGULATED INDUSTRY / PROTECTED MATERIAL
Not applicable. The app does not operate in a regulated industry and includes no
copyrighted, licensed, or protected third-party material. It implements the
publicly documented Bluetooth SIG CSCS specification for interoperability testing
only. No additional authorization is required.
```

---

## Terminology Reference

- **Emulator** — App Store product name and BLE local name (`Bike Sensor Emulator`); home-screen label is shortened to `Bike Sensor`
- **Simulated / simulation modes** — describes generated ride data and behavior, not a competing product name

---

## Out of Scope for v1.0

- Configurable concurrent connections ([issue #1](https://github.com/tonytallman/CSCS-emulator/issues/1))
- BLE state restoration
- Other items listed under Future Enhancements in README
