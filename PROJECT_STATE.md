# GutterRumble — Project State
_Last updated: 2026-07-28_

## Current snapshot

All 10 audit slices implemented. Project is running on Godot 4.4+ mobile renderer.

## What exists and works

### Combat core (pre-existing, solid)
- `player_controller.gd` — full FSM: IDLE/LOCOMOTION/ATTACK_LIGHT/ATTACK_HEAVY/DODGE/HIT_REACT/KO
- `enemy_ai.gd` — AI with APPROACH/ATTACK/DODGE/HIT_REACT/KO, reads from AttackConfig
- `attack_config.gd` — autoload, single source of truth for all frame data (damage, knockback, windup/active/recovery times, cancel windows)
- `combat_manager.gd` — hitbox registry with distance check + knockback applier
- Hitbox/Hurtbox Area3D system wired in both player and enemy

### Arena
- `rumble_arena_back_alley.gd` — upgraded to Warriors-mode: supports classic 1v1 (`warriors_mode=false`) and multi-wave gang brawl (`warriors_mode=true`)
- 5 enemy spawn points in the back-alley arena (up from 1)
- WorldEnvironment now loads `assets/environments/arena_back_alley.tres` (glow, SSAO, Filmic tone map)

### New autoloads (slices 1–3, 4)
- `FighterPool` — pre-allocates 12 instances per scene, pull/push API, grows dynamically
- `PerfLogger` — logs FPS, draw calls, active objects, physics objects to `user://perf_log.csv` every 2s
- `GangSpawner` — Warriors-mode wave manager, applies team_color_flat shader per team, forwards player ref to all AI

### Shaders (slice 3)
- `cel_shaded.gdshader` — upgraded: added `team_color` vec4 uniform (alpha=0 inactive), cel_bands parameter, emissive_strength
- `team_color_flat.gdshader` — new flat team shader with rim light for fighter silhouette readability

### Networking (slice 5)
- `networked_player.gd` — rewritten: MultiplayerSynchronizer-ready, authority-gated physics, RPC health sync

### Performance (slices 7, 10)
- `fighter_lod.gd` — attach as child of any CharacterBody3D; switches High/Med/Low mesh children at configurable distances
- `project.godot` — layer names (Fighters/Environment/Hitboxes/Hurtboxes), shadow atlas 4096, max lights per object 2, env preset path

### Testing (slice 9)
- `scenes/test/test_spawn_validator.tscn` + `.gd` — headless test; checks fighter height (0.5–3m), visibility, spawn-at-marker accuracy. Exit 0 = pass.

### HUD (slice 8)
- `scenes/ui/hud/combat_hud.gd` — round timer, kill counter, combo display (resets after 1.8s). Needs `.tscn` wired in editor.

## What still needs work

| Item | Blocker |
|------|---------|
| AnimationTree root-motion | Needs mouse.glb with baked anims from Blender |
| MultiMesh batching | Worth adding if >8 identical fighters causes draw-call issues; profile first |
| Rollback netcode | Needs Snopek Games addon (godot-rollback-netcode) — Phase 2 |
| CombatHUD .tscn | Needs editor wiring; `combat_hud.gd` is ready |
| Supabase matchmaking | `find_rumble_match()` is a stub in `network_manager.gd` |
| Character creator → arena | Flow exists but appearance not yet applied to in-arena fighter mesh |

## Recommended next git commit message
```
feat: audit upgrades — FighterPool, GangSpawner, PerfLogger, team shaders, LOD, Warriors-mode arena
```

## Key file paths
```
autoloads/fighter_pool.gd
autoloads/perf_logger.gd
autoloads/gang_spawner.gd
scenes/player/fighter_lod.gd
scenes/ui/hud/combat_hud.gd
scenes/test/test_spawn_validator.gd
assets/shaders/cel_shaded.gdshader        (upgraded)
assets/shaders/team_color_flat.gdshader   (new)
assets/environments/arena_back_alley.tres (new)
scenes/arenas/back_alley/rumble_arena_back_alley.gd  (upgraded)
project.godot  (autoloads + layer names + perf settings)
```
