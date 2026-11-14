# FlyPin — First-Time Deployment & User Guide

> This guide describes the current Windows + iPhone deployment flow for FlyPin.
>
> **Important:** FlyPin uses Apple's developer location-simulation services (DVT/LocationSimulation). It is a development/testing workflow, not a permanent GPS modification. Some apps can detect software-simulated locations or reject them.

## 1. What FlyPin consists of

FlyPin has three parts:

1. **FlyPin Web** — the map and location picker hosted on GitHub Pages. Use it to search for a place, choose a point, and send coordinates.
2. **FlyPin Companion** — the iOS app installed on the iPhone. It imports the device pairing record, prepares the developer connection, receives coordinates from the website, and controls the DVT location-simulation session.
3. **LocalDevVPN** — an auxiliary iOS app/runtime dependency used by the current Companion workflow to expose the local developer-service connection. It is not the location engine itself.

The website cannot directly access Apple's private developer services from Safari. Therefore, **the Companion must remain installed**. The intended daily workflow can be web-first, but it is not currently a web-only implementation with the Companion removed.

## 2. Supported setup and requirements

### Computer

- Windows 10/11, 64-bit.
- Internet access for downloads and initial setup.
- A data-capable USB cable.
- Apple's Windows device support installed. Use the current Apple Devices app or an Apple iTunes distribution that includes Apple Mobile Device Support. Avoid installing multiple conflicting Apple device-management packages.
- Sideloadly for signing and installing the unsigned Companion IPA.

### iPhone

- An iPhone running a supported iOS version. The current project workflow has been developed around iOS 26; compatibility with other iOS versions is not guaranteed without device testing.
- Developer Mode enabled: **Settings → Privacy & Security → Developer Mode**. Follow the restart and confirmation prompts.
- Trust This Computer accepted when connecting over USB.
- LocalDevVPN installed from the App Store if the current Companion build prompts for or launches it.

### Downloads

