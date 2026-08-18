# Website updates — Bike Sensor Emulator

## Instructions for the website agent

You are updating [tallmansoftware.com](https://www.tallmansoftware.com/) so Bike Sensor Emulator copy matches the shipping app.

Apply only the tasks below. Do not redesign unrelated pages or invent features.

Preserve the live site’s voice and layout; change facts, names, ranges, platforms, and missing sections — not marketing tone.

Prefer the **Proposed copy** blocks; adapt only to match surrounding voice.

## Canonical facts

| Fact | Value |
| --- | --- |
| Product name | Bike Sensor Emulator |
| Home-screen name | Bike Sensor |
| BLE advertised name | Localized; English is `CSCS Emulator`. The acronym **CSCS** is never translated |
| App Store listing name | Bike Sensor Emulator (not “CSC Emulator”) |
| Platforms | iPhone, iPad, and Apple Silicon Mac (iPad app on Mac) |
| Manual slider ranges | Speed 0–50 mph; cadence 0–200 rpm |
| Random mode | Cadence varies around ~90 rpm; speed is derived from cadence |
| BLE connections | One central at a time |
| Background | Continues advertising on iPhone and iPad while the app runs in the background |
| Price / privacy | Free; no data collected |
| GitHub | https://github.com/tonytallman/CSCS-emulator |
| App Store URL | Use the existing “View on the App Store” URL already on the live site (numeric ID is not stored in the app repo) |
| Version checked | Marketing version **1.2**, build **6** |
| Localizations | App UI: English, Spanish, Simplified Chinese, Traditional Chinese, Japanese, German, French, Portuguese (Brazil), Korean, Italian |

## Scope

Touch only:

- `https://www.tallmansoftware.com/`
- `https://www.tallmansoftware.com/projects/`
- `https://www.tallmansoftware.com/projects/bike-sensor-emulator`

Out of scope: home services/about, contact, unrelated projects, visual redesign, new case studies.

## Per-page tasks

### `/` (home — Featured project)

**Status:** live but stale

**Current copy:**

> Bike Sensor Emulator
>
> Virtual cycling sensor
>
> A virtual Bluetooth Low Energy sensor that emulates a Cycling Speed and Cadence (CSC) peripheral — no dedicated hardware required.
>
> iPhone, iPad, and Apple Silicon Mac (iPad app on Mac)

**Task:** Update

**Proposed copy:**

> Bike Sensor Emulator
>
> Virtual cycling sensor
>
> A virtual Bluetooth Low Energy sensor that emulates a Cycling Speed and Cadence (CSCS) peripheral — no dedicated hardware required.
>
> iPhone, iPad, and Apple Silicon Mac (iPad app on Mac)

**Must include:** product name Bike Sensor Emulator; CSCS (not CSC); iPhone, iPad, and Apple Silicon Mac (iPad app on Mac).

**Must not claim:** ANT+, multiple sensors, that the App Store listing is still named CSC Emulator.

### `/projects/`

**Status:** live but stale

**Current copy:** same card as the home Featured project (CSC, not CSCS).

**Task:** Update (keep the card short; match the home card)

**Proposed copy:** same as the home Featured project proposed copy above.

**Must include / must not claim:** same as home.

### `/projects/bike-sensor-emulator` (case study)

**Status:** live but stale

**Current copy (verbatim excerpts):**

> Virtual cycling sensor. A native app that emulates a standard Cycling Speed and Cadence (CSC) Bluetooth sensor — no dedicated hardware required.
>
> App Store listing currently appears as CSC Emulator.
>
> Bike Sensor Emulator turns an iPhone or iPad into a virtual BLE cycling sensor. It emulates the Bluetooth SIG Cycling Speed and Cadence Service (CSCS), so apps and bike computers that support the standard can connect and receive simulated speed and cadence data. The iPad app also runs on Apple Silicon Macs via “iPhone and iPad Apps on Mac.”
>
> The app is free, collects no data, and runs as a single native codebase on iphone, ipad, and apple silicon mac (ipad app on mac).

**Task:** Update

**Proposed copy:**

**Hero / tagline**

> Virtual cycling sensor. A native app that emulates a standard Cycling Speed and Cadence (CSCS) Bluetooth sensor — no dedicated hardware required.

Remove the line “App Store listing currently appears as CSC Emulator.” The App Store listing name is **Bike Sensor Emulator**. Home screen: **Bike Sensor**. BLE advertised name: **CSCS Emulator** (localized; CSCS never translated).

**What is it**

> Bike Sensor Emulator turns an iPhone or iPad into a virtual BLE cycling sensor. It emulates the Bluetooth SIG Cycling Speed and Cadence Service (CSCS), so apps and bike computers that support the standard can connect and receive simulated speed and cadence data. The iPad app also runs on Apple Silicon Macs via “iPhone and iPad Apps on Mac.”
>
> The app is free, collects no data, and runs as a single native codebase on iPhone, iPad, and Apple Silicon Mac (iPad app on Mac). The interface is localized in English, Spanish, Simplified Chinese, Traditional Chinese, Japanese, German, French, Portuguese (Brazil), Korean, and Italian. The Bluetooth SIG acronym CSCS is never translated.

**Engineering challenge** — keep the existing architecture paragraphs. Type names `CSCPeripheralManager`, `CSCSMeasurementEncoder`, `CentralSubscriptionTracker`, `SimulationEngine`, and `AppContainer` are still accurate. No change required unless surrounding copy still says CSC instead of CSCS.

**How it behaves** — current bullets are accurate (metrics lock, Random ~90 rpm, Manual 0–50 mph / 0–200 rpm, one central, background advertising, Bluetooth errors). No change required.

**Result**

> Bike Sensor Emulator is live on the App Store as Bike Sensor Emulator — free, no account required, no data collected. It is published under Tallman Software and available at apps.apple.com. Nearby devices see the BLE peripheral as CSCS Emulator (localized; CSCS never translated). The home-screen label is Bike Sensor.

**Must include:** CSCS (not CSC) for the Bluetooth service; App Store name Bike Sensor Emulator; home-screen name Bike Sensor; BLE name CSCS Emulator; iPad-on-Mac; free / no data collected; UI localized in the ten languages listed (English plus nine translations).

**Must not claim:** that the App Store listing still appears as CSC Emulator; ANT+; multiple concurrent sensors; FTMS.

## What's New that the site should reflect

From App Store 1.2 (6):

- **Localization** — the UI now ships in nine languages besides English. Mention this on the case study (see proposed “What is it” paragraph). Home and `/projects/` cards can stay short; do not cram a language list onto the cards.
- **Scroll bounce** — when content already fits on screen, the UI no longer rubber-bands. Too minor for website copy; skip.

## Assets

Fresh App Store screenshots are in `documentation/screenshots/` (`iphone-configuration.png`, `iphone-running.png`, `ipad-configuration.png`, `ipad-running.png`). A human attaches them if the case study or cards use screenshots. Do not embed binaries from this brief.
