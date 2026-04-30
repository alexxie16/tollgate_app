# Development

This document covers repository setup, local development requirements, and the common build and run commands for contributors.

## Prerequisites

Core tooling:

- Flutter `3.41.6`
- Dart `3.11.x`
- Rust toolchain with `cargo`
- CMake

Android tooling:

- JDK `17`
- Android SDK command-line tools
- Android platform tools
- Android SDK platforms required by the project
- Android NDK required by the native Cashu bridge

Apple tooling if you want Apple builds:

- Xcode
- CocoaPods
- At least one installed iOS Simulator runtime

## Repository Structure

Key top-level paths:

- `lib/`: Flutter app code
- `android/`, `ios/`, `macos/`, `linux/`, `windows/`, `web/`: platform runners
- `cdk_flutter/`: in-repo Cashu Flutter package and Rust bridge
- `third_party/WiFiFlutter/`: local overrides for Wi-Fi packages
- `docs/`: contributor and feature documentation

The app depends on in-repo submodules and local package overrides, so cloning with submodules is required.

## Setup

Clone the repository with submodules:

```bash
git clone --recurse-submodules <repo-url>
cd tollgate_app
```

If the repo is already cloned:

```bash
git submodule update --init --recursive
```

Install packages and generate source:

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
```

## Build And Run

Analyze the project:

```bash
flutter analyze
```

Build a debug APK:

```bash
flutter build apk --debug
```

Run the app:

```bash
flutter run
```

Run on a specific Android target:

```bash
flutter devices
flutter run -d <device-id>
```

Install an already-built APK on a connected Android phone:

```bash
adb install -r build/app/outputs/flutter-apk/app-debug.apk
```

## Contributor Notes

- Android is the practical target for end-to-end TollGate testing.
- The app uses local `http://` router endpoints for TollGate APIs.
- `cdk_flutter` requires the Rust/native toolchain during Android builds.
- `wifi_scan` and `wifi_iot` are sourced from `third_party/WiFiFlutter` because the published packages are not compatible with the current Dart SDK used here.

## Useful Commands

```bash
git submodule update --init --recursive
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter analyze
flutter build apk --debug
flutter run
flutter devices
adb devices -l
adb install -r build/app/outputs/flutter-apk/app-debug.apk
```
