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
- [ ] Record a **screen recording** on a physical device (see [App Review Information](#app-review-information) below)
- [ ] Paste the full **Review Notes** template into App Store Connect → **App Review Information** → **Notes** (fill in device list and attach recording)
- [ ] Submit for review

---

## App Review Information

Apple may reject new submissions under **Guideline 2.1 — Information Needed** if the **Notes** field in App Store Connect does not include enough detail for reviewers to understand and test the app. Include all seven items below in every submission.

### Screen recording (item 1)

Capture on a **physical device** running the **latest OS**. Begin at app launch and show the typical user flow:

1. Launch CSC Emulator
2. Bluetooth permission prompt (if shown on first launch)
3. Configuration screen: enable Speed and/or Cadence
4. Tap **Start Emulator**
5. Running screen: switch between Pedaling, Coasting, and Random modes
6. Adjust speed/cadence sliders (Pedaling mode)
7. Tap **Stop Emulator**

**Not applicable to this app** (none of these features exist): account registration/login/deletion, paid content or subscriptions, user-generated content, location/contacts/camera/App Tracking Transparency prompts.

The only sensitive capability requested is Bluetooth (`NSBluetoothAlwaysUsageDescription`: "Advertises a simulated cycling speed and cadence sensor.").

Optional second-device verification: any CSCS-compatible app on another phone, tablet, or bike computer can scan for a peripheral named **CSCS emulator** and connect. This is not required to verify the app itself functions correctly.

**Important:** App Review testing of BLE requires a **physical device**. The Simulator cannot advertise as a BLE peripheral.

### Review Notes template (items 1–7)

Paste into App Store Connect → **App Review Information** → **Notes**. Replace the device list placeholder with your actual test hardware.

```
APP REVIEW INFORMATION — CSC Emulator v1.0

1. SCREEN RECORDING
A screen recording is attached to this submission (or was uploaded with this reply).
It was captured on a physical device running the latest OS and begins at app launch.

The recording demonstrates the full core user flow:
- Launch CSC Emulator
- Bluetooth permission prompt (if shown on first launch)
- Configuration screen: enable Speed and/or Cadence
- Tap "Start Emulator" to begin BLE advertising
- Running screen: switch between Pedaling, Coasting, and Random modes
- Adjust speed/cadence sliders (Pedaling mode)
- Tap "Stop Emulator" to return to configuration

Not applicable to this app (none of these features exist):
- Account registration, login, or account deletion
- Paid content, purchases, or subscriptions
- User-generated content, reporting, or blocking
- Location, contacts, camera, or App Tracking Transparency prompts

The only sensitive capability requested is Bluetooth (NSBluetoothAlwaysUsageDescription:
"Advertises a simulated cycling speed and cadence sensor.").

Optional second-device verification: any CSCS-compatible app on another phone, tablet,
or bike computer can scan for a peripheral named "CSCS emulator" and connect to
receive simulated speed/cadence data. This is not required to verify the app itself
functions correctly.


2. DEVICES AND OPERATING SYSTEMS TESTED
[PASTE YOUR TESTING NOTES HERE — e.g.:]

- iPhone [model], iOS [version]
- iPad [model], iPadOS [version]
- Mac [model], macOS [version]


3. APP PURPOSE AND TARGET AUDIENCE

CSC Emulator is a developer and testing utility that turns an iPhone, iPad, or Mac
into a virtual Bluetooth Low Energy (BLE) Cycling Speed and Cadence (CSCS) sensor.

Problem it solves:
Developers, QA engineers, and cyclists often need to test apps or bike computers that
read CSCS sensor data, but physical sensors are not always available during
development or review. CSC Emulator provides a controllable, standards-compliant
CSCS peripheral without dedicated hardware.

Target audience:
- iOS/macOS developers building cycling or fitness apps with BLE CSCS support
- QA teams verifying BLE sensor integrations
- Cyclists evaluating CSCS-compatible apps before purchasing a physical sensor

Value provided:
- Simulates speed (0–50 mph) and cadence (0–200 rpm) in real time
- Three modes: Pedaling (manual control), Coasting (speed decay), Random (natural
  cadence variation)
- Advertises the standard Bluetooth SIG Cycling Speed and Cadence Service
- Free, no account required, no data collection


4. SETUP AND TESTING INSTRUCTIONS

No login credentials, sample files, or external setup are required.

To test on a physical iPhone or iPad (Bluetooth is not available in Simulator):
1. Launch CSC Emulator.
2. If prompted, grant Bluetooth permission.
3. On the configuration screen, enable Speed and/or Cadence (at least one required).
4. Tap "Start Emulator."
5. On the running screen:
   - Use the mode picker: Pedaling, Coasting, or Random
   - In Pedaling mode, adjust speed and cadence sliders
   - In Coasting mode, observe cadence drop to 0 and speed decay
   - In Random mode, observe automatically varying cadence and derived speed
6. Tap "Stop Emulator" to end the session and return to configuration.

To verify BLE output (optional, second device):
- On another device running any CSCS-compatible central app, scan for a peripheral
  named "CSCS emulator" and connect. Speed and/or cadence measurements will update
  based on the selected mode and slider values.

macOS testing:
- Same steps as above. Bluetooth must be enabled in System Settings.


5. EXTERNAL SERVICES, TOOLS, AND PLATFORMS

None. CSC Emulator is fully self-contained and operates entirely on-device.

- No network access, servers, or cloud services
- No authentication providers
- No payment processors or subscriptions
- No analytics, crash reporting, or advertising SDKs
- No AI services or third-party data providers

Core functionality uses only Apple platform APIs:
- CoreBluetooth (BLE peripheral advertising and GATT service)
- SwiftUI (user interface)
- Standard Bluetooth SIG Cycling Speed and Cadence Service (0x1816)


6. REGIONAL DIFFERENCES

The app functions identically in all App Store territories. There are no region-
specific features, content, pricing tiers, or restrictions. All simulation modes
and BLE behavior are the same worldwide.


7. REGULATED INDUSTRY / PROTECTED THIRD-PARTY MATERIAL

Not applicable. CSC Emulator:
- Does not operate in a regulated industry (healthcare, finance, gambling, etc.)
- Does not include copyrighted media, licensed content, or protected third-party
  material
- Implements the publicly documented Bluetooth SIG Cycling Speed and Cadence
  Service specification for interoperability testing only
- Does not provide medical, fitness coaching, or health advice

No additional authorization documentation is required.
```

---

## Terminology Reference

- **Emulator** — product name (`CSC Emulator`, `CSCS BLE Emulator`, `CSCS emulator` BLE local name)
- **Simulated / simulation modes** — describes generated ride data and behavior, not a competing product name

---

## Out of Scope for v1.0

- Configurable concurrent connections ([issue #1](https://github.com/tonytallman/CSCS-emulator/issues/1))
- BLE state restoration
- Other items listed under Future Enhancements in README
