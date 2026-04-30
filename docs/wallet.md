# Wallet

The app uses a local eCash wallet model optimized for offline TollGate payments.

## Local eCash Model

The UI exposes two user-facing buckets:

- `Regular eCash`: newly received local value
- `Swapped eCash`: locally stored value prepared for exact offline splits

Regular eCash is best for receive and mint flows. Swapped eCash is preferred for send and TollGate top-up because it can satisfy exact amounts offline more reliably.

## Mint Configuration

If no mint is configured, the app defaults to Minibits:

```text
https://mint.minibits.cash/Bitcoin
```

Built-in presets:

- `Minibits`
- `Coinos`

You can also save and use a custom Cashu mint URL from `Settings`.

## Receive

From `Wallet` -> `Receive`, the app supports:

- pasting a Cashu token
- creating a Lightning invoice through the current mint

When receive succeeds, the resulting value is stored as regular local eCash.

Invoice notes:

- invoice creation requires internet and mint reachability
- the app waits for the mint quote to reach `issued`
- if the mint never returns the first quote, the UI shows a retryable error instead of loading forever

## Send

From `Wallet` -> `Send`, the app exports an exact local token for the requested sats amount.

Priority order:

- swapped eCash when an exact offline token can be created
- an already matching regular token when possible

If the regular token cannot satisfy the requested amount exactly, swap regular eCash into swapped eCash first.

## Swap

`Swap All Regular eCash` converts regular local eCash into swapped eCash using hidden local wallet state.

Notes:

- swapping requires internet and mint connectivity
- swapped eCash is intended to make exact offline spending easier
- the visible regular balance includes hidden staging balance so the wallet UI does not under-report funds during swap-related flows

## Wallet History

Wallet-related history includes:

- local wallet backend activity
- successful TollGate payments submitted by the app
