# Fast Tunnel

Fast Tunnel v1.0 is a Flutter network and internet testing utility. The store-facing functional positioning is **Fast Tunnel: Network Test**.

## Current Release

- Network/Internet Test: Available
- VPN: Coming Soon / not implemented

## What Version 1.0 Does

- Runs user-triggered network diagnostics.
- Looks up the current public IP.
- Measures HTTPS latency using lightweight repeated requests.
- Calculates average latency, minimum latency, maximum latency, jitter, and request failure rate.
- Checks DNS resolution and HTTPS reachability.
- Calculates a transparent network score from real measured values.
- Stores completed test history locally on the device, capped at 50 records.
- Supports Google Mobile Ads with embedded in-app configuration.

## What Version 1.0 Does Not Do

- It does not provide VPN functionality.
- It does not establish a system-level VPN connection.
- It does not route device traffic through a VPN, proxy, or traffic tunnel.
- It does not modify DNS settings.
- It does not change the public IP.
- It does not inspect, intercept, or collect user traffic through VPN functionality.
- It does not request VPN entitlements, NetworkExtension capabilities, or packet tunnel targets.

## App Review Clarification

The current version of Fast Tunnel does not implement VPN functionality. It performs user-triggered network diagnostics only. It does not establish a system-level VPN connection, route traffic through a VPN, or collect user traffic through VPN functionality.

## Network Test Methodology

The score is calculated from real diagnostic values:

- Latency: 45%
- Jitter: 25%
- Request failure rate: 20%
- DNS and HTTPS reachability: 10%

Latency is measured with lightweight HTTPS requests. Jitter is the average variation between successful latency samples. Failed requests contribute to request failure rate. DNS and HTTPS checks are direct reachability diagnostics.

Default accuracy is `Accurate`, which performs 30 latency attempts. Available modes:

- Fast: 10 attempts
- Balanced: 20 attempts
- Accurate: 30 attempts
- Maximum: 40 attempts

## Diagnostic Endpoints

The app uses lightweight HTTPS endpoints for reachability and latency:

- `https://www.google.com/generate_204`
- `https://www.cloudflare.com/cdn-cgi/trace`
- `https://cp.cloudflare.com/generate_204`

Public IP lookup uses:

- `https://api.ipify.org?format=json`

No large files are downloaded for latency testing.

## Package Identifiers

- Android applicationId: `com.fasttunnel.networktest`
- iOS bundle identifier: `com.zyverio.fasttunnel`
- Flutter package name: `fast_tunnel_network_test`

Bundle identifiers generally cannot be changed after an app is published.

## Architecture

The Flutter code is feature-first under `lib/src`.

- `app`: GoRouter routes, app root, and theme.
- `core/storage`: shared preferences provider.
- `core/widgets`: shared action buttons, badges, empty/error states, and dialogs.
- `core/ads`: AdMob configuration, services, controllers, and widgets.
- `features/network_test`: network diagnostics service, result models, and controller.
- `features/history`: local completed test history repository, controller, list, and result details.
- `features/settings`: persisted settings repository and screen.
- `features/public_ip`: reusable public IP parsing support.
- `features/legal`: About, Methodology, Privacy Policy, and Terms of Use.
- `features/tunnel`: future-only tunnel abstractions retained for later native work, not used by the current production navigation.

## Windows Setup

1. Install Flutter stable for Windows.
2. Install Android Studio and the Android SDK.
3. Confirm `android/local.properties` points to your local SDKs:

   ```properties
   sdk.dir=C:\\Users\\hp\\AppData\\Local\\Android\\Sdk
   flutter.sdk=C:\\Development\\flutter
   ```

4. Install dependencies:

   ```powershell
   flutter pub get
   ```

5. Check the toolchain:

   ```powershell
   flutter doctor
   ```

Xcode is not required for Android development on Windows.

## Android Testing

Connect an Android device or start an emulator:

```powershell
flutter devices
flutter run -d <device-id>
```

Run the local quality gate:

```powershell
dart format .
flutter pub get
flutter analyze
flutter test
flutter build apk --debug
```

The debug APK is generated at:

```text
build\app\outputs\flutter-apk\app-debug.apk
```

## Advertising

Fast Tunnel uses `google_mobile_ads` version `^9.0.0`.

iOS ads are enabled directly inside the app through embedded AdMob configuration:

- App Open: `ca-app-pub-7416708332505708/6203802459`
- Banner: `ca-app-pub-7416708332505708/7648746066`
- Interstitial: `ca-app-pub-7416708332505708/4511446833`

Native and rewarded ads are configured but disabled in version 1.0.

Android currently uses official Google test ads because Android production AdMob IDs have not been provided. Do not publish Android with test ad identifiers.

Interstitial ads must not be shown while a network test is running or while results are being calculated.

## Codemagic And iOS

The iOS project is kept structurally valid for Codemagic TestFlight builds.

Preserved settings:

- Bundle ID: `com.zyverio.fasttunnel`
- iOS deployment target: `15.0`
- CocoaPods-based plugin integration
- Swift Package Manager disabled for Flutter plugin integration
- Existing signing and App Store Connect integration

Windows cannot verify an iOS archive locally. Use Codemagic for iOS archive and TestFlight verification.

## iOS Capability Audit

Version 1.0 intentionally avoids:

- NetworkExtension framework usage for VPN
- `NEVPNManager`
- `NEPacketTunnelProvider`
- Packet Tunnel Provider targets
- Personal VPN entitlement
- Network Extension entitlement
- proxy routing
- DNS modification
- traffic tunneling
