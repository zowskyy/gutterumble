# GUTTERUMBLE — Project Blueprint

> **Architecture authority (2026-08-13):** Prefer
> [`docs/engineering/CANONICAL_ARCHITECTURE.md`](docs/engineering/CANONICAL_ARCHITECTURE.md),
> [`docs/engineering/REPOSITORY_AUDIT.md`](docs/engineering/REPOSITORY_AUDIT.md), and
> [`docs/engineering/ARCHITECTURE_MIGRATION_PLAN.md`](docs/engineering/ARCHITECTURE_MIGRATION_PLAN.md)
> over this blueprint when they conflict.
>
> **Critical:** Canonical fighter is `fighter.tscn` + `player_controller.gd`.
> Do **not** wire `networked_player.gd` into arenas. Supabase Realtime is **not**
> combat authority — future gameplay transport is ENet + dedicated Godot server.
> Phase 1 “CODE_COMPLETE” multiplayer rows below are **scaffolding**, not a working foundation.

**Genre:** Warriors-style arena brawler (many-on-many)  
**Engine:** Godot 4.7 (Mobile renderer)  
**Stack:** GDScript, Supabase (auth/lobby/persistence), ENet dedicated server (planned), local fallback, cel-shaded 3D  
**Roadmap:** engineering docs above · [`TRACKING.json`](TRACKING.json) · [`docs/CITATION_MAP.md`](docs/CITATION_MAP.md)

## Vision

Fast, arcade-style street brawler where the player and their gang fight enemy gangs in tight urban arenas. Inspired by PS2-era Warriors games: many fighters on screen, readable team colours, punchy combat feedback.

## Architecture

```
Autoloads:   GameManager, CustomizationManager, NetworkManager, SupabaseManager
             NetRealtimeSync, NetConnectionLifecycle, LobbyManager
             MatchResolver, RepPipeline, ShaderWarmup, CrashReporter
             FighterPool, GangSpawner, CombatFeel, RoundManager, SaveManager, …
Scenes:      MainMenu → CharacterCreator → ArenaSelect → RumbleArena
Net:         net/realtime_sync.gd, remote_player_interpolator.gd,
             connection_lifecycle.gd, lobby_manager.gd, match_start.gd
Systems:     systems/match_resolver.gd, systems/rep_pipeline.gd
Combat:      scenes/combat/hitbox.gd, hurtbox.gd, player_controller.gd, enemy_ai.gd
Backend:     backend/supabase_schema.sql (RLS), edge_functions/award_match_rep.sql
```

## Public Release Roadmap — Implementation Status

| Phase | Focus | Code status |
|-------|-------|-------------|
| 0 | Core loop lockdown | ✅ 0.1–0.4 CODE_COMPLETE · 0.5 acceptance pending |
| 1 | Multiplayer core | ✅ 1.1–1.4 CODE_COMPLETE · 1.5 device test pending |
| 2 | Rumble mode | ✅ 2.1–2.3 CODE_COMPLETE · 2.4 device test pending |
| 3 | Performance | ✅ 3.1–3.2 CODE_COMPLETE · 3.3–3.4 Pixel 6a profiling pending |
| 4 | Backend hardening | ✅ 4.1–4.2 CODE_COMPLETE · 4.3 adversarial pass pending |
| 5 | Platform compliance | ✅ Templates in `docs/compliance/` · Play Console manual steps pending |
| 6 | Closed test | ✅ 6.1 crash reporter · 6.2–6.3 external testers pending |
| 7 | Public release | 📋 Checklist in `docs/compliance/STORE_LISTING.md` · manual rollout |

## Original Blueprint Slices (BUILD_GUIDE_10X) — All Done

| # | Slice | Status |
|---|-------|--------|
| 1 | FighterPool autoload | ✅ Done |
| 2 | PerfLogger autoload | ✅ Done |
| 3 | Team colour shader refactor | ✅ Done |
| 4 | GangSpawner — warriors-mode many-vs-many | ✅ Done |
| 5 | MultiplayerSpawner + MultiplayerSynchronizer | ✅ Done (skeleton; Supabase Realtime in Phase 1) |
| 6 | WorldEnvironment preset | ✅ Done |
| 7 | LOD fighter distance system | ✅ Done (script exists; mesh variants blocked on assets) |
| 8 | HUD upgrade | ✅ Done |
| 9 | Spawn validator test scene | ✅ Done |
| 10 | Project settings lock | ✅ Done |

## Headless CI Tests

| Test | Slice |
|------|-------|
| `test_spawn_validator.tscn` | Blueprint #9 |
| `test_hit_registration.tscn` | 0.2 |
| `test_customization_warmup.tscn` | 0.4 |
| `test_match_resolver.tscn` | 2.2 |
| `test_match_start.tscn` | 2.1 |
| `test_rep_pipeline.tscn` | 2.3 |
| `test_shader_warmup.tscn` | 3.2 |
| `test_crash_reporter.tscn` | 6.1 |

## Non-goals (deferred)

- Rollback netcode (Snopek addon — future phase)
- Root-motion AnimationTree (blocked on GLB combat anims)
- MultiMesh batching (if >8 identical fighters cause draw-call issues)

## File Map

| File | Role |
|------|------|
| `scenes/player/player_controller.gd` | Human FSM + input buffer + stagger |
| `scenes/combat/hitbox.gd` | Per-swing hit dedup component |
| `net/realtime_sync.gd` | Supabase Broadcast position sync |
| `net/lobby_manager.gd` | Lobby state machine |
| `systems/match_resolver.gd` | Deterministic win/loss |
| `systems/rep_pipeline.gd` | Server-validated rep awards |
| `autoloads/shader_warmup.gd` | Boot-time pipeline warmup |
| `backend/supabase_schema.sql` | Tables + RLS policies |
| `docs/compliance/` | Play Store compliance templates |
