# TollGate Wi-Fi Access App

Flutter mobile application for discovering TollGate Wi-Fi networks and paying for access with Bitcoin via Cashu.

## Status

- Android debug build verified locally with `flutter build apk --debug`
- Android emulator launch and app install verified locally with `flutter run -d emulator-5554 --debug --no-resident`
- Android phone sideload verified locally with `adb install -r build/app/outputs/flutter-apk/app-debug.apk`
- Wallet mint configuration flow now exists in-app under Settings
- Default wallet mint is Minibits at `https://mint.minibits.cash/Bitcoin`, with support for custom mint URLs
- Wallet home is now simplified to `Send` and `Receive` only
- Wallet `Receive` now supports both pasted Cashu tokens and invoice creation, and stores the result as regular local eCash
- Wallet `Send` now prefers swapped local eCash for exact offline splits and falls back to regular local eCash when needed
- Wallet home now shows both regular eCash and swapped eCash, with a manual `Swap All` action to convert regular eCash into swapped `1 sat` proofs
- Available TollGate network scan cards no longer show fake random `sats/min`; live pricing is only shown after connecting to a TollGate
- TollGate SSIDs can now be connected from the home and scan flows, then load live pricing from `http://172.19.217.1:2121`
- TollGate top-up now uses the one stored local eCash token, splits it offline, and submits the selected raw token to `POST http://172.19.217.1:2121/`
- The app does not require showing a captive-portal UI to the user for the current TollGate payment flow
- Primary supported build target is Android
- iOS/macOS toolchain can be configured, but the app's Wi-Fi connection flow is Android-first

## Repository Layout

This repo now depends on in-repo submodules and local package overrides:

- `cdk_flutter/`: Cashu Flutter bindings and Rust bridge
- `third_party/WiFiFlutter/`: vendored source for `wifi_scan` and `wifi_iot`
- `CHANGELOG.md`: repo-level attempt log for app changes and verification work

Clone with submodules:

```bash
git clone --recurse-submodules <repo-url>
```

If you already cloned the repo:

```bash
git submodule update --init --recursive
```

## Build Requirements

### Core

- Flutter `3.41.6`
- Dart `3.11.x`
- Rust toolchain with `cargo`
- CMake

### Android

- JDK `17`
- Android SDK command-line tools
- Android platform tools
- Android SDK platforms `33`, `34`, `35`, and `36`
- Android build-tools `34.0.0`, `35.0.0`, and `36.0.0`
- Android NDK `27.0.12077973`

### Apple tooling

- Xcode
- CocoaPods
- At least one installed iOS Simulator runtime if you want simulator builds

## Local Environment

On this machine, the working Android/Java paths are:

- `JAVA_HOME=/opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home`
- `ANDROID_HOME=/opt/homebrew/share/android-commandlinetools`
- `ANDROID_SDK_ROOT=/opt/homebrew/share/android-commandlinetools`

The Android project is configured to use those locations through:

- `android/local.properties`
- `android/gradle.properties`

Flutter CLI also needs to know which JDK to use. If `flutter build apk --debug` fails with `Unable to locate a Java Runtime`, point Flutter at JDK 17:

```bash
flutter config --jdk-dir="/opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home"
```

## Project Setup

1. Install Flutter, Rust, CMake, JDK 17, and Android SDK tooling.
2. Initialize submodules.
3. Fetch Dart/Flutter packages.
4. Generate Riverpod/Freezed outputs.

Commands:

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
```

## Build

### Analyze

```bash
flutter analyze
```

Current analysis state is buildable, with warnings/info remaining from deprecated Flutter APIs and a few unused members.

### Android Debug APK

```bash
flutter build apk --debug
```

Output:

```bash
build/app/outputs/flutter-apk/app-debug.apk
```

## Wallet Mint MVP

### Default mint

If no mint has been configured yet, the app now defaults to the Minibits mint:

```text
https://mint.minibits.cash/Bitcoin
```

That URL was validated against the mint info endpoint:

```text
https://mint.minibits.cash/Bitcoin/v1/info
```

### Configure or change mint

1. Open `Settings`.
2. Use `Use Default Minibits Mint` for the default path, or enter another Cashu mint URL.
3. Tap `Save Mint`.
4. Use the `Configured Mints` list to switch between already-added mints.

### Create an invoice

1. Open `Wallet`.
2. Open `Receive`.
3. Switch to `Create Invoice`.
4. Enter the amount in sats.
5. Tap `Create Invoice`.
6. Pay the displayed Lightning invoice externally.
7. Once the mint quote reaches `issued`, the app converts the minted amount into the stored local eCash token.

### Current verification state

- The mint configuration flow, mint screen validation, and invoice error handling are implemented.
- Android build and runtime smoke tests were rerun after these changes.
- End-to-end balance update after paying a real invoice still requires manual payment verification.

## Wallet Actions

### Receive a Cashu token or invoice

1. Open `Wallet`.
2. Tap `Receive`.
3. Either paste a Cashu token string such as `cashuA...`, or switch to `Create Invoice` and mint funds through the current mint.
4. Complete the chosen receive flow.
5. The app stores the resulting value as regular local eCash for later send, swap, and TollGate use.

Implementation notes:

- One regular local token and one swapped local token are supported for now.
- If a regular token is already stored, the app asks you to send, spend, clear, or swap it before receiving another regular token.
- Creating an invoice requires internet and mint access. The wallet and TollGate still work partially offline with an already stored local token.
- Swapping regular eCash into swapped eCash is a manual wallet action and requires internet plus mint connectivity.

### Send a Cashu token

1. Open `Wallet`.
2. Tap `Send`.
3. Enter the sats amount you want to export.
4. Confirm the amount.
5. The app exports an exact token from the swapped eCash pool when available, or uses the regular token directly when it already matches the requested amount exactly.

### Balance model

The wallet home now shows local eCash buckets, not a combined mint-backed account balance.

- `Receive` prepares regular local eCash.
- `Swap All` converts regular local eCash into swapped local eCash with `1 sat` proofs.
- `Send` and TollGate payment prefer swapped local eCash because it is easier to split exactly offline.
- The wallet page also shows swapped eCash pool balances and any legacy swapped token waiting to be imported into that pool.
- The app no longer exposes `Reserve` or `Melt` in the wallet UI.

## TollGate Pricing And Payment

### Discovery pricing

The app cannot know a TollGate's real price from a Wi-Fi scan alone.

- Scanned TollGate SSIDs are now shown as `Pricing available after connect` until the app can fetch live router metadata.
- TollGate Wi-Fi detection is based on the SSID pattern and those cards now connect directly into the app's TollGate flow.

### Connected TollGate pricing

When connected to a TollGate, the app fetches pricing from the router API at:

```text
http://172.19.217.1:2121
```

The app reads pricing from the TollGate metadata tags, including:

- `metric`
- `step_size`
- `price_per_step`
- `mint`

The connected TollGate card and TollGate top-up screen now use that real metadata instead of mock `sats/min` values.

For example, if the router advertises `metric=megabytes`, `step_size=21`, and `price_per_step=1`, the app interprets that as `1 sat per 21 MB`.

### Top-up flow

The TollGate screen now performs a real offline local-eCash top-up flow:

1. Connect to a TollGate SSID from the home screen or scan screen.
2. Load live pricing from `http://172.19.217.1:2121`.
3. Choose a package derived from the router's advertised data step size, or enter a custom amount in MB.
4. Use the active local eCash already saved in the app.
5. Export an exact token from the swapped eCash pool when available, or use the regular token directly when it already matches the requested amount exactly.
6. Submit the selected token to the router with `POST http://172.19.217.1:2121/` using the raw Cashu token string as the request body.

