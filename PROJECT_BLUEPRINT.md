# GutterRumble — Project Blueprint

**Genre:** Warriors-style arena brawler (many-on-many)  
**Engine:** Godot 4.4+  
**Stack:** GDScript, ENet multiplayer, Supabase auth, cel-shaded 3D

## Vision
Fast, arcade-style street brawler where the player and their gang fight enemy gangs in tight urban arenas. Inspired by PS2-era Warriors games: many fighters on screen, readable team colours, punchy combat feedback.

## Architecture
```
Autoloads:        AttackConfig, GameManager, NetworkManager, CustomizationManager
                  FighterPool (new), PerfLogger (new)
Scenes:           MainMenu → CharacterCreator → RumbleArenaBackAlley
Core scripts:     player_controller.gd, enemy_ai.gd, combat_manager.gd
Shaders:          cel_shaded.gdshader (team colour uniform), neon.gdshader, water.gdshader
```

## Slices (Salami Method)

| # | Slice | Status |
|---|-------|--------|
| 1 | FighterPool autoload | ✅ Done |
| 2 | PerfLogger autoload | ✅ Done |
| 3 | Team colour shader refactor | ✅ Done |
| 4 | GangSpawner — warriors-mode many-vs-many | ✅ Done |
| 5 | MultiplayerSpawner + MultiplayerSynchronizer | ✅ Done |
| 6 | WorldEnvironment preset (glow, SSAO, tone map) | ✅ Done |
| 7 | LOD fighter distance system | ✅ Done |
| 8 | HUD upgrade (timer, kills, combo) | ✅ Done |
| 9 | Spawn validator test scene | ✅ Done |
| 10 | Project settings lock (layers, shadows, perf) | ✅ Done |

## Non-goals (Phase 1)
- No rollback netcode (deferred to Phase 2 — needs Snopek addon)
- No root-motion AnimationTree (blocked on GLB with baked anims)
- No MultiMesh batching (add if >8 identical fighters causes draw-call issues)
- No story mode / narrative

## File Map
| File | Role |
|------|------|
| `autoloads/fighter_pool.gd` | Pre-allocates & recycles fighter instances |
| `autoloads/perf_logger.gd` | Writes FPS/draw-calls/physics to CSV |
| `autoloads/gang_spawner.gd` | Warriors-mode wave & gang management |
| `scenes/arenas/back_alley/rumble_arena_back_alley.gd` | Arena + match state machine |
| `scenes/player/player_controller.gd` | Human-controlled fighter FSM |
| `scenes/enemies/enemy_ai.gd` | AI fighter FSM |
| `scenes/player/fighter_lod.gd` | LOD distance switching wrapper |
| `assets/shaders/cel_shaded.gdshader` | Cel + outline + team_color uniform |
| `assets/shaders/team_color_flat.gdshader` | Flat team-colour + emissive for fighters |
| `assets/environments/arena_back_alley.tres` | Env preset for back-alley arena |
| `scenes/test/test_spawn_validator.tscn` | Headless spawn/scale regression test |
| `scenes/test/test_spawn_validator.gd` | Test runner script |
