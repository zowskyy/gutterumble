# Android Build Status

**Command 03.** Status of Android packaging for GutterRumble.

## Configuration in repo

| Item | Status |
|------|--------|
| `window/handheld/orientation=landscape` (`project.godot`) | Present |
| `renderer/rendering_method=mobile` | Present |
| `export_presets.cfg` | Present (restored + fixed) |
| Preset **Android Release** → AAB (`gradle_build/export_format=1`) | Present |
| Preset **Android Debug** → APK (`export_format=0`) | Present |
| `permissions/internet=true` | Present (both Android presets) |
| `package/unique_name=com.gutterumble.game` | Present |
| `version/code=1`, `version/name=1.0.0` | Present |
| Release keystore path/password in git | **Intentionally empty** (no secrets) |
| `android/` custom build template tree | Absent (Godot installs via editor when needed) |

## Keystore

Do **not** commit keystores or passwords. Configure locally / CI via Godot Editor Settings or env injection:

- `keystore/release` path
- `keystore/release_user`
- `keystore/release_password`

See `docs/compliance/ANDROID_EXPORT.md`.

## Validation this environment

| Check | Result |
|-------|--------|
| Static preset keys vs EditorExportPlatformAndroid docs | PASS (internet, version, package, architectures, gradle export_format) |
| Headless `test_input_command` | Run with local Godot 4.7 when available |
| Device install / AAB export | **UNVERIFIED** — Android SDK / export templates not assumed present in agent VM |
| On-device touch/safe-area | **UNVERIFIED** |

## How to export (when SDK + templates installed)

```bash
godot --headless --path . --export-release "Android Release" build/gutterumble-release.aab
godot --headless --path . --export-debug "Android Debug" build/gutterumble-debug.apk
```

Preset names must match `export_presets.cfg` exactly.
