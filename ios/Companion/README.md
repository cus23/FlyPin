# FlyPin Companion (iOS)

This is the first native-app scaffold for FlyPin. It is deliberately separate from the existing GitHub Pages site.

## Current scope

- SwiftUI iOS app skeleton (Xcode 26 project generated with XcodeGen)
- URL handoff: `flypin-companion://set-location?lat=25.033&lon=121.565`
- Coordinate range validation
- Local pairing-file import with iOS file protection, POSIX mode 0600, and backup exclusion
- Explicit LocalDevVPN app handoff
- Fail-closed placeholder for DVT start/stop

## Not implemented yet

**This build does not change the iPhone's system location.** The DVT/RSD transport, Developer Disk Image acquisition and integrity verification, tunnel readiness check, and real start/move/clear calls are not integrated. Start and Stop are disabled on purpose.

## Build

Requires macOS with Xcode 26 and XcodeGen:

```sh
brew install xcodegen
cd ios/Companion
xcodegen generate
xcodebuild -project FlyPinCompanion.xcodeproj -scheme FlyPinCompanion \
  -sdk iphoneos -configuration Debug \
  -destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO build
```

The GitHub Actions workflow builds the unsigned `.app` bundle and uploads it as a short-lived artifact (7-day retention). It does not export an IPA. Installing the app on a physical iPhone still requires a valid signing and provisioning method; an unsigned build is not directly installable.

## Security rules

- Never commit a pairing file, UDID, Apple ID credential, signing certificate, or provisioning profile.
- Never put pairing contents in URLs, logs, analytics, issues, or build artifacts.
- Treat Developer Support files as supply-chain inputs: pin the source revision and verify published hashes before mounting.
- Do not report a location as active unless the DVT service confirms the operation.
- iOS Developer Mode is required for the intended developer-service path.
