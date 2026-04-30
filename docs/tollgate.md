# TollGate

This document describes how the app discovers TollGate networks, loads pricing, and submits payments.

## Discovery

The app can identify likely TollGate SSIDs from scan results, but it cannot know the real price from Wi-Fi scan data alone.

Before connection, TollGate scan cards are shown with pricing only after the router metadata becomes available.

## Live Pricing

After the device connects to a TollGate network, the app fetches pricing from the router API:

```text
http://172.19.217.1:2121
```

The app reads live metadata such as:

- `metric`
- `step_size`
- `price_per_step`
- `mint`

The connected TollGate views use that live metadata instead of mock pricing.

## Top-Up Flow

Current top-up flow:

1. Connect to a TollGate SSID from the home or scan flow.
2. Load live pricing from the router.
3. Choose a package derived from the router's data step size, or enter a custom amount in MB.
4. Use already stored local swapped eCash.
5. Submit the raw Cashu token body to the router with `POST http://172.19.217.1:2121/`.

Important behavior:

- TollGate top-up does not prepare, split, or swap tokens during payment
- TollGate top-up does not call the mint at payment time
- the flow only uses already stored local swapped tokens that are safe to spend offline
- if the selected amount cannot be satisfied from stored swapped tokens, top-up is rejected and the user must prepare swapped value first from the wallet

## Session Usage

The Home screen can show remaining TollGate session data using the router usage endpoint.

That keeps the UI tied to the router's current session state instead of estimating access from wallet balance alone.

## Testing Notes

- the Android emulator path can verify build and app launch
- real Wi-Fi join and real TollGate payment submission require a physical Android device
- Android is the practical target for full TollGate validation
