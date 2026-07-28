# GutterRumble — Project State
_Last updated: 2026-07-28_

## Current snapshot

BUILD_GUIDE_10X.md's 10 slices are all implemented, committed, and passing the
Godot CI headless workflow (`.github/workflows/godot-ci.yml`). Project targets
Godot 4.7 (mobile renderer, per `project.godot`).

## What exists and works

### Combat core
- `player_controller.gd` / `enemy_ai.gd` — full FSM (windup/active/recovery
  phases, 3-hit combo, dodge, hit-react, KO), identical public API on both
- `attack_config.gd` — single source of frame data; includes `special_aoe`
  (Musou-style instant AOE, not routed through the phase system)
- `AnimationTreeBuilder` — builds the state machine in code at `_ready()`,
  no editor wiring needed; combat clips still route to the idle placeholder
  until real ones exist (see Blocked below)

### Arena & match flow
- `rumble_arena_back_alley.gd` — shared match-manager script, reused as-is
  by BOTH arenas (see below) — no back-alley-specific coupling
- Two arenas: back alley (classic 1v1) and rooftop (Warriors mode, night
  theme, bigger wave progression). Main menu routes 1v1 RUMBLE → back alley,
  GANG WARS → rooftop
- Multi-round play actually works now — round 2+ correctly respawns fighters,
  resets AI/combat state, and re-arms Warriors-mode wave spawning (all three
  were silently broken before slice 3's audit)
- "Gutter Streak" — persistent combo that survives round transitions, only
  breaking on taking a hit or going idle; escalating flavor text (ON A TEAR /
  RAMPAGE / GUTTER KING) ties back to the game's own tagline
- Musou-style special gauge — fills from dealing AND taking damage, unlocks
  an instant AOE, persists across rounds within a match
- Finisher slow-mo + camera punch-in on every round-ending KO
- Hit-spark VFX, weapon trails, screen shake/hit-stop on every landed hit
- Enemies-remaining/wave counters in Warriors mode (not a two-sided "gang
  size" stat — there's no player-side ally roster in this codebase, despite
  GangSpawner's doc comment saying "gang vs gang")
- Crowd barks from off-screen/non-engaged AI (spatial, cooldown-gated)
- Win-gated gang color/shirt unlocks in the character creator

### Autoloads
`FighterPool`, `GangSpawner`, `PerfLogger`, `CombatFeel`, `AudioManager`,
`RoundManager`, `SaveManager`, `VFXPool`, `AnimationTreeBuilder`,
`SpecialMeter`, `SupabaseManager`, `CombatManager`, `AttackConfig`,
`GameManager`, `CustomizationManager`, `NetworkManager`

### CI
- `.github/workflows/godot-ci.yml` — runs on every push/PR: imports the
  project, boots the main scene (exercises every autoload), greps the log
  for parse/script errors (Godot doesn't reliably exit non-zero on those),
  then runs `test_spawn_validator.tscn`

## Bugs found and fixed during this sprint (not newly introduced — pre-existing)

- **Hit-stop could freeze the game permanently on the first hit.**
  `Engine.time_scale = 0.0` combined with a countdown driven by
  `get_process_delta_time()` (which is itself scaled to ~0 by time_scale) —
  confirmed against Godot's own docs, which explicitly warn against setting
  time_scale to exactly 0.0. Fixed: near-zero scale + real-time
  (`Time.get_ticks_usec()`) countdown.
- **Team colors never actually rendered.** `GangSpawner._apply_team_color()`
  looked for a hardcoded `MouseModel/MeshInstance3D` path that doesn't exist
  in the actual rig (multiple named mesh surfaces nested under a skeleton).
  Silent no-op until fixed with a recursive, clothing-filtered mesh search.
- **`combat_hud.gd`/`.tscn` were dead code** — never instantiated anywhere;
  the arena has always driven its HUD through direct node references.
  Deleted rather than building new features on top of an orphaned duplicate.
- **Multi-round play didn't work at all.** No next-round trigger existed;
  signal connections stacked on every pooled fighter reuse; pooled fighters
  kept their KO state forever; GangSpawner's wave index never reset between
  rounds. All four fixed as part of slice 3.

## Blocked on assets, not code

| Item | Blocker |
|------|---------|
| Real combat animations | `tools/blender_scripts/generate_combat_animations.py` is ready — run once in Blender, re-export `mouse.glb` |
| `fighter_lod.gd` | Exists, never wired — needs actual High/Med/Low mesh variants exported from Blender first (only one quality level currently exists) |
| Rollback netcode | Needs the Snopek Games addon — Phase 2, separate integration effort |
| Supabase matchmaking | `find_rumble_match()` in `network_manager.gd` is still a stub |
| Asset provenance | `mouse.glb` and arena textures have no documented source — see `CREDITS.md` action item before any public release |

## Key file paths
```
autoloads/fighter_pool.gd, gang_spawner.gd, perf_logger.gd, combat_feel.gd,
  audio_manager.gd, round_manager.gd, save_manager.gd, vfx_pool.gd,
  animation_tree_builder.gd, special_meter.gd
scenes/vfx/attack_trail.gd
scenes/arenas/back_alley/rumble_arena_back_alley.gd  (shared by both arenas)
scenes/arenas/back_alley/arena_camera.gd             (shared by both arenas)
scenes/arenas/rooftop/rumble_arena_rooftop.tscn
scenes/character_creator/character_creator.gd
tools/blender_scripts/generate_combat_animations.py
.github/workflows/godot-ci.yml
BUILD_GUIDE_10X.md  — slice-by-slice log of what was built and why
```
