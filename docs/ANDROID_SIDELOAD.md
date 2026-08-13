# Android sideload (Galaxy A37 / arm64)

## Build (agent / CI)

Requires Godot 4.7, Android SDK platform 34, build-tools 34.0.0, and a debug keystore.

Export preset: **Android Debug** in `export_presets.cfg`

- Package: `com.gutterumble.game`
- ABI: `arm64-v8a` only
- Gradle build: off (template APK)
- Output: `build/gutterumble-galaxy-a37-debug.apk`

```bash
# Example (paths may differ per machine)
godot --headless --export-debug "Android Debug" build/gutterumble-galaxy-a37-debug.apk
```

## Install on device

1. Enable **Install unknown apps** for your browser/Files app.
2. Install the debug-signed APK.
3. If Play Protect warns, choose Install anyway.
4. Launch **GUTTERUMBLE** in landscape. Offline loop: main menu → Rumble/Warriors → arena → touch controls.

## Notes

- Debug-signed; not Play Store / release-key ready.
- Combat networking / dedicated server is not required for this offline sideload test.
- On-device install is **UNVERIFIED** until exercised on a physical Galaxy A37.
