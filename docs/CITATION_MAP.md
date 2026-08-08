# GUTTERUMBLE — Citation Map (Agent Reference)

_Last verified: 2026-08-08 via web search. Update this file when slices or standards change._

This map is the quarterback's source of truth for **citation-backed decisions**. Consult before implementing; update after web search finds new evidence.

---

## Workflow integration

| Layer | Rule file | Role |
|-------|-----------|------|
| Quarterback | `.cursor/rules/quarterback-worker.mdc` | Decompose, delegate, re-gate, deliver |
| Taylor worker | `.cursor/rules/taylor-worker-frontier-relay.mdc` | Implement slices only; return file list + gate status |
| Frontier relay | same + `AGENTS.md` | Both gate scripts until PASS on every changed file |
| Web verify | `.cursor/rules/web-search-verify.mdc` | Search before technical claims; update this map |
| Ship | `.cursor/rules/ship-finished-work.mdc` | No partial deliverables |

---

## Phase 0 — Core loop

### Slice 0.1 — Movement / input buffer ✅ CODE_COMPLETE

| Claim | Verified? | Source |
|-------|-----------|--------|
| Movement in `_physics_process` + `move_and_slide()` | ✅ | [Godot CharacterBody3D movement](https://uhiyama-lab.com/en/notes/godot/characterbody3d-movement/) |
| Input buffer 100–200ms window | ✅ | [Input buffering patterns](https://github.com/raduacg/game-mechanics-optimizations/blob/main/72_input_buffering.md); [Souls-like buffer 200ms](https://codingquests.io/blog/how-to-make-a-souls-like-game-in-godot-4) |
| `@export` tunables for designer iteration | ✅ | Same input-buffer doc recommends `@export` buffer window |
| `lerp_angle` for turn cap | ✅ | [3D character controller tutorial](https://codingquests.io/blog/godot-4-3d-character-controller-tutorial) |
| **Our choice:** 120ms buffer, `@export turn_speed` | ✅ | Within cited 100–200ms range |

**Repo path:** `scenes/player/player_controller.gd`

### Slice 0.2 — Hit registration ✅ CODE_COMPLETE

| Claim | Verified? | Source |
|-------|-----------|--------|
| `Area3D.area_entered` over per-frame polling | ✅ | Godot signal model; slice spec |
| One hit per swing dedup set (`_hit_this_swing`) | ✅ | Implemented in `scenes/combat/hitbox.gd` |
| Hurtbox marker via script + group | ✅ | `scenes/combat/hurtbox.gd` |
| Automated edge/center/miss test | ✅ | `scenes/test/test_hit_registration.tscn` (CI step) |
| High-speed tunneling manual test | ⚠️ Pending | Slice verification step |

**Repo paths:** `scenes/combat/hitbox.gd`, `scenes/combat/hurtbox.gd`, `scenes/test/test_hit_registration.gd`

### Slice 0.3 — Stagger / knockback

| Claim | Verified? | Source |
|-------|-----------|--------|
| Knockback via `CharacterBody3D.velocity` impulse | ✅ | Existing codebase + brawler convention |
| Input lock during stagger 200–400ms | ⚠️ Tune in slice | Slice spec |

### Slice 0.4 — Customization shader pre-warm

| Claim | Verified? | Source |
|-------|-----------|--------|
| Runtime material creation causes pipeline compile stutter | ✅ | [Godot pipeline compilations](https://docs.godotengine.org/en/4.6/tutorials/performance/pipeline_compilations.html) |
| Preload/warm at boot; avoid mid-match first-use | ✅ | Same doc — RenderingServer must see shaders at load-time |
| Shader baker on export (4.5+) | ✅ | Same doc — reduces startup, not all mid-run stutters |
| Mobile renderer supports ubershaders (4.4+) | ✅ | Same doc — Forward+ and **Mobile** only |

---

## Phase 1 — Multiplayer

### Slice 1.1 — Player state sync

| Claim | Verified? | Source |
|-------|-----------|--------|
| **Broadcast** for high-frequency position (~<50ms) | ✅ | [Supabase Realtime benchmarks](https://supabase.com/docs/guides/realtime/benchmarks); [AgileSoftLabs 2026](https://www.agilesoftlabs.com/blog/2026/05/supabase-realtime-in-production-what) |
| **Postgres Changes** for durable match results | ✅ | [Supabase subscribing to DB changes](https://supabase.com/docs/guides/realtime/subscribing-to-database-changes) — Broadcast recommended for scale |
| Postgres Changes latency 50–200ms+ | ✅ | AgileSoftLabs 2026; AI Coding Guild architecture post |
| No delivery guarantee — re-fetch on reconnect | ✅ | [AI Coding Guild gotchas](https://aicodingguild.com/blog/real-time-supabase-architecture-gotchas) |
| Target WiFi latency <150ms for movement | ⚠️ Tune | Slice spec; Broadcast cited at <50ms server-side |

**Repo path (planned):** `net/realtime_sync.gd`

### Slice 1.2 — Client interpolation

| Claim | Verified? | Source |
|-------|-----------|--------|
| Buffer last two states, interpolate | ✅ | Standard netcode; slice spec |
| Discard stale/out-of-order packets | ✅ | Slice spec |

### Slice 1.3 — Android lifecycle reconnect

| Claim | Verified? | Source |
|-------|-----------|--------|
| `NOTIFICATION_APPLICATION_PAUSED/RESUMED` | ✅ | Godot 4 Android lifecycle; slice spec |
| Tear down + re-subscribe Realtime on resume | ✅ | Supabase reconnect guidance (AI Coding Guild) |

---

## Phase 3 — Performance

### Slice 3.1 — Mobile renderer lock

| Claim | Verified? | Source |
|-------|-----------|--------|
| Project uses Mobile renderer for Pixel-class targets | ✅ | `project.godot` `config/features=Mobile`; Godot mobile guidance |
| Startup assertion for renderer path | ⚠️ Implement | Slice spec |

### Slice 3.2 — Shader warmup audit

| Claim | Verified? | Source |
|-------|-----------|--------|
| Zero compiles after loading screen | ✅ | Pipeline compilations doc + slice 0.4 |

---

## Phase 4 — Backend hardening

| Claim | Verified? | Source |
|-------|-----------|--------|
| RLS default-deny on all client-exposed tables | ✅ | Supabase security model; slice spec |
| Anon key in APK = public | ✅ | Standard Supabase client architecture |
| Rate-limit auth sign-up | ✅ | Supabase Auth rate limits; slice 4.2 |

---

## Phase 5 — Platform compliance

| Claim | Verified? | Source |
|-------|-----------|--------|
| Play Console Data Safety must match actual collection | ✅ | Google Play policy; slice spec |
| Privacy policy URL required | ✅ | Play Store listing requirements |
| Release keystore backup before first upload | ✅ | Android signing best practice; slice spec |

---

## CI / debug bar

| Check | Command / URL | Green means |
|-------|---------------|-------------|
| Godot headless | `.github/workflows/godot-ci.yml` | Boot main scene + spawn validator, no SCRIPT ERROR |
| Gate check | `.github/workflows/gate-check.yml` | Gate scripts PASS on changed files |
| Local gate | `bash scripts/gate-file.sh --file <path>` | Both reviewers PASS |
| Debug worker | Task `subagent_type=debug` | Run when CI or headless repro fails |

**Current PR #3 CI (2026-08-08):** `gate` ✅ · `headless-check` ✅

---

## Slice status quick reference

See `TRACKING.json` for live status. Phase order: 0 → 1 → 2 → 3 → 4 → 5 → 6 → 7.

**Next implementation slice:** 0.3 — Stagger / Knockback Tuning
