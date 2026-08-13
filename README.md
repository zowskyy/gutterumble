# GUTTERUMBLE

Street-fighting arena brawler built in **Godot 4.7** (Mobile/Android). Customize your fighter, pick a weapon, and battle AI opponents across urban arenas.

**Status**: Main Menu ✅ · Character Creator ✅ · Back Alley Arena ✅ · Rooftop Arena ✅ · Combat Core ✅ · Remaining Content ❌

See [BUILD_GUIDE.md](BUILD_GUIDE.md) for the full slide-by-slide development roadmap (~15–20 playable hours target, 6 arenas, 5 weapon types).

## Install

### Prerequisites

- [Godot 4.7](https://godotengine.org/) (Mobile export templates for Android)

### Clone

```bash
git clone https://github.com/zowskyy/gutterumble.git
cd gutterumble
```

Open `project.godot` in the Godot editor, or import the folder as an existing project.

### Android export (optional)

Install Android SDK/NDK via Godot Editor → Export → Android, then configure signing keys under `android/` export presets.

## Run

### In-editor

1. Open the project in Godot 4.7
2. Press **F5** (main scene: `scenes/main_menu/main_menu.tscn`)
3. Flow: Main Menu → Arena Select → Fight (or Gang Wars for multi-wave rooftop)

### Controls (1v1 / Gang Wars)

| Key | Action |
|-----|--------|
| WASD / arrows | Move |
| Z | Light attack |
| X | Heavy attack |
| Space | Dodge |
| C | Special (when meter full) |

## Deploy

| Target | Steps |
|--------|-------|
| Android APK | Godot → Project → Export → Android → Export Project |
| Desktop (dev) | Godot → Export → Windows/Linux (configure preset) |

Backend: Supabase integration in `backend/` with automatic **local JSON fallback**
(`user://gutterumble_local/`) when Supabase credentials are not configured. Match
results are logged locally or to Supabase via `SupabaseManager.log_match()`.

## Build roadmap (summary)

Full detail in [BUILD_GUIDE.md](BUILD_GUIDE.md):

| Phase | Focus | Deliverable |
|-------|-------|-------------|
| 1 | Combat polish | AI enemy, hit feedback, victory/defeat loop |
| 2 | Content pipeline | Modular character assembly, arena variants |
| 3 | Arena rollout | 6 arenas (subway, rooftop, warehouse, parking garage, burning lot) |
| 4 | Progression | Profile persistence, match stats, opponent selector |
| 5 | Launch polish | Menu refinement, performance, APK on device |

## CI

PR/push CI: [`.github/workflows/godot-ci.yml`](.github/workflows/godot-ci.yml) — headless import, boot smoke, and slice tests.
