# GUTTERUMBLE — Architecture Migration Plan

**Companion freeze:** [`CANONICAL_ARCHITECTURE.md`](./CANONICAL_ARCHITECTURE.md)  
**Principle:** Consolidate toward one shared gameplay sim **before** implementing multiplayer features beyond planning.  
**Hard stop:** **Do NOT start by wiring `networked_player.gd` into the arena.**

Phases below map to Commands in the revised pack. Execute in order. Do not skip consolidation to chase online combat.

---

## Phase overview

| Phase | Command | Title | Multiplayer features? |
|------:|---------|-------|------------------------|
| 0 | 01 | Freeze docs (this pair) | No — docs only |
| 1 | 02 | Consolidation | No — quarantine / annotate / decide |
| 2 | 03 | Android offline | No net combat — shipable offline loop |
| 3 | 04 | Supabase reconcile | Metadata / SQL only |
| 4 | 05 | Dedicated server movement | Server movement only (planning → stub host) |
| 5 | 06 | Authoritative combat net | First real combat authority over ENet |
| 6 | 07 | Allies / weapons / revive | Design + sim features |
| 7 | 08 | Waves / boss | Extend GangSpawner / round flow |
| 8 | 09 | Matchmaking | `matchmaking_queue` + lobby SQL |
| 9 | 10 | Android online | Clients ↔ dedicated server |
| 10–16 | 11–17 | Per revised pack (below) | Only after 0–9 gates pass |

---

## Phase 0 — Freeze docs (Command 01) — THIS

**Exact files written:**

- `docs/engineering/CANONICAL_ARCHITECTURE.md`
- `docs/engineering/ARCHITECTURE_MIGRATION_PLAN.md`

**Acceptance:**

- Canonical paths frozen for PLAYER / COMBAT / MATCH / NETWORK / BACKEND
- Classification table covers all required systems
- RoundManager KEEP + MatchResolver DEFER recorded
- Critical Rules 1–15 present
- No gameplay `.gd` / `.tscn` changes

---

## Phase 1 — Consolidation (Command 02)

Goal: remove ambiguity without deleting until reference search is complete. **No multiplayer wiring.**

### Dependency order (execute top → bottom)

1. Re-read `CANONICAL_ARCHITECTURE.md` Critical Rules.
2. Annotate / quarantine obsolete combat & net claims (files below).
3. Record RoundManager vs MatchResolver decision in code comments + this plan (already decided: KEEP RoundManager, DEFER MatchResolver).
4. Isolate Realtime from combat documentation/claims in headers.
5. Grep references (patterns below); produce a hit list before any delete.
6. Gate: consolidation acceptance criteria (below) — then stop.

### Files Command 02 will quarantine / annotate (not delete yet)

Command 01 forbids deletion. Command 02 **searches first**, then annotates. Deletion is a later follow-up only when reference count is zero and a delete command authorizes it.

| File | Action in Command 02 |
|------|----------------------|
| `scenes/combat/combat_manager.gd` | Header: **NOT authoritative**; damage path is Hitbox → `take_damage`; mark REPLACE candidate |
| `scenes/player/networked_player.gd` | Quarantine banner: obsolete player path; **do not spawn from arenas** |
| `scenes/player/player.tscn` | Comment / doc note: non-canonical; pairs with networked_player |
| `net/realtime_sync.gd` | Isolate: not combat sync; DEFER removal; strip/avoid combat-authority comments |
| `net/remote_player_interpolator.gd` | Note: tied to obsolete Realtime combat assumption |
| `net/connection_lifecycle.gd` | Note: Realtime resume only; not dedicated-server lifecycle |
| `systems/match_resolver.gd` | Note: test-only until compare; do not autoload-drive arenas |
| `backend/match_server.gd` | Note: skeleton; rebuild around shared sim in Command 05+ |
| `docs/engineering/CANONICAL_ARCHITECTURE.md` | Already frozen — update only if forensic correction needed |
| `PROJECT_BLUEPRINT.md` / `docs/PUBLIC_RELEASE_ROADMAP.md` (optional) | Point readers at freeze docs where they claim Supabase Broadcast combat |

