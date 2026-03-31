# TollGate Wi-Fi Access App

Flutter mobile application for discovering TollGate Wi-Fi networks and paying for access with Bitcoin via Cashu.

## Status

- Android debug build verified locally with `flutter build apk --debug`
- Android emulator launch and app install verified locally with `flutter run -d emulator-5554 --debug --no-resident`
- Android phone sideload verified locally with `adb install -r build/app/outputs/flutter-apk/app-debug.apk`
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

Sideload an already-built debug APK onto a connected Android phone:

```bash
adb devices -l
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
