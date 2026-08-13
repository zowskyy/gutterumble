# GutterRumble — Project State
_Last updated: 2026-08-13_

## Engineering authority (read first)

As of 2026-08-13, **do not follow older multiplayer roadmaps blindly**. Authoritative docs:

| Doc | Role |
|-----|------|
| [`docs/engineering/REPOSITORY_AUDIT.md`](docs/engineering/REPOSITORY_AUDIT.md) | Forensic ground truth |
| [`docs/engineering/CANONICAL_ARCHITECTURE.md`](docs/engineering/CANONICAL_ARCHITECTURE.md) | KEEP/MERGE/REPLACE/DELETE/DEFER freeze |
| [`docs/engineering/ARCHITECTURE_MIGRATION_PLAN.md`](docs/engineering/ARCHITECTURE_MIGRATION_PLAN.md) | Command order + consolidation plan |
| [`docs/engineering/IMPLEMENTATION_DEPENDENCY_GRAPH.md`](docs/engineering/IMPLEMENTATION_DEPENDENCY_GRAPH.md) | Hard gates |
| [`docs/engineering/COMMAND_AUDIT_LOOP.md`](docs/engineering/COMMAND_AUDIT_LOOP.md) | PASS/FAIL/UNVERIFIED process |

**Canonical fighter:** `fighter.tscn` + `player_controller.gd` — **not** `networked_player.gd`.  
**Canonical combat:** Hitbox/Hurtbox + AttackConfig → `take_damage`.  
**Next permitted command after freeze:** Command 02 (consolidation quarantine) — **in progress / complete on branch**.
**After Command 02:** Command 03 (Android offline) when GATE permits.

## Current snapshot

BUILD_GUIDE_10X.md's 10 slices are implemented for the **offline** combat loop and
pass Godot CI headless (`.github/workflows/godot-ci.yml`). Project targets
Godot 4.7 (mobile renderer, per `project.godot`). Cursor Gate CI/protocol removed.

Networking / Supabase Realtime / `networked_player.gd` are **non-canonical quarantine**, not a
working multiplayer foundation — see the audit.

Recent additions on `main` (through Aug 2026):

- **Arena select** — `scenes/arena_select/` lets 1v1 RUMBLE pick Back Alley or
  Rooftop before fighting (GANG WARS still routes straight to rooftop Warriors
  mode).
- **Local backend fallback** — `SupabaseManager` auto-falls back to
  `backend/local_profile_store.gd` (`user://gutterumble_local/`) when Supabase
  credentials are missing; match results logged via `log_match()`.
- **Release audit script** — `scripts/release-audit.sh` checks README claims,
  TODOs, and stub modules before a release tag.
- **Menu mascot** — skeleton idle sprite on main menu (`skeleton_mascot.gd`),
  cursor-facing flip.
- **UAL animation pack** — Quaternius Universal Animation Library[Standard] at
  project root; combat clips not yet retargeted onto `mouse.glb` (see Blocked).

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
  theme, bigger wave progression). Main menu routes 1v1 RUMBLE → arena
  select → fight; GANG WARS → rooftop Warriors waves
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
- Match results persisted locally (or Supabase when configured) on victory/defeat

### Autoloads
`FighterPool`, `GangSpawner`, `PerfLogger`, `CombatFeel`, `AudioManager`,
`RoundManager`, `SaveManager`, `VFXPool`, `AnimationTreeBuilder`,
`SpecialMeter`, `SupabaseManager`, `CombatManager`, `AttackConfig`,
`GameManager`, `CustomizationManager`, `NetworkManager`

### CI
- `.github/workflows/godot-ci.yml` — runs on every push/PR: imports the
  project, boots the main scene (exercises every autoload), greps the log
  for parse/script errors (Godot doesn't reliably exit non-zero on those),
  then runs headless slice tests

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
| Real combat animations | UAL pack is in-repo at `Universal Animation Library[Standard]/`; retarget onto `mouse.glb` per `QUATERNIUS_RETARGET_SETUP.md`. Procedural fallback: `tools/blender_scripts/generate_combat_animations.py` |
| `fighter_lod.gd` | Exists, never wired — needs actual High/Med/Low mesh variants exported from Blender first (only one quality level currently exists) |
| Rollback netcode | Needs the Snopek Games addon — Phase 2, separate integration effort |
| Supabase matchmaking | `find_rumble_match()` in `network_manager.gd` is still a stub |
| Asset provenance | `mouse.glb` and arena textures have no documented source — see `CREDITS.md` action item before any public release |
| Remaining 4 arenas | subway, warehouse, parking garage, burning lot — see `BUILD_GUIDE.md` Phase 3 |

## Key file paths
```
autoloads/fighter_pool.gd, gang_spawner.gd, perf_logger.gd, combat_feel.gd,
  audio_manager.gd, round_manager.gd, save_manager.gd, vfx_pool.gd,
  animation_tree_builder.gd, special_meter.gd
scenes/arena_select/arena_select.gd
scenes/vfx/attack_trail.gd
scenes/main_menu/skeleton_mascot.gd
backend/local_profile_store.gd, supabase_manager.gd
scenes/arenas/back_alley/rumble_arena_back_alley.gd  (shared by both arenas)
scenes/arenas/back_alley/arena_camera.gd             (shared by both arenas)
scenes/arenas/rooftop/rumble_arena_rooftop.tscn
scenes/character_creator/character_creator.gd
Universal Animation Library[Standard]/Unreal-Godot/UAL1_Standard.glb
tools/blender_scripts/generate_combat_animations.py
tools/blender_scripts/generate_character_rig.py
scripts/release-audit.sh
.github/workflows/godot-ci.yml
BUILD_GUIDE_10X.md  — slice-by-slice log of what was built and why
BUILD_GUIDE.md      — full roadmap (6 arenas, progression, launch polish)
```
