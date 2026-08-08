# Android Release — AAB Export & Keystore Checklist

Godot 4.x · GUTTERUMBLE · Target: Google Play (AAB required)

---

## Prerequisites

- [ ] Godot 4.7+ with Android export templates installed
- [ ] Android SDK + JDK 17 configured in Godot Editor → Editor Settings → Export
- [ ] Release keystore generated and backed up (see below)
- [ ] `version/code` and `version/name` bumped in `project.godot` export preset

---

## 1. Create release keystore (one-time)

```bash
keytool -genkeypair \
  -v \
  -keystore gutterumble-release.keystore \
  -alias gutterumble \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000 \
  -storetype PKCS12
```

Record in a password manager (never commit to git):

| Field | Example |
|-------|---------|
| Keystore path | `gutterumble-release.keystore` |
| Keystore password | `[SECURE]` |
| Key alias | `gutterumble` |
| Key password | `[SECURE]` |

---

## 2. Keystore backup checklist

Store copies in **at least two** separate secure locations before the first Play upload.
**You cannot update the app if the keystore is lost.**

| # | Location | Format | Verified |
|---|----------|--------|----------|
| 1 | Password manager attachment (1Password / Bitwarden) | `.keystore` + passwords | [ ] |
| 2 | Encrypted offline USB in safe | `.keystore` on encrypted volume | [ ] |
| 3 | Team vault (if applicable) | `.keystore` + env secrets | [ ] |

Also document:

- [ ] Keystore SHA-1 / SHA-256 fingerprints (`keytool -list -v -keystore ...`)
- [ ] Play App Signing enrollment status (Google holds upload key vs app signing key)
- [ ] Who has access and revocation plan if team member leaves

---

## 3. Configure Godot export preset

1. **Project → Export → Add → Android**
2. Set **Custom Build** if using Gradle plugins; otherwise use built-in export.
3. Under **Keystore / Release**:
   - Release Keystore: path to `gutterumble-release.keystore`
   - Release User: `gutterumble`
   - Release Password: from password manager
4. Under **Gradle Build**:
   - **Export Format:** `aab` (Android App Bundle — required for Play)
   - Min SDK: 24 (Android 7.0) or project minimum
   - Target SDK: latest stable (34+)
5. Under **Architectures:** enable `arm64-v8a` (required); `armeabi-v7a` optional for older devices.
6. Save preset as `Android Release`.

---

## 4. Export AAB (CLI)

```bash
godot --headless --path /workspace \
  --export-release "Android Release" \
  build/gutterumble-release.aab
```

Verify output:

```bash
ls -lh build/gutterumble-release.aab
# Expect multi-MB file; 0 bytes = export failure
```

Optional local install test (requires bundletool + connected device):

```bash
java -jar bundletool.jar build-apks \
  --bundle=build/gutterumble-release.aab \
  --output=build/gutterumble.apks \
  --ks=gutterumble-release.keystore \
  --ks-key-alias=gutterumble
```

---

## 5. Upload to Play Console

1. Play Console → GUTTERUMBLE → **Release → Testing → Internal testing** (or Production).
2. **Create new release** → upload `gutterumble-release.aab`.
3. Complete release notes.
4. Run **Pre-launch report** before promoting to production.
5. Confirm Data Safety form matches `docs/compliance/DATA_SAFETY.md`.
6. Confirm Privacy Policy URL matches `docs/compliance/PRIVACY_POLICY.md`.

---

## 6. Post-export verification

| Check | Command / action | Pass |
|-------|------------------|------|
| AAB not debug-signed | `jarsigner -verify build/gutterumble-release.aab` | [ ] |
| Version code incremented | Compare to last Play upload | [ ] |
| CrashReporter enabled | Force test crash on release build | [ ] |
| PerfLogger disabled | Confirm `PerfLogger.enabled = false` in release | [ ] |
| Supabase keys are anon only | No service_role in APK | [ ] |

---

## Troubleshooting

| Symptom | Fix |
|---------|-----|
| `ERR_CANT_OPEN` keystore | Check path; avoid spaces; use absolute path in export preset |
| `INSTALL_FAILED_UPDATE_INCOMPATIBLE` | Uninstall debug build first (different signature) |
| AAB rejected: target SDK | Bump `target_sdk` in export preset to Play minimum |
| Lost keystore | Cannot update existing listing — new package name required |
