# Troubleshooting

## Android Build Fails With Missing Java Runtime

If Flutter cannot find Java, point Flutter at JDK 17:

```bash
flutter config --jdk-dir="/path/to/jdk-17"
```

## The Wallet Says No Mint Is Configured

Open `Settings` and either:

- choose `Use Minibits` or `Use Coinos`
- enter another valid Cashu mint URL and save it

## Invoice Creation Fails

Check that:

- the configured mint URL is reachable
- the mint supports Cashu minting
- the device has internet access

If the first quote never arrives, retry from the `Receive` screen.

## A Received Token Fails To Import

Check that:

- the pasted value is a valid Cashu token string
- the token has not already been spent
- the referenced mint is reachable if the flow needs mint interaction

## A TollGate Network Does Not Show A Price

That is expected until the device is actually connected and the router metadata has been fetched.

## TollGate Testing Does Not Work On The Emulator

The emulator can verify build and app launch, but it cannot exercise real nearby Wi-Fi association the way a physical Android device can.

For real TollGate testing:

- connect a physical Android phone
- verify it appears in `adb devices -l`
- run the app on that device

## Flutter Shows Unexpected iPhone Device Warnings On macOS

This is usually caused by an existing Xcode/CoreDevice pairing on the host rather than this repository.

If needed, remove the stale pairing:

```bash
xcrun devicectl manage unpair --device <ios-udid>
```