Implementation notes:

- The screen shows the active local eCash balance before attempting a top-up.
- The preset top-up packages are built from the router's step size, such as `21 MB`, `105 MB`, and `210 MB` when one step equals `21 MB`.
- The TollGate purchase flow does not call the mint at payment time; it only posts the selected local token slice to the router endpoint.
- If a regular token cannot satisfy the selected amount exactly, swap all local eCash into swapped eCash from the wallet page first.
- The payment request posts the raw Cashu token body directly to the router endpoint instead of wrapping it in JSON.
- The app logs the router payment URL, request payload, and HTTP response in debug output to help with on-device testing.
- Android cleartext HTTP is enabled because the router APIs are local `http://` endpoints.

### Live device testing status

End-to-end testing against a real SSID such as `TollGate-A4PX-2.4GHz` requires a physical Android device connected over `adb`.

- The Android emulator build/run path was verified after these changes.
- A live Wi-Fi join and real payment submission test could not be completed in this attempt because no physical Android phone was attached during the test pass.

### Run on Android device or emulator

List devices:

```bash
flutter devices
```

Launch the existing Android emulator profile named `Tollgate_API_35` on this machine:

```bash
flutter emulators --launch Tollgate_API_35
```

Run on Android. If the launched emulator shows up as `emulator-5554`, this works:

```bash
flutter run -d emulator-5554
```

Or target a connected Android device explicitly:

```bash
flutter run -d <android-device-id>
```

### Run on a physical Android device

Check that the phone is visible:

```bash
adb devices -l
flutter devices
```

Sideload an already-built debug APK onto a connected Android phone:

```bash
adb install -r build/app/outputs/flutter-apk/app-debug.apk
```

If you want to launch the installed app from the shell:

```bash
adb shell monkey -p com.example.tollgate_app -c android.intent.category.LAUNCHER 1
```

### Troubleshooting

If `flutter build apk --debug` fails with `Unable to locate a Java Runtime`, configure Flutter to use JDK 17:

```bash
flutter config --jdk-dir="/opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home"
```

If the wallet says no mint is configured, open `Settings` and either:

- tap `Use Default Minibits Mint`, or
- paste another valid Cashu mint URL and tap `Save Mint`

If invoice creation fails, verify that the configured mint URL is reachable and supports Cashu minting, then retry from the Mint screen.

If a received token fails to import, verify that:

- the pasted value is a valid Cashu token string
- the token has not already been spent
- the mint referenced by the token is reachable

If a scanned TollGate network does not show a price, that is expected until the device is actually connected and the router metadata has been fetched.

If you want to validate a real TollGate SSID such as `TollGate-A4PX-2.4GHz`, attach a physical Android phone with `adb` and test from that device. The emulator cannot exercise real Wi-Fi association against nearby access points.

If `flutter devices` shows an unwanted iPhone local-network warning on macOS, that is usually caused by an existing Xcode/CoreDevice pairing on the host, not by this repo. Removing the stale pairing stops Flutter from probing that device:

```bash
xcrun devicectl manage unpair --device <ios-udid>
```

## Notes

- `wifi_scan` and `wifi_iot` are sourced from `third_party/WiFiFlutter` via local overrides because the published packages are not compatible with the Dart SDK used by this app.
- `cdk_flutter` is built from the in-repo submodule and requires the Rust/Android native toolchain during Android builds.
- iOS programmatic Wi-Fi connection is limited by platform behavior; Android is the practical target for full app functionality.

## Useful Commands

```bash
git submodule update --init --recursive
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter analyze
flutter build apk --debug
flutter devices
flutter emulators --launch Tollgate_API_35
flutter run -d emulator-5554
adb devices -l
adb install -r build/app/outputs/flutter-apk/app-debug.apk
```
