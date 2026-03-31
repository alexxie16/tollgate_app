# TollGate Wi-Fi Access App

Flutter mobile application for discovering TollGate Wi-Fi networks and paying for access with Bitcoin via Cashu.

## Status

- Android debug build verified locally with `flutter build apk --debug`
- Primary supported build target is Android
- iOS/macOS toolchain can be configured, but the app's Wi-Fi connection flow is Android-first

## Repository Layout

This repo now depends on in-repo submodules and local package overrides:

- `cdk_flutter/`: Cashu Flutter bindings and Rust bridge
- `third_party/WiFiFlutter/`: vendored source for `wifi_scan` and `wifi_iot`

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

### Run on Android device or emulator

```bash
flutter run
```

## Notes

- `wifi_scan` and `wifi_iot` are sourced from `third_party/WiFiFlutter` via local overrides because the published packages are not compatible with the Dart SDK used by this app.
- `cdk_flutter` is built from the in-repo submodule and requires the Rust/Android native toolchain during Android builds.
- `flutter gen-l10n` currently warns that `synthetic-package` in `l10n.yaml` is deprecated and has no effect.
- iOS programmatic Wi-Fi connection is limited by platform behavior; Android is the practical target for full app functionality.

## Useful Commands

```bash
git submodule update --init --recursive
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter analyze
flutter build apk --debug
flutter run
```
