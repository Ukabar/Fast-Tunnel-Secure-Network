# Fast Tunnel

Fast Tunnel v1.0 is a private Flutter interface prototype for selecting a location and managing a simulated connection session. Store metadata should be revised before any public release.

This build is **not a real VPN**. It does not route traffic, change DNS, change public IP, hide identity, encrypt device traffic, or install native VPN capabilities. The simulated service exists so the interface can be tested before native tunnel work begins.

## What Version 1.0 Does

- Shows a tunnel-focused Home screen.
- Lets users select a preferred location.
- Supports favorites and alphabetical location browsing.
- Starts, cancels, retries, and ends simulated connection sessions.
- Shows elapsed session time and a session identifier.
- Looks up the current public IP as an informational value.
- Stores local session history, capped at 100 records.
- Stores theme, animation, selected location, and favorite preferences locally.
- Supports Android-only Google Mobile Ads placements controlled by remote JSON.
- Keeps About, Privacy Policy, Terms of Use, and optional future features pages.

## What Version 1.0 Does Not Do

- It does not provide an active VPN or real tunnel.
- It does not implement NetworkExtension, WireGuard, OpenVPN, proxy routing, packet tunneling, traffic interception, DNS modification, or IP changes.
- It does not request VPN entitlements or add packet tunnel targets.
- It does not claim protected traffic, encrypted traffic, anonymous browsing, hidden IP, or routed traffic.
- It does not include StoreKit, Google Play Billing, subscriptions, purchase buttons, or prices.
- It does not include AppLovin SDK, analytics SDKs, iOS ad setup, or unrelated tracking SDKs.

## Package Identifiers

Current temporary local development identifiers:

- Android applicationId: `com.fasttunnel.networktest`
- iOS bundle identifier: `com.fasttunnel.networktest`
- Flutter package name: `fast_tunnel_network_test`

Before publication, replace these with final reverse-domain identifiers based on a domain you own. Bundle identifiers generally cannot be changed after an app is published.

## Architecture

The Flutter code is feature-first under `lib/src`.

- `app`: GoRouter routes, app root, and theme.
- `core/storage`: shared preferences provider.
- `core/widgets`: shared action buttons, badges, empty/error states, and dialogs.
- `features/tunnel`: `TunnelService`, simulated service implementation, Home shell, session details, and debug controls.
- `features/public_ip`: independent current-public-IP service and provider.
- `features/history`: local session history repository, controller, list, and record details.
- `features/locations`: static location metadata and selector UI.
- `features/settings`: persisted settings repository and screen.
- `features/premium`: non-purchasable future feature concepts.
- `features/legal`: About, Privacy Policy, and Terms of Use.
- `core/ads`: Android-only AdMob configuration, cache, services, controllers, and widgets.

Every tunnel-facing UI consumes `TunnelService`. A future native implementation should replace only the service implementation behind the provider.

## Simulated Flow

Connect:

```text
Not Connected -> Preparing -> Connecting -> Session Active
```

Disconnect:

```text
Session Active -> Disconnecting -> Not Connected
```

The debug screen is available from Settings in debug builds and controls simulated failure, random failures, delay sliders, and reset state. These controls affect only simulated state.

## Public IP

The app can display `Current Public IP` using:

```text
https://api.ipify.org?format=json
```

This is informational only. The app never displays a replacement IP and never claims that the public IP changed.

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

Run the full local quality gate:

```powershell
dart format .
flutter pub get
flutter analyze
flutter test
flutter build apk --debug
flutter build apk --release
```

The debug APK is generated at:

```text
build\app\outputs\flutter-apk\app-debug.apk
```

The Android app keeps only the `android.permission.INTERNET` permission for the current public IP lookup.

## Android Advertising

Fast Tunnel uses `google_mobile_ads` version `^9.0.0` on Android only.

Remote configuration is loaded from the raw JSON endpoint:

```text
https://raw.githubusercontent.com/Ukabar/Ads_config_Tunnel/main/ads_config.json
```

An optional build-time override is supported:

```powershell
flutter run --dart-define=ADS_CONFIG_URL=https://example.com/ads_config.json
```

Only HTTPS endpoints are accepted. The app loads the last valid cached config immediately, refreshes the remote config in the background, caches only successfully validated JSON, respects `cache_duration_minutes`, and disables ads after seven days without a valid refresh.

The Android AdMob App ID is configured in:

```text
android/app/src/main/AndroidManifest.xml
```

The current value is a placeholder:

```xml
android:value="REPLACE_WITH_REAL_ANDROID_ADMOB_APP_ID"
```

Replace it with the real Android AdMob App ID before publication. App IDs contain `~`; ad unit IDs contain `/`. Do not put an ad unit ID in the manifest.

Debug builds always use official Google Android test ad unit IDs. Release builds use test IDs when remote `test_mode=true`; production ad units are used only in release when `test_mode=false`. Never click live ads during development or testing.

Current placements:

- Banner: Locations, History, and Settings only, using anchored adaptive banners.
- Interstitial: only after successfully completed simulated sessions, with remote frequency, interval, and daily caps.
- App Open: implemented for Android lifecycle returns from background, but only when enabled remotely.
- Native: implemented with one Locations placement after the sixth location item, hidden while disabled remotely.
- Rewarded: infrastructure only; no user-facing placement until a real enforceable reward exists.

The AppLovin section of the remote JSON is parsed but unsupported. If a format selects `applovin`, that format is unavailable; the app does not install, initialize, or fall back to an AppLovin SDK.

The Privacy Policy placeholder mentions Google Mobile Ads processing. Legal review, regional consent handling, and future Google UMP consent integration are required before publication. No fake consent dialog or iOS ATT prompt is included.

## GitHub Setup

This directory may not be initialized as a Git repository. Initialize only when you are ready:

```powershell
git init
git add .
git commit -m "Fast Tunnel tunnel-only prototype"
git branch -M main
git remote add origin REPLACE_WITH_GITHUB_REPOSITORY_URL
git push -u origin main
```

## Codemagic And iOS

The iOS project is kept structurally valid for future Codemagic builds. Version 1.0 intentionally avoids iOS NetworkExtension code, VPN entitlements, packet tunnel targets, and provisioning assumptions.

Suggested Codemagic build steps:

```bash
flutter pub get
flutter analyze
flutter test
flutter build ios --release --no-codesign
```

Add signing only when preparing a real iOS release.

## Future Native Integration

Keep `TunnelService` as the boundary. A future native implementation should provide the same stream of state, session metadata, cancellation, retry, and disconnect behavior while adding real platform capabilities only after the required native code, entitlements, provisioning, and legal copy are ready.
