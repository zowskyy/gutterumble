# Agent instructions — GutterRumble

Godot 4.7 Android-first multiplayer street-brawler.

## Authoritative engineering docs

Treat these as ground truth over older roadmaps (`TRACKING.json`, `BUILD_GUIDE*`, `PROJECT_BLUEPRINT.md`, `PUBLIC_RELEASE_ROADMAP.md`) when they conflict:

1. [`docs/engineering/REPOSITORY_AUDIT.md`](docs/engineering/REPOSITORY_AUDIT.md)
2. [`docs/engineering/CANONICAL_ARCHITECTURE.md`](docs/engineering/CANONICAL_ARCHITECTURE.md)
3. [`docs/engineering/ARCHITECTURE_MIGRATION_PLAN.md`](docs/engineering/ARCHITECTURE_MIGRATION_PLAN.md)
4. [`docs/engineering/IMPLEMENTATION_DEPENDENCY_GRAPH.md`](docs/engineering/IMPLEMENTATION_DEPENDENCY_GRAPH.md)
5. [`docs/engineering/COMMAND_AUDIT_LOOP.md`](docs/engineering/COMMAND_AUDIT_LOOP.md)

## Critical architecture rules

- Canonical fighter: `scenes/player/fighter.tscn` + `player_controller.gd`.
- Canonical combat: `Hitbox` / `Hurtbox` + `AttackConfig` → `take_damage`.
- Canonical match flow: `RoundManager` + `GangSpawner` (do not dual-wire `MatchResolver`).
- **Do not wire `networked_player.gd` / `player.tscn` into arenas.**
- Supabase Realtime is **not** combat authority. ENet + dedicated Godot server is.
- Clients send input intent only; server owns damage, KO, rewards, waves, results.
- Never put Supabase service-role credentials in the Android client.
- Preserve offline single-player.

## Process

Every slice: `INSPECT → REPRODUCE → TRACE → CLASSIFY → PATCH → TEST → REGRESSION → AUDIT → DOCUMENT → GATE`  
(see `COMMAND_AUDIT_LOOP.md`). Status is PASS / FAIL / UNVERIFIED — never promote UNVERIFIED to PASS.

## Environment

Optional cloud bootstrap: `bash scripts/install-agent-environment.sh`
