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

### Attempt 4 - Wallet receive flow and recent transactions

- Wired the wallet `Receive` button to a real receive screen instead of leaving it as a no-op.
- Added token receive support through the wallet repository using `cdk_flutter` token redemption.
- Implemented a paste-first receive UI for Cashu tokens and switch the current mint to the token mint after a successful receive.
- Replaced the placeholder `Recent Transactions` widget with real wallet transaction history from `listTransactions()`.
- Invalidated transaction history after mint, send, reserve, and receive success paths so the wallet list updates immediately.
- Re-ran `flutter analyze` with no new analysis errors.
- Re-ran `flutter build apk --debug` successfully.
- Re-ran `flutter run -d emulator-5554 --debug --no-resident` successfully.

### Attempt 5 - TollGate pricing truthfulness and runtime audit

- Confirmed that scanned TollGate SSIDs were showing fake random pricing from `WifiService.scanNetworks()` instead of real router data.
- Removed the fake random `satsPerMin` assignment from Wi-Fi scans.
- Updated scanned network cards to show `Pricing available after connect` until live TollGate metadata is available.
- Made scan-screen network cards tappable so they can trigger connection attempts directly.
- Renamed the connected TollGate action from `Top Up` to `Review Pricing` to better reflect the current app behavior.
- Replaced the old mock payment screen logic, which used a fake wallet balance and simulated successful payment, with a truthful live-pricing review screen.
- The new TollGate pricing screen now reads real `TollGateInfo` pricing and the real wallet balance, and clearly states that actual TollGate payment submission is not implemented yet.
- Re-ran `flutter analyze` with no new analysis errors.
- Re-ran `flutter build apk --debug` successfully.
- Re-ran `flutter run -d emulator-5554 --debug --no-resident` successfully.
- Could not complete a live end-to-end test against `TollGate-A4PX-2.4GHz` in this attempt because only the Android emulator was attached; a physical Android device is still required for real Wi-Fi association testing.
