# TollGate Wi-Fi Access App

Flutter mobile application for discovering TollGate Wi-Fi networks and paying for access with Bitcoin via Cashu.

Android is the primary supported target for the full Wi-Fi and TollGate flow.

## Features

- Discover nearby Wi-Fi networks and identify TollGate SSIDs
- Connect to a TollGate network and fetch live router pricing
- Pay for TollGate access with locally stored Cashu tokens
- Manage local eCash with receive, send, and swap flows
- Create Lightning invoices through a configured Cashu mint

## Tech Stack

- Flutter
- Riverpod
- Go Router
- HTTP
- Cashu via `cdk_flutter` and the Rust bridge

## Getting Started

Prerequisites:

- Flutter `3.41.6`
- Dart `3.11.x`
- Rust toolchain with `cargo`
- CMake
- JDK `17` for Android builds
- Android SDK and platform tools for Android development

Install:

```bash
git clone --recurse-submodules <repo-url>
cd tollgate_app
flutter pub get
dart run build_runner build --delete-conflicting-outputs
```

Run:

```bash
flutter run
```

Build Android debug APK:

```bash
flutter build apk --debug
```

## Project Structure

- `lib/`: Flutter application code
- `cdk_flutter/`: Cashu Flutter bindings and Rust bridge
- `third_party/WiFiFlutter/`: vendored Wi-Fi plugin source overrides
- `docs/`: development and feature documentation
- `CHANGELOG.md`: change history and verification notes

## Documentation

- [`docs/development.md`](docs/development.md): setup, build, repo layout, and contributor notes
- [`docs/wallet.md`](docs/wallet.md): mint configuration, receive/send/swap flows, and local eCash model
- [`docs/tollgate.md`](docs/tollgate.md): TollGate discovery, pricing, and top-up behavior
- [`docs/troubleshooting.md`](docs/troubleshooting.md): common build, wallet, and device issues

## License

This project is licensed under the MIT License. See `LICENSE`.
