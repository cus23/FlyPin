# FlyPin Companion (iOS)

Native companion for the existing FlyPin map website. The website selects coordinates; this app connects to the iPhone's developer services and applies them through DVT location simulation.

## Implemented in this branch

- SwiftUI iOS companion and `flypin-companion://set-location?lat=25.033&lon=121.565` handoff
- Secure local pairing-file import
- LocalDevVPN handoff and RSD tunnel setup
- Pinned `idevice` FFI dependency with Git object verification
- Pinned Cryptex Developer Disk Image assets with Git object verification
- Cryptex DDI installation through `cryptexd` (Apple personalization/TSS required)
- DVT location simulation set and clear calls
- Website-to-iPhone handoff, including a QR path for Windows desktop browsers
- Persistent GitHub pre-release for the latest unsigned app

## Intended use flow

1. On Windows, install iTunes (the USB device support required by the pairing utility). For iOS 26, use the [idevice_pair 0.1.14 Windows build](https://github.com/jkcoxson/idevice_pair/releases/download/0.1.14/idevice_pair--windows-x86_64.exe) as the compatibility fallback. Its release predates the v1.0 rewrite and includes the RPPairing workflow. The newer [v1.1.0 build](https://github.com/jkcoxson/idevice_pair/releases/download/v1.1.0/idevice_pair--windows-x86_64.exe) also documents USB RPPairing for iOS 17.4+, but use 0.1.14 if v1.1.0 fails on your Windows/iPhone setup.
2. Connect the iPhone by USB, unlock it, and tap **Trust** if prompted. In idevice_pair 0.1.14, select the iPhone and click **Generate** to create the RPPairing record (the 0.1.14 GUI labels the RPPairing path as Generate). Save/export that generated record to a file. Do not use a Lockdown-only record.
3. Transfer the pairing file to the iPhone using iCloud Drive or another private file-transfer method.
4. Install FlyPin Companion and [LocalDevVPN from the App Store](https://apps.apple.com/app/id6755608044) on the iPhone. Import the RPPairing file in Companion.
5. Open LocalDevVPN, enable its tunnel, then return to Companion.
6. Tap **Connect & Prepare** once. Companion creates the RSD tunnel, downloads and verifies the pinned Cryptex DDI assets, then asks Apple's TSS service to personalize/install the DDI.
7. Open FlyPin on the iPhone in Safari and use **Send location to iPhone**. If using the Windows browser, scan the generated QR code with the iPhone camera and tap the handoff page's button.
8. Companion receives the coordinate and applies it through DVT. Later location changes can be sent from the same index page. Use Stop to clear the simulation.

The pairing record is sensitive. Keep it out of GitHub, screenshots, chat messages, and shared folders. The USB step is only for initial pairing; later sessions use the LocalDevVPN/RSD path over the supported network.

## Windows + iPhone build workflow

No Mac is required on the Windows PC. GitHub Actions uses a hosted macOS runner and Xcode to build the unsigned app. The latest package is published at:

https://github.com/cus23/FlyPin/releases/tag/companion-latest

The Release contains an unsigned `.app` archive, an unsigned `.ipa` package for Windows sideloading tools, and SHA256 checksums. It is retained until manually deleted, unlike the seven-day Actions artifact.

**The IPA is not signed.** On Windows, use a trusted sideloading/signing utility with your own Apple ID to sign and install it locally. Do not upload Apple ID credentials, signing certificates, or provisioning profiles to this repository or GitHub Actions. Apple's normal signing and provisioning rules still apply.

## Compatibility and limits

- Requires iOS Developer Mode and an existing RPPairing record for the same iPhone.
- Cryptex DDI installation requires network access to Apple's personalization service (TSS).
- LocalDevVPN's app-open callback does not prove that its tunnel is active; the RSD connection itself is the readiness check.
- DVT simulation may be detected or ignored by apps that reject software location simulation or use independent location signals.
- iOS may suspend the companion app. Reopen it if the developer connection drops.
- A successful CI build is not proof of physical-device compatibility. Real iOS 26 hardware testing remains necessary.

## Security

- Pairing data stays in the iOS app's protected local storage and is never put in URLs, logs, GitHub artifacts, or source control.
- Developer Image downloads are pinned to immutable source revisions and verified before use.
- Never report a coordinate as active unless the DVT call returns successfully.
