# GUTTERUMBLE — Public Release Roadmap

> **DRIFT WARNING (2026-08-13):** This roadmap is historical. Authoritative order is
> [`docs/engineering/IMPLEMENTATION_DEPENDENCY_GRAPH.md`](engineering/IMPLEMENTATION_DEPENDENCY_GRAPH.md)
> and [`docs/engineering/ARCHITECTURE_MIGRATION_PLAN.md`](engineering/ARCHITECTURE_MIGRATION_PLAN.md).
> Phase 1 “Supabase Realtime” combat is **obsolete**. `net/` exists; do not treat
> `networked_player.gd` as the co-op path. Critical path: canonicalize → Android offline →
> backend schema → dedicated server → authoritative combat → 2P → content **late**.

**Legacy slice tracker:** [`TRACKING.json`](../TRACKING.json) (status rows may over-claim CODE_COMPLETE)

Engine: Godot 4.x (GDScript, static typing) · Backend: Supabase · Target: Android / Pixel 6a @ 60fps

Each slice is 1–4 hours. No slice is `MERGED` until independently verified against its verification steps.

## How to use

1. Prefer Commands 01–16 in the architecture migration plan over phase tables below.
2. Implement and verify against acceptance criteria + `COMMAND_AUDIT_LOOP.md`.
3. Commit with a clear message; mark VERIFIED only after verification steps pass.

## Phase overview (legacy)

| Phase | Goal | Slices |
|-------|------|--------|
| 0 | Core loop lockdown (single-player feel) | 0.1–0.5 |
| 1 | Multiplayer core (**planned ENet server**; Realtime ≠ combat) | 1.1–1.5 |
| 2 | Rumble mode complete | 2.1–2.4 |
| 3 | Performance validation (Pixel 6a 60fps) | 3.1–3.4 |
| 4 | Backend hardening (RLS, auth) | 4.1–4.3 |
| 5 | Platform compliance (Play Store) | 5.1–5.4 |
| 6 | Closed test | 6.1–6.3 |
| 7 | Public release | 7.1–7.2 |

## Repo path mapping

| Roadmap path | Actual path |
|--------------|-------------|
| `player/player_controller.gd` | `scenes/player/player_controller.gd` |
| `combat/hitbox.gd` | `scenes/combat/hitbox.gd` |
| `systems/customization_manager.gd` | `autoloads/customization_manager.gd` |
| `net/*.gd` | `net/` (present; Realtime stack isolated from combat) |

## Current baseline (2026-08-13)

- Full offline player/enemy FSM, combo, dodge, hit-react, KO on **fighter.tscn**
- Two arenas, round flow (`RoundManager`), customization UI
- Mobile renderer configured in `project.godot`
- Networking modules quarantined as non-canonical (`networked_player.gd`, Realtime) — see engineering freeze

See `PROJECT_STATE.md` and `docs/engineering/REPOSITORY_AUDIT.md`.

## Slice details

Full slice specifications (difficulty, root cause, implemented fix, verification steps) are in the original roadmap document provided at project kickoff. `TRACKING.json` carries `acceptance_criteria`, `files`, `status`, and `notes` per slice.

**Active slice:** 0.1 — Movement Controller Feel Pass
