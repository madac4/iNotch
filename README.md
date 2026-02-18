# iNotch

iNotch is a macOS menu bar utility that brings an interactive notch-like HUD for:

- Volume changes
- Battery status
- Bluetooth connectivity updates (AirPods/headphones and similar devices)
- Now Playing controls

The app uses Sparkle for in-app updates and publishes releases through GitHub + `appcast.xml`.

## Current Version

- Marketing version: `1.3.0`
- Build number: `5`
- Minimum system version: macOS `26.0`

## Features

- Dynamic notch UI with open/closed states
- Configurable settings sections:
  - General
  - Battery
  - Connectivity
  - Sound
  - Now Playing
- Bluetooth battery and connection notifications
- Menu bar app behavior with optional Dock visibility
- Sparkle updater integration (`Check for Updates`)

## Tech Stack

- Swift / SwiftUI
- Xcode project (`iNotch.xcodeproj`)
- Sparkle (via Swift Package Manager)
- Defaults library (settings persistence)

## Repository Structure

- `iNotch/` - app source code
- `iNotch.xcodeproj/` - Xcode project
- `mediaremote-adapter/` - local framework/helper integration
- `appcast.xml` - Sparkle update feed
- `scripts/` - release helper scripts for signing/appcast updates
- `sparkle-tools/` - Sparkle tooling sources

## Build and Run

1. Open `iNotch.xcodeproj` in Xcode.
2. Select the `iNotch` target and run with a macOS destination.
3. Build configuration notes:
   - Signing identity is currently `Apple Development` for local builds.
   - Hardened runtime is enabled.

## Permissions and Entitlements

iNotch uses:

- Bluetooth access
- Apple Events automation for:
  - `com.apple.Music`
  - `com.spotify.client`
- Network client access (Sparkle feed/downloads)

Entitlements are defined in `iNotch/iNotch.entitlements`.

## Auto-Update Setup (Sparkle)

Configured in `iNotch/Info.plist`:

- `SUFeedURL` points to the repository `appcast.xml` on `main`
- `SUPublicEDKey` is included for Sparkle signature verification

Release metadata lives in `appcast.xml` and must include:

- `sparkle:version` (build number)
- `sparkle:shortVersionString` (marketing version)
- `sparkle:minimumSystemVersion`
- `enclosure` URL, size, and `sparkle:edSignature`

## Release Workflow

1. Update version/build in Xcode:
   - `MARKETING_VERSION` (for example `1.3.1`)
   - `CURRENT_PROJECT_VERSION` (increment integer)
2. Archive in Xcode:
   - `Product -> Archive`
   - `Distribute App -> Developer ID`
3. Notarize and export app.
4. Create DMG from exported `.app`.
5. Notarize + staple DMG.
6. Upload DMG to GitHub Releases.
7. Update `appcast.xml` top item with:
   - release notes
   - GitHub DMG URL
   - real `length`
   - real `sparkle:edSignature`
8. Push `appcast.xml` to `main`.

## Notes

- `appcast.xml` should always keep newest release at the top of `<channel>`.
- For production distribution on other Macs, use Developer ID signing + notarization, not quarantine-removal workarounds.
