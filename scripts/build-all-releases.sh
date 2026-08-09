#!/usr/bin/env bash
# Build all GUTTERUMBLE release artifacts after audit loop passes.
# Usage: bash scripts/build-all-releases.sh [--skip-audit]
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

SKIP_AUDIT=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --skip-audit) SKIP_AUDIT=1; shift ;;
    -h|--help)
      echo "Usage: build-all-releases.sh [--skip-audit]"
      echo "Runs release audit + Godot CI tests, then exports Linux, Windows, and Android AAB."
      exit 0
      ;;
    *) echo "Unknown argument: $1" >&2; exit 2 ;;
  esac
done

GODOT="${GODOT:-godot}"
BUILD_DIR="$ROOT/build"
KEYSTORE="${GUTTERUMBLE_KEYSTORE:-$ROOT/android/gutterumble-release.keystore}"
KEYSTORE_ALIAS="${GUTTERUMBLE_KEYSTORE_ALIAS:-gutterumble}"
KEYSTORE_PASS="${GUTTERUMBLE_KEYSTORE_PASSWORD:-gutterumble-ci}"

section() { echo; echo "=== $1 ==="; }

fail() { echo "ERROR: $*" >&2; exit 1; }

require_godot() {
  command -v "$GODOT" >/dev/null 2>&1 || fail "Godot not found. Install 4.7+ and set GODOT= path."
  "$GODOT" --version | grep -q '^4\.7\.' || fail "Godot 4.7 required (got $($GODOT --version))"
}

run_audit_loop() {
  section "Release audit"
  bash "$ROOT/scripts/release-audit.sh"

  section "Godot import"
  "$GODOT" --headless --path "$ROOT" --import >/dev/null

  section "Boot main scene"
  "$GODOT" --headless --path "$ROOT" res://scenes/main_menu/main_menu.tscn --quit-after 60 \
    2>&1 | tee "$BUILD_DIR/godot_boot.log" || true
  if grep -qE "SCRIPT ERROR|Parse Error|Invalid (call|assignment|get index)" "$BUILD_DIR/godot_boot.log"; then
    fail "Main scene boot failed — see $BUILD_DIR/godot_boot.log"
  fi

  section "Headless slice tests"
  local tests=(
    "res://scenes/test/test_spawn_validator.tscn"
    "res://scenes/test/test_hit_registration.tscn"
    "res://scenes/test/test_customization_warmup.tscn"
    "res://scenes/test/test_match_resolver.tscn"
    "res://scenes/test/test_match_start.tscn"
    "res://scenes/test/test_rep_pipeline.tscn"
    "res://scenes/test/test_shader_warmup.tscn"
    "res://scenes/test/test_crash_reporter.tscn"
  )
  for scene in "${tests[@]}"; do
    echo "Running $scene"
    "$GODOT" --headless --path "$ROOT" "$scene"
  done
}

ensure_keystore() {
  if [[ -f "$KEYSTORE" ]]; then
    echo "Using existing keystore: $KEYSTORE"
    return
  fi
  section "Generate CI release keystore"
  mkdir -p "$(dirname "$KEYSTORE")"
  keytool -genkeypair -v \
    -keystore "$KEYSTORE" \
    -alias "$KEYSTORE_ALIAS" \
    -keyalg RSA -keysize 2048 -validity 10000 \
    -storetype PKCS12 \
    -storepass "$KEYSTORE_PASS" \
    -keypass "$KEYSTORE_PASS" \
    -dname "CN=GUTTERUMBLE CI, OU=Build, O=GUTTERUMBLE, L=Unknown, ST=Unknown, C=US"
  echo "Created $KEYSTORE (alias=$KEYSTORE_ALIAS) — replace with production keystore before Play upload."
}

