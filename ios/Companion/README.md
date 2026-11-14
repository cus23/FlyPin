# FlyPin Companion (iOS)

This is the native companion for the existing FlyPin GitHub Pages website. The website remains the map and coordinate-selection interface; this app handles iPhone-side pairing and developer-service communication.

## Current scope

- SwiftUI iOS app skeleton (Xcode 26 project generated with XcodeGen)
- URL handoff: `flypin-companion://set-location?lat=25.033&lon=121.565`
- Coordinate range validation
- Local pairing-file import with iOS file protection, POSIX mode 0600, and backup exclusion
- Explicit LocalDevVPN app handoff
- Pinned, SHA-256-verified `idevice` FFI dependency fetched only during the macOS build
- RSD developer-tunnel connection implementation (requires an imported pairing record and a working LocalDevVPN tunnel)
- Unsigned app package published to a persistent GitHub pre-release

## Not implemented yet

**This build does not yet change the iPhone's system location.** Developer Disk Image acquisition, device-build matching, image signature/integrity validation, personalized image mounting, and end-to-end physical-device testing are still required before enabling location simulation. Start and Stop remain disabled until those steps are implemented and verified.

## Windows + iPhone workflow

You do not need a Mac on your Windows PC. GitHub Actions uses a hosted macOS runner with Xcode 26 to build the app. The latest unsigned build is published to:

https://github.com/cus23/FlyPin/releases/tag/companion-latest

The release contains `FlyPinCompanion-unsigned.zip` and `SHA256SUMS.txt`. The release is retained until it is manually deleted; it is separate from the seven-day Actions artifact.

**Important:** the ZIP contains an unsigned `.app`, not an installable IPA. Installing it on an iPhone requires code signing and a provisioning profile. A Windows PC can download and keep the release, but cannot replace Apple's signing/provisioning requirements.

## Build locally

Requires macOS with Xcode 26 and XcodeGen:

```sh
./scripts/fetch-idevice.sh
brew install xcodegen
xcodegen generate
xcodebuild -project FlyPinCompanion.xcodeproj -scheme FlyPinCompanion \
  -sdk iphoneos -configuration Debug \
  -destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO build
```

## Security rules

- Never commit a pairing file, UDID, Apple ID credential, signing certificate, or provisioning profile.
- Never put pairing contents in URLs, logs, analytics, issues, or build artifacts.
- Treat Developer Support files as supply-chain inputs: pin the source revision and verify published hashes before mounting.
- Do not report a location as active unless the DVT service confirms the operation.
- iOS Developer Mode is required for the intended developer-service path.
- LocalDevVPN's app-open callback is not proof that its tunnel is connected.
- iOS may suspend the companion app; persistent background operation is not guaranteed.
