# Changelog

## 2026-04-02

### Attempt 6 - TollGate API connect and top-up flow

- Centralized TollGate SSID detection so the scan flow and current connection state use the same TollGate matching rules.
- Updated TollGate connection flows from the home screen and scan screen to connect first, then fetch live pricing from `http://172.19.217.1:2121`.
- Hardened `TollGateInfo` parsing to support the router's `price_per_step`, `step_size`, `mint`, and `tips` tag layouts.
- Replaced the review-only TollGate screen with a real top-up flow that generates a Cashu token from the wallet and submits it to `http://172.19.217.1:2050`.
- Kept captive-portal compatibility internal by preferring the router's `/api/` submission path when present, then falling back to `/` without exposing that distinction in the UI.
- Renamed the connected TollGate action back to `Top Up` to match the new behavior.
- Enabled Android cleartext traffic so the app can call the local TollGate HTTP endpoints directly.
- Updated `README.md` to document the live TollGate connect and top-up flow, router endpoints, and current testing limits.
- Re-ran `flutter analyze` with no new analysis errors.
- Re-ran `flutter run -d emulator-5554 --debug --no-resident`; the app built, installed, and launched, but real Wi-Fi/TollGate payment verification still requires a physical Android device.

### Attempt 7 - Megabyte-based top-up packages

- Removed the time-based TollGate package selection from the top-up screen.
- Switched the TollGate top-up flow to data-based pricing and package labels in MB/GB.
- Made the preset top-up options derive from the router's `step_size`, so a router advertising `1 sat` per `21 MB` now renders packages such as `21 MB`, `105 MB`, and `210 MB`.
- Kept custom top-up entry in MB and continued pricing it from the live TollGate metadata.
- Updated `README.md` to document the megabyte-based pricing interpretation and step-size-derived package options.

### Attempt 8 - Offline mint resolution for TollGate top-ups

- Removed the TollGate top-up path's dependency on adding a mint over the network during payment.
- When the TollGate omits `mint`, the app now uses the saved current mint URL when present, otherwise the hardcoded default mint URL.
- Removed the `listMints()` dependency from the TollGate top-up path because that fetches mint info over the network.
- Updated `README.md` to document the offline mint selection behavior for TollGate payments.

### Attempt 9 - Raw token POST to router payment endpoint

- Replaced the JSON TollGate payment request body with the router's current raw-token contract: `POST http://172.19.217.1:2121/` and body `cashu...`.
- Updated the app to submit the Cashu token string directly in the request body with curl-compatible form semantics.
- Updated the TollGate payment screen copy and `README.md` to reflect that payment currently posts to `2121` instead of `2050`.

### Attempt 10 - Offline TollGate payment uses reserved local eCash

- Fixed the TollGate purchase path so it no longer calls `wallet.prepareSend()` or `wallet.send()` during payment.
- Switched TollGate payment to use the reserved local eCash token already stored in the app, then submit that raw token directly to the router.
- Cleared the stored local eCash token only after the router accepts the payment, preventing accidental token reuse.
- Updated the TollGate payment screen to show local eCash balance instead of the online mint wallet balance.
- Updated `README.md` to explain that TollGate purchase is now an offline local-eCash flow and no longer fetches mint info at payment time.

### Attempt 11 - Exact offline token splitting and quieter mint resolution

- Added an exact local Cashu token split helper to `cdk_flutter`, allowing the app to carve out a selected offline subtoken without contacting the mint.
- Updated TollGate payment to split the reserved local token to the requested sats amount, submit only that selected subtoken to the router, and keep the local remainder stored for later use.
- Added debug logging for the TollGate router payment URL, raw Cashu payload, and HTTP response body.
- Changed `currentMintProvider` so its normal build path no longer calls `listMints()` or `addMint()` just to resolve the default mint while offline.
- Updated `README.md` to describe exact offline token splitting and the new debug logging behavior.

### Attempt 12 - Reserve flow reissues into 1-sat proofs

- Cleaned the previously dirty `cdk_flutter` submodule worktree before starting the new reserve implementation.
- Added `ReceiveOptions.amountSplitTargetValue` support to `cdk_flutter` so the app can ask the mint to reissue received tokens into smaller proofs.
- Re-added the exact local Cashu token split helper in `cdk_flutter` because TollGate payment still needs to carve out an offline subtoken before posting it to the router.
- Refactored the Reserve flow so it now exports a temporary token from the main wallet, re-receives it through the mint with a `1 sat` proof target, then stores the final local TollGate token.
- Added reserve wallet recovery behavior so an interrupted reserve attempt can export pending reserve balance on the next run instead of silently losing it.
- Updated the TollGate payment copy and `README.md` to explain that reserve now tries to prepare many `1 sat` proofs while online, then splits and posts raw tokens offline.

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