**Do not modify in Command 02 (gameplay behavior):**

- `scenes/player/player_controller.gd`
- `scenes/player/fighter.tscn`
- `scenes/combat/hitbox.gd` / `hurtbox.gd`
- `scenes/arenas/**/rumble_arena_*.gd` spawn paths (must remain `fighter.tscn`)

### Search patterns (Command 02 reference sweep)

Run from repo root (ripgrep / project search). Record every hit before deleting anything.

```text
networked_player
player.tscn
res://scenes/player/player.tscn
CombatManager
apply_damage
NetRealtimeSync
realtime_sync
RemotePlayerInterpolator
NetConnectionLifecycle
MatchResolver
RoundManager
MatchStart
find_rumble_match
/matchmaking
host_user_id
LobbyState
award_match_rep
fighter.tscn
take_damage
```

Suggested commands:

```bash
rg -n "networked_player|player\\.tscn|CombatManager|apply_damage|NetRealtimeSync|MatchResolver" --glob '*.gd' --glob '*.tscn' --glob '*.md'
rg -n "fighter\\.tscn|RoundManager|GangSpawner|take_damage" --glob '*.gd' --glob '*.tscn'
rg -n "host_user_id|/matchmaking|matchmaking_queue|award_match_rep" --glob '*.gd' --glob '*.sql' --glob '*.md'
```

### Acceptance criteria — Consolidation gate (Command 02)

- [ ] `CombatManager` header states it is **not** on the damage path
- [ ] `networked_player.gd` / `player.tscn` quarantined; **zero** new arena references added
- [ ] Arena spawn paths still preload **`fighter.tscn` only**
- [ ] `NetRealtimeSync` (and dependents) documented as **non-combat**; no new combat RPC on Realtime
- [ ] RoundManager vs MatchResolver decision **written in freeze + MatchResolver header**; arena still uses RoundManager only
- [ ] Reference search artifact attached to PR / notes (hit list)
- [ ] **No** wiring of `networked_player.gd` into any arena
- [ ] Offline headless / existing CI smoke still boots (autoloads parse)

---

## Phase 2 — Android offline (Command 03)

**Intent:** Pixel-class offline loop on canonical sim only.

**Files / areas (dependency order):**

1. Export / mobile renderer lock — `project.godot`, `docs/compliance/ANDROID_EXPORT.md`
2. Input / pause — `scenes/ui/pause_menu.*`, player input map
3. Arena boot path — `rumble_arena_back_alley.gd`, arena select, main menu
4. Local persistence — `LocalProfileStore`, `SaveManager`, `SupabaseManager` fallback
5. Perf baselines — `PerfLogger`, optional `fighter_lod` still DEFER if meshes missing

**Out of scope:** ENet, Realtime combat, MatchResolver arena integration.

---

## Phase 3 — Supabase reconcile (Command 04)

**Dependency order:**

1. Normalize `backend/supabase_schema.sql` (appearance JSONB **object**; confirm lobby columns)
2. Align `LobbyManager` field names to SQL (`host_id`, `open|starting|closed`)
3. Confirm rewards path = service_role only (`award_match_rep` / edge README)
4. Plan `matchmaking_queue` table (create in Command 09; document stub now)
5. Keep `RepPipeline` client as submitter that cannot escalate privilege with anon

**Exact SQL canonical file:** `backend/supabase_schema.sql`  
**Related:** `backend/edge_functions/award_match_rep.sql`, `backend/supabase_manager.gd`, `net/lobby_manager.gd`

---

## Phase 4 — Dedicated server movement (Command 05)

**Dependency order:**

1. Extract / identify shared movement + transform ownership in `PlayerController` (read-only design notes OK)
2. Rebuild plan for `backend/match_server.gd` as ENet host
3. Snapshot movement state to clients (no hit authority yet if sliced that way)
4. Do **not** revive `NetRealtimeSync` for positions as the long-term path