ensure_export_templates() {
  local tpl_dir="$HOME/.local/share/godot/export_templates/4.7.stable"
  if [[ ! -f "$tpl_dir/linux_release.x86_64" && -d "$tpl_dir/templates" ]]; then
    mv "$tpl_dir/templates"/* "$tpl_dir/"
    rmdir "$tpl_dir/templates" 2>/dev/null || true
  fi
}

ensure_editor_settings() {
  local settings="$HOME/.config/godot/editor_settings-4.7.tres"
  local java_home="/usr/lib/jvm/java-21-openjdk-amd64"
  local sdk_root="${ANDROID_SDK_ROOT:-$HOME/Android/Sdk}"
  if [[ -f "$settings" ]]; then
    if grep -q 'export/android/java_sdk_path = ""' "$settings"; then
      sed -i "s|export/android/java_sdk_path = \"\"|export/android/java_sdk_path = \"$java_home\"|" "$settings"
    fi
    if ! grep -q "export/android/android_sdk_path" "$settings"; then
      echo "export/android/android_sdk_path = \"$sdk_root\"" >> "$settings"
    fi
  fi
}

install_android_template() {
  if [[ -f "$ROOT/android/.build_version" && -d "$ROOT/android/build" ]]; then
    return
  fi
  section "Install Android build template"
  mkdir -p "$ROOT/android/build" "$ROOT/android/plugins"
  unzip -qo "$HOME/.local/share/godot/export_templates/4.7.stable/android_source.zip" \
    -d "$ROOT/android/build"
  echo "4.7.stable.official" > "$ROOT/android/.build_version"
}

ensure_android_sdk() {
  local sdk_root="${ANDROID_SDK_ROOT:-$HOME/Android/Sdk}"
  if [[ -d "$sdk_root/platforms/android-34" ]]; then
    export ANDROID_SDK_ROOT="$sdk_root"
    export ANDROID_HOME="$sdk_root"
    ensure_editor_settings
    return
  fi

  section "Install Android SDK (platform 34)"
  mkdir -p "$sdk_root/cmdline-tools"
  local tools_zip="/tmp/android-cmdline-tools.zip"
  if [[ ! -d "$sdk_root/cmdline-tools/latest" ]]; then
    curl -fsSL -o "$tools_zip" \
      "https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip"
    unzip -qo "$tools_zip" -d /tmp/android-cmdline-tools
    rm -rf "$sdk_root/cmdline-tools/latest"
    mv /tmp/android-cmdline-tools/cmdline-tools "$sdk_root/cmdline-tools/latest"
  fi

  export ANDROID_SDK_ROOT="$sdk_root"
  export ANDROID_HOME="$sdk_root"
  local sdkmanager="$sdk_root/cmdline-tools/latest/bin/sdkmanager"
  yes | "$sdkmanager" --licenses >/dev/null 2>&1 || true
  "$sdkmanager" "platform-tools" "platforms;android-34" "build-tools;34.0.0" "ndk;23.2.8568313"
  ensure_editor_settings
}

export_linux() {
  section "Export Linux Release"
  "$GODOT" --headless --path "$ROOT" \
    --export-release "Linux Release" "$BUILD_DIR/gutterumble-linux.x86_64"
  test -s "$BUILD_DIR/gutterumble-linux.x86_64" || fail "Linux export produced empty file"
  chmod +x "$BUILD_DIR/gutterumble-linux.x86_64"
  ls -lh "$BUILD_DIR/gutterumble-linux.x86_64"
}

export_windows() {
  section "Export Windows Desktop Release"
  "$GODOT" --headless --path "$ROOT" \
    --export-release "Windows Desktop Release" "$BUILD_DIR/gutterumble-windows.exe"
  test -s "$BUILD_DIR/gutterumble-windows.exe" || fail "Windows export produced empty file"
  ls -lh "$BUILD_DIR/gutterumble-windows.exe"
}

export_android() {
  ensure_android_sdk
  install_android_template
  ensure_keystore

  section "Export Android Release (AAB)"
  export GODOT_ANDROID_KEYSTORE_RELEASE_PATH="$KEYSTORE"
  export GODOT_ANDROID_KEYSTORE_RELEASE_USER="$KEYSTORE_ALIAS"
  export GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD="$KEYSTORE_PASS"

  "$GODOT" --headless --path "$ROOT" \
    --install-android-build-template \
    --export-release "Android Release" "$BUILD_DIR/gutterumble-release.aab"
  test -s "$BUILD_DIR/gutterumble-release.aab" || fail "Android export produced empty file"
  ls -lh "$BUILD_DIR/gutterumble-release.aab"
}

main() {
  require_godot
  ensure_export_templates
  mkdir -p "$BUILD_DIR"

  if [[ $SKIP_AUDIT -eq 0 ]]; then
    run_audit_loop
  else
    echo "Skipping audit loop (--skip-audit)"
  fi

  export_linux
  export_windows
  export_android

  section "Build summary"
  ls -lh "$BUILD_DIR"/gutterumble-*
  echo
  echo "ALL RELEASES BUILT SUCCESSFULLY"
}

main "$@"
