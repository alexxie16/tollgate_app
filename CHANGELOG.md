# Changelog

## 2026-04-01

### Attempt 1 - Android build and device verification

- Fixed local Flutter JDK configuration by pointing Flutter to the installed JDK 17.
- Verified `flutter build apk --debug` succeeds locally.
- Verified `flutter run` on the Android emulator.
- Verified sideload to a physical Android phone with `adb install -r build/app/outputs/flutter-apk/app-debug.apk`.
- Updated `README.md` with Android setup, emulator, physical device, and troubleshooting commands.

### Attempt 2 - Mint MVP foundation

- Set the app to default to the Minibits mint at `https://mint.minibits.cash/Bitcoin` when no mint is configured yet.
- Added real Cashu mint configuration controls in Settings, including a one-tap Minibits default action and custom mint URL input.
- Hardened current mint selection so the app adds or selects a mint safely instead of assuming it already exists.
- Fixed the mint amount validation path so invalid input stays on the form instead of crashing into an async error state.
- Hardened the mint quote stream and invoice UI to render recoverable errors instead of throwing from the widget tree.
- Re-ran `flutter analyze` with no new analysis errors, only existing project warnings/info.
- Re-ran `flutter build apk --debug` successfully after the mint changes.
- Re-ran `flutter run -d emulator-5554 --debug --no-resident` successfully after the mint changes.
- Remaining manual verification: pay a real invoice and confirm the wallet balance updates end-to-end.

### Attempt 3 - Android emulator keyboard input fix

- Diagnosed the local Android emulator keyboard issue to the AVD config at `~/.android/avd/Tollgate_API_35.avd/config.ini`.
- Changed `hw.keyboard=no` to `hw.keyboard=yes` so the emulator accepts Mac hardware keyboard input.
- Restarted the emulator and re-ran the app on `emulator-5554`.
