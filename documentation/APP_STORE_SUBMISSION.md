# App Store Submission Guide — CSC Emulator

This document contains everything needed to submit **CSC Emulator** to the App Store. The build and upload steps require your Apple Developer account and must be completed manually in Xcode and App Store Connect.

---

## App Identity

| Field | Value |
| --- | --- |
| **App Name** | CSC Emulator |
| **Subtitle** | Virtual Cycling Sensor |
| **Bundle ID** | `com.tallmansoftware.csc-emulator` |
| **SKU** | `csc-emulator` (suggested; any unique string is fine) |
| **Primary Language** | English (U.S.) |
| **Version** | 1.0 |
| **Build** | 1 |
| **Category** | Developer Tools |
| **LSApplicationCategoryType** | `public.app-category.developer-tools` |
| **Display Name (home screen)** | CSC Emulator |
| **In-app navigation title** | CSCS BLE Emulator (unchanged) |
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

CSC Emulator advertises as a standard Cycling Speed and Cadence (CSCS) peripheral. Any app or bike computer that supports the Bluetooth SIG CSCS specification can connect and receive simulated data.

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

**Captured automatically (simulator):**

| File | Dimensions | Target requirement |
| --- | --- | --- |
| `iphone-configuration.png` | 1284 × 2778 | 1284 × 2778 (6.5" iPhone) |
| `iphone-running.png` | 1284 × 2778 | 1284 × 2778 (6.5" iPhone) |
| `ipad-configuration.png` | 2064 × 2752 | 2048 × 2732 (12.9" iPad) |
| `ipad-running.png` | 2064 × 2752 | 2048 × 2732 (12.9" iPad) |
| `mac-configuration.png` | 1280 × 2027 | 1280 × 800 minimum (Mac) |
| `mac-running.png` | 1280 × 2027 | 1280 × 800 minimum (Mac) |

**Mac screenshots** are exported by the Debug build itself (no Screen Recording permission required). Regenerate with:

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

The capture script uses the iPhone 16 Pro Max simulator (1320 × 2868 raw) and resizes to 1284 × 2778 for App Store Connect.

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

**Note:** Simulator captures may not match exact pixel dimensions. Resize or re-capture on the target device class if App Store Connect rejects them.

### Regenerating screenshots

Set the `CSCS_SCREENSHOT_MODE` environment variable when launching in Debug:

```bash
# Configuration screen
CSCS_SCREENSHOT_MODE=configuration

# Running screen
CSCS_SCREENSHOT_MODE=running
```

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
  - Name: **CSC Emulator**
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

- [ ] Open `CSCSEmulator/CSCSEmulator.xcodeproj` in Xcode
- [ ] Select **Any iOS Device (arm64)** or a connected device for archive (not Simulator)
- [ ] Product → Archive
- [ ] In Organizer: **Validate App** → fix any issues
- [ ] **Distribute App** → App Store Connect → Upload
- [ ] For Mac: ensure the Mac target is included in the archive or create a separate Mac archive if needed

### 4. Submit for Review

- [ ] In App Store Connect, select the uploaded build
- [ ] Answer export compliance (exempt — see above)
- [ ] Add **Review Notes** if helpful, for example:

  > CSC Emulator advertises as a BLE Cycling Speed and Cadence (CSCS) peripheral for testing and development. To test: launch the app, enable speed and/or cadence, tap Start Emulator, and scan for "CSCS emulator" from any CSCS-compatible central app. Bluetooth permission is required. No account or network access is needed.

- [ ] Submit for review

---

## Review Notes Template

```
CSC Emulator is a developer/testing utility that simulates a Bluetooth Low Energy
Cycling Speed and Cadence (CSCS) sensor.

How to test:
1. Launch the app on a physical iPhone or iPad (Bluetooth is not available in Simulator).
2. Enable Speed and/or Cadence on the configuration screen.
3. Tap "Start Emulator".
4. From a second device running any CSCS-compatible app, scan for a peripheral named
   "CSCS emulator" and connect.
5. Adjust speed/cadence sliders or switch modes (Pedaling, Coasting, Random).

The app collects no data and requires no account. Bluetooth permission is the only
permission requested.
```

**Important:** App Review testing of BLE requires a **physical device**. The Simulator cannot advertise as a BLE peripheral.

---

## Terminology Reference

- **Emulator** — product name (`CSC Emulator`, `CSCS BLE Emulator`, `CSCS emulator` BLE local name)
- **Simulated / simulation modes** — describes generated ride data and behavior, not a competing product name

---

## Out of Scope for v1.0

- Configurable concurrent connections ([issue #1](https://github.com/tonytallman/CSCS-emulator/issues/1))
- BLE state restoration
- Other items listed under Future Enhancements in README