| Item | Purpose | Download |
|---|---|---|
| FlyPin Companion IPA | iOS app package; install this on iPhone | [Latest Companion release](https://github.com/cus23/FlyPin/releases/tag/companion-latest) — download `FlyPinCompanion-unsigned.ipa` |
| Sideloadly | Sign and install the unsigned IPA from Windows | [sideloadly.io](https://sideloadly.io/) |
| idevice_pair for Windows | Create/verify the iPhone remote-pairing record | [idevice_pair 0.1.14 release](https://github.com/jkcoxson/idevice_pair/releases/tag/0.1.14) |
| LocalDevVPN | Auxiliary local developer-service bridge used by the current Companion workflow | [App Store](https://apps.apple.com/app/id6755608044) |
| FlyPin Web | Daily location picker | [cus23.github.io/FlyPin](https://cus23.github.io/FlyPin/) |

Download only the IPA asset from the FlyPin release. The ZIP/source archives are not the file to drag into Sideloadly.

## 3. First-time deployment

### Step 1 — Prepare the iPhone

1. Install any available iOS updates only if you intend to do so; do not update just to troubleshoot FlyPin without checking compatibility.
2. Open **Settings → Privacy & Security → Developer Mode**.
3. Turn Developer Mode on.
4. Accept the restart prompt.
5. After reboot, unlock the iPhone and confirm Developer Mode.
6. Install LocalDevVPN if the Companion workflow requires it. Be aware that starting a VPN-based bridge may disconnect an already active VPN.

### Step 2 — Install Windows device support

1. Install Apple's current Windows device support (Apple Devices, or an iTunes package that includes Apple Mobile Device Support).
2. Connect the iPhone using a data-capable USB cable.
3. Unlock the iPhone.
4. Tap **Trust** if iOS asks whether to trust this computer.
5. Keep the iPhone unlocked during pairing and initial setup.

If Windows cannot detect the phone, first check the cable, USB port, Apple device support, and whether the iPhone is unlocked. Do not repeatedly regenerate pairing records to fix a USB transport problem.

### Step 3 — Create the pairing record

1. Download the Windows x64 `idevice_pair` executable from the 0.1.14 release linked above.
2. Run it with the iPhone connected by USB.
3. Select the connected iPhone.
4. Choose the **RPPairing** workflow.
5. Select **Generate** and complete the on-device prompts, if any.
6. Run **Validation** / **Verify RPPairing file over USB**.
7. Continue only when validation reports success.
8. Copy the complete newly generated pairing plist content into Windows Notepad if the tool does not provide a Save/Export button.
9. In Notepad, choose **File → Save As**:
   - File name: `FlyPinPairing.plist`
   - Save as type: **All files**
   - Encoding: **UTF-8**
10. Confirm the filename ends in `.plist`, not `.plist.txt`.

**Pairing record security**

- The plist contains private pairing credentials. Treat it like a password.
- Never paste it into chats, issues, pull requests, public repositories, or screenshots.
- Do not commit it to Git.
- Use only the newest pairing record generated after any earlier record was exposed or regenerated.
- Store it locally in a private folder and delete temporary copies when no longer needed.
- Import it through the Companion's file-import flow; do not place it in a public URL or QR code.

### Step 4 — Install FlyPin Companion

1. Open the [FlyPin Companion release page](https://github.com/cus23/FlyPin/releases/tag/companion-latest).
2. Download **`FlyPinCompanion-unsigned.ipa`** to Windows.
3. Install and open Sideloadly from its official website.
4. Connect and unlock the iPhone over USB.
5. Drag the IPA into Sideloadly.
6. Select the connected iPhone as the target device.
7. Enter the Apple ID in Sideloadly only. Never send Apple ID credentials to anyone or commit them to the repository.
8. Press **Start** and complete any Apple authentication prompts.
9. Wait for Sideloadly to report successful installation.
10. If iOS blocks the app, follow the on-device developer-app trust prompt under **Settings → General → VPN & Device Management**. Keep Developer Mode enabled.

**Signing note:** With a free Apple ID, sideloaded app provisioning commonly expires after seven days and may need to be refreshed/re-signed. Sideloadly's automatic refresh depends on its configuration and the computer/device being available. If the app stops opening after expiry, reinstall or refresh the signature; do not regenerate the pairing record unless pairing itself is invalid.

### Step 5 — Import the pairing plist into Companion

1. Transfer `FlyPinPairing.plist` to the iPhone using a private method (for example, USB file transfer or a trusted private cloud drive).
2. Save it in the iPhone **Files** app.
3. Open **FlyPin Companion**.
4. Use the pairing-file import control.
5. Select the plist from Files.
6. Wait for the app to validate/import it. Do not share the file with the website.

### Step 6 — Prepare the developer connection

1. Keep the iPhone unlocked and connected to Windows by USB for this first preparation.
2. Open FlyPin Companion.
3. Start the device preparation flow.
4. Allow the app to start its required local bridge/developer-service connection.
5. Wait until Companion displays:

   **“Device is ready. You can now select a location from the FlyPin website and apply it.”**

6. If the app reports a connection or Cryptex/DDI error, do not delete system files or regenerate pairing data immediately. Restart the iPhone once, reconnect USB, and retry. If the same error persists, capture the exact error text with pairing secrets redacted.

A successful pairing-file validation alone does not mean the developer image is mounted. The Companion's **ready** state is the checkpoint for proceeding to a location test.

## 4. First location test

1. On the iPhone, open Safari.
2. Visit [FlyPin Web](https://cus23.github.io/FlyPin/).
3. Search for a recognizable test location (for example, Taipei 101) or tap the map.
4. Select the desired coordinate.
5. Tap **Send location to iPhone**.
6. iOS should open FlyPin Companion using its URL scheme.
7. Review the coordinate in Companion and apply it.
8. Open Apple Maps or another location-aware app to check whether the simulated coordinate is reflected.

The website passes coordinates to Companion; it does not itself perform the iOS location simulation.

## 5. Daily operation — intended web-first workflow

After initial pairing and installation:

1. Keep FlyPin Companion installed on the iPhone.
2. Make sure the iPhone and the computer/network path required by the current bridge are available. For a wireless session, the phone and host-side service must be reachable over the same permitted network; Wi-Fi client isolation, VPN routing, firewalls, or guest networks can block it.
3. Open FlyPin Companion and check that its status is ready/connected. If the app requires a start/prepare action, perform it before sending a coordinate.
4. Open FlyPin Web in iPhone Safari.
5. Select a location and tap **Send location to iPhone**.
6. Companion receives the coordinate and applies it.
7. Repeat from the website whenever you want to change location.

### Can the USB cable be disconnected?

Usually, the USB cable is needed for initial trust/pairing and setup, not necessarily for every later session. However, wireless operation must be tested on the actual device and network.

**Safe test:**

1. First confirm one successful location change while USB is connected.
2. Leave Companion installed and its session active.
3. Disconnect the USB cable.
4. Keep the iPhone and required host/network components on the same reachable Wi-Fi network.
5. Return to FlyPin Web, select a different test coordinate, and send it again.
6. Confirm Companion applies the new coordinate.

If the wireless test fails, reconnect USB and check Companion's connection status. Do not assume that a successful USB preparation automatically proves wireless DVT connectivity.

## 6. Reboot, app closure, and recovery

- **iPhone reboot:** The developer-service/DDI state or active DVT session may need to be prepared again after a reboot. Open Companion and check its status; prepare again if it is no longer ready.
- **Companion force-quit:** Force-quitting the app can end its active keepalive/session. Reopen it and prepare/reconnect before sending another coordinate.
- **Companion background suspension:** iOS may suspend or terminate background work. A location session is not guaranteed to survive indefinitely in the background.
- **Wi-Fi/VPN change:** Changing networks, enabling another VPN, or losing connectivity can interrupt the developer connection. Restore the required network path and reconnect.
- **Sideload expiry:** If Companion no longer launches, refresh/re-sign it with Sideloadly. Pairing data normally does not need to be regenerated just because the signing profile expired.
- **Pairing errors:** Regenerate pairing only if the pairing record is actually invalid, revoked, or no longer accepted. Keep the new record private.

## 7. Can Companion be deleted? Can FlyPin be web-only?

**Not with the current architecture.**

The web page is the user interface and coordinate picker. Safari cannot directly open Apple's DVT LocationSimulation developer service. FlyPin Companion is the on-device bridge that imports the pairing credentials, manages the developer connection, and sends the location command.

Therefore:

- You can use the **website as the main interface** for choosing locations.
- You still need **FlyPin Companion installed** to receive and apply coordinates.
- If you delete Companion, the website's handoff has no local app to receive the coordinates and the current workflow will stop working.
- A true browser-only solution would require a different architecture and a supported system-level service; an ordinary web page cannot replace the Companion's privileged developer-service bridge.

## 8. Limitations and troubleshooting

| Symptom | Meaning / next check |
|---|---|
| Pairing validation fails | Check that the selected plist is the newest one, complete, and belongs to this iPhone. Check USB trust and connection. |
| `Socket(Kind(NotConnected))` | USB/usbmux or device connection dropped. Reconnect, unlock, trust, and retry before changing pairing data. |
| `Cryptexd ... /System/Developer [17: File exists]` | The mount path already exists; a previous or concurrent DDI/Cryptex install may have left a state. Restart the iPhone once and retry. Do not manually delete system paths. |
| Companion says device is not ready | Reopen Companion, restore the required network/bridge, and run preparation again. |
| Website does not open Companion | Use Safari on iPhone, not a desktop browser. Confirm Companion is installed and its URL scheme is registered. |
| Coordinate is not reflected | Confirm Companion received and applied the coordinate; test in another location-aware app. Some apps reject simulated locations. |
| Works on USB but not Wi-Fi | Check same-network reachability, client isolation, VPN/firewall routing, and Companion connection status. |

### Important behavioral limitations

- iOS identifies this as software-simulated location. Apps can inspect simulation metadata or compare IP, Wi-Fi, cellular, time-zone, and motion signals.
- Some apps may ignore or reject simulated coordinates.
- The active session can stop after reboot, app termination, background suspension, network interruption, or signing expiry.
- This project is intended for authorized development and testing. Follow the terms and rules of apps and services being tested.

## 9. Security checklist

- [ ] Pairing plist is stored privately and is not committed to Git.
- [ ] Apple ID credentials are entered only into Sideloadly's own UI.
- [ ] Developer Mode is enabled.
- [ ] Companion is installed and opens successfully.
- [ ] Pairing plist is imported into Companion.
- [ ] Companion reports the device is ready.
- [ ] One location change has been tested.
- [ ] Wireless operation has been tested before relying on cable-free use.
