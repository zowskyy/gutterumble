# GUTTERUMBLE — Public Release Roadmap

**Source of truth for slice status:** [`TRACKING.json`](../TRACKING.json)  
**Workflow:** Taylor worker + Frontier relay (see [`.cursor/rules/taylor-worker-frontier-relay.mdc`](../.cursor/rules/taylor-worker-frontier-relay.mdc))

Engine: Godot 4.x (GDScript, static typing) · Backend: Supabase · Target: Android / Pixel 6a @ 60fps

Each slice is 1–4 hours. No slice is `MERGED` until independently verified against its verification steps.

## How to use

1. Pick the next `NOT_STARTED` or `IN_PROGRESS` slice in `TRACKING.json` (phase order).
2. Quarterback delegates implementation to a **Taylor worker** (Task subagent).
3. Worker implements + gates; quarterback **re-runs both gate scripts** (Frontier relay) on every changed file.
4. Commit with the slice's `git_commit` message.
5. Mark `VERIFIED` only after verification steps pass — not on code-complete alone.

## Phase overview

| Phase | Goal | Slices |
|-------|------|--------|
| 0 | Core loop lockdown (single-player feel) | 0.1–0.5 |
| 1 | Multiplayer core (Supabase Realtime) | 1.1–1.5 |
| 2 | Rumble mode complete | 2.1–2.4 |
| 3 | Performance validation (Pixel 6a 60fps) | 3.1–3.4 |
| 4 | Backend hardening (RLS, auth) | 4.1–4.3 |
| 5 | Platform compliance (Play Store) | 5.1–5.4 |
| 6 | Closed test | 6.1–6.3 |
| 7 | Public release | 7.1–7.2 |

## Repo path mapping

Roadmap paths differ from this repo's layout:

| Roadmap path | Actual path |
|--------------|-------------|
| `player/player_controller.gd` | `scenes/player/player_controller.gd` |
| `combat/hitbox.gd` | `scenes/combat/hitbox.gd` |
| `systems/customization_manager.gd` | `autoloads/customization_manager.gd` |
| `net/*.gd` | Not yet created — new `net/` directory |

## Current baseline (2026-08-08)

Substantial Phase 0 combat work already exists from `BUILD_GUIDE_10X.md`:

- Full player/enemy FSM, combo, dodge, hit-react, KO
- Two arenas, round flow, customization UI
- Mobile renderer configured in `project.godot`
- Networking stubs only (`network_manager.gd`, `networked_player.gd`)

See `PROJECT_STATE.md` for detailed implementation snapshot.

## Slice details

Full slice specifications (difficulty, root cause, implemented fix, verification steps) are in the original roadmap document provided at project kickoff. `TRACKING.json` carries `acceptance_criteria`, `files`, `status`, and `notes` per slice.

**Active slice:** 0.1 — Movement Controller Feel Pass
