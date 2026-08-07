# GUTTERUMBLE

Street-fighting arena brawler built in **Godot 4.7** (Mobile/Android). Customize your fighter, pick a weapon, and battle AI opponents across urban arenas.

**Status**: Main Menu ✅ · Character Creator ✅ · Back Alley Arena ✅ · Combat Core ⚠️ · Remaining Content ❌

See [BUILD_GUIDE.md](BUILD_GUIDE.md) for the full slide-by-slice development roadmap (~15–20 playable hours target, 6 arenas, 5 weapon types).

## Install

### Prerequisites

- [Godot 4.7](https://godotengine.org/) (Mobile export templates for Android)
- Python 3.12+ (Cursor Gate tooling only)

### Clone and bootstrap

```bash
git clone https://github.com/zowskyy/gutterumble.git
cd gutterumble
pip install -r requirements.txt
bash scripts/install-agent-environment.sh
```

Open `project.godot` in the Godot editor, or import the folder as an existing project.

### Android export (optional)

Install Android SDK/NDK via Godot Editor → Export → Android, then configure signing keys under `android/` export presets.

## Run

### In-editor

1. Open the project in Godot 4.7
2. Press **F5** (main scene: `scenes/main_menu/main_menu.tscn`)
3. Flow: Main Menu → Character Creator → Arena Select → Fight

### Gate a file locally

```bash
bash scripts/gate-file.sh --file samples/hello_passing.py
```

## Deploy

| Target | Steps |
|--------|-------|
| Android APK | Godot → Project → Export → Android → Export Project |
| Desktop (dev) | Godot → Export → Windows/Linux (configure preset) |

Backend: Supabase integration scaffolded in `backend/` (player profiles, match logging) — see BUILD_GUIDE Phase 4.

## Build roadmap (summary)

Full detail in [BUILD_GUIDE.md](BUILD_GUIDE.md):

| Phase | Focus | Deliverable |
|-------|-------|-------------|
| 1 | Combat polish | AI enemy, hit feedback, victory/defeat loop |
| 2 | Content pipeline | Modular character assembly, arena variants |
| 3 | Arena rollout | 6 arenas (subway, rooftop, warehouse, parking garage, burning lot) |
| 4 | Progression | Profile persistence, match stats, opponent selector |
| 5 | Launch polish | Menu refinement, performance, APK on device |

## Cursor Gate

```bash
bash scripts/install-agent-environment.sh
bash scripts/gate-file.sh --file samples/hello_passing.py
```

PR CI: `.github/workflows/gate-check.yml` gates `samples/hello_passing.py` on every pull request.

Agent policy: [AGENTS.md](AGENTS.md)