**Exact file focus:** `backend/match_server.gd`, later shared sim module location TBD by Command 05 design note.

---

## Phase 5 — Authoritative combat net (Command 06)

**Dependency order:**

1. Shared sim combat ticks on server (AttackConfig + Hitbox semantics)
2. Client input → server; server → `take_damage` authority
3. Presentation (CombatFeel, VFXPool) remains client-side
4. Still no `networked_player` arena shortcut — extend `fighter.tscn` / controller under authority flags instead

---

## Phase 6 — Allies / weapons / revive (Command 07)

**Dependency order:**

1. `docs/weapon_manifest.json` → code contract (single weapon data path; **no** parallel manifests)
2. Ally spawn via `GangSpawner` / `FighterPool` (player-side roster — currently absent)
3. Revive rules inside shared sim + RoundManager/wave interaction
4. Keep AttackConfig as combat numbers source unless weapon table is merged into it deliberately

---

## Phase 7 — Waves / boss (Command 08)

**Dependency order:**

1. Extend `GangSpawner` wave table
2. Boss as special wave entity using same Hitbox/Hurtbox/take_damage path
3. RoundManager / Warriors mode hooks in arena script — still no MatchResolver dual-wire unless Phase 1 deferral was lifted by explicit decision

---

## Phase 8 — Matchmaking (Command 09)

**Dependency order:**

1. Create `matchmaking_queue` in `supabase_schema.sql`
2. Wire lobby open → starting → closed per SQL
3. Hand off `server_ip` / `server_port` from `matches` row to clients
4. Remove any phantom `/matchmaking` REST assumptions from `NetworkManager` / docs

---

## Phase 9 — Android online (Command 10)

**Dependency order:**

1. Android client connects to dedicated Godot server (ENet)
2. Supabase auth + lobby metadata only
3. Lifecycle (pause/resume) against **ENet**, not Realtime combat channels
4. Device acceptance on Pixel-class hardware

---

## Phases 10–16 (Commands 11–17) — revised pack

Execute only after Phases 0–9 acceptance. Titles follow the revised pack sequence:

| Phase | Command | Focus |
|------:|---------|-------|
| 10 | 11 | Shared-sim extraction hardening (single module boundary offline ≡ server) |
| 11 | 12 | Progression / unlock economy locked to service_role + LocalProfileStore parity |
| 12 | 13 | Content arenas (subway / warehouse / parking / burning lot) on canonical spawn path |
| 13 | 14 | Performance lock (LOD meshes, pool sizes, Pixel 6a 60fps gate) |
| 14 | 15 | Platform compliance + Data Safety / Privacy final pass |
| 15 | 16 | Closed test (crash reporter, resume, disconnect) |
| 16 | 17 | Public release checklist / store rollout |

If the revised pack renames these later, update this table in place — **do not** reorder Phases 0–9.

---

## Global dependency graph

```text
Command 01 Freeze docs
    → Command 02 Consolidation (quarantine CombatManager, networked_player, Realtime)
        → Command 03 Android offline
            → Command 04 Supabase reconcile
                → Command 05 Dedicated server movement
                    → Command 06 Authoritative combat net
                        → Command 07 Allies / weapons / revive
                        → Command 08 Waves / boss
                            → Command 09 Matchmaking
                                → Command 10 Android online
                                    → Commands 11–17 (Phases 10–16)
```

Parallelism allowed only within a phase when file ownership does not conflict. **Never** parallelize Command 02 deletions with Command 06 net combat.

---

## Reminder box

```text
Do NOT start by wiring networked_player.gd into the arena.
Canonical player: scenes/player/fighter.tscn + player_controller.gd
Canonical damage: Hitbox → take_damage
Canonical match-flow (now): RoundManager
MatchResolver: evaluate later — do not dual-wire
Combat sync future: ENet dedicated server + shared sim
Supabase: auth / lobby / persistence / progression only
```
