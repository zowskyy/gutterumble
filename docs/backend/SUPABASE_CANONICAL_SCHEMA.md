# Supabase canonical schema — Command 04 client/SQL contract

GutterRumble’s backend contract is defined by `backend/supabase_schema.sql`
(and incremental `backend/migrations/20260813_canonical_schema.sql`).
GDScript clients must match these names and types. SQL wins over legacy GDScript field names.

## Core tables (client-relevant)

| Table | Role |
|-------|------|
| `players` | Auth-mirrored profile (`id` = `auth.users.id`) |
| `characters` | Fighter rows; `appearance` JSONB **object**; `rep` server-authoritative |
| `gangs` | Gang ownership / membership via characters |
| `matches` | Match lifecycle (`pending` / `active` / `completed` / `cancelled`) |
| `match_results` | Per-user result + `rep_delta`; unique `(match_id, user_id)` |
| `lobbies` | `host_id`, `status` ∈ `open` \| `starting` \| `closed` |
| `lobby_members` | `(lobby_id, user_id)` membership — not a `player_ids` column |
| `matchmaking_queue` | Queue rows for matchmaking |
| `appearance_items` / `customization_inventory` | Cosmetic catalog + ownership |
| `award_rep_rate_limits` | Service-role-only rate limit for awards |

## Lobby status mapping (`LobbyManager` ↔ SQL)

| `LobbyManager.LobbyState` | `lobbies.status` |
|---------------------------|------------------|
| `WAITING` | `open` |
| `STARTING` | `starting` |
| `IN_MATCH` | `closed` |
| `ENDED` | `closed` |

Remote POST/PATCH bodies use **`host_id`** and **`status`** only.
Clients must **never** write columns `host_user_id`, `state`, or `player_ids`.

Join: fetch lobby → `POST lobby_members {lobby_id, user_id}`.
Leave: `DELETE` the `lobby_members` row.
In-memory `player_ids` is UX-only; remote membership is derived from `lobby_members`.

Local fallback serializes lobbies with `host_id`, `status`, and optional `member_ids`.

## Appearance object

`characters.appearance` DEFAULT `'{}'::jsonb` with
`CHECK (jsonb_typeof(appearance) = 'object')`.

Documented keys (align with `CustomizationManager` / `SaveManager`):

- `skin_idx`, `hair_idx`, `shirt_idx`, `pants_idx`, `shoe_idx`, `gang_idx`, `gang_color`

`SupabaseManager.update_character(char_id, appearance: Dictionary)` and
`LocalProfileStore.update_character` accept a **Dictionary**, not an Array.

## `matchmaking_queue`

Columns: `id`, `player_id`, `mode` (default `rumble_coop`), `region` (default `global`),
`status` (`queued` \| `matched` \| `cancelled` \| `expired`), `party_id`, `session_id`,
`queued_at`, `matched_match_id`.

RLS: player insert/select/update own rows; `FORCE ROW LEVEL SECURITY`.
Indexes: `(status, queued_at)`, `(player_id)`.

Remote queue path:

`POST /rest/v1/matchmaking_queue` with `{player_id, mode, region, status: "queued"}`.

There is **no** `/rest/v1/matchmaking` table or route.

Constant: `SupabaseManager.MATCHMAKING_QUEUE_PATH`.

## Award path (rep)

Canonical SQL:

```
award_match_rep(
  p_match_id UUID,
  p_user_id UUID,
  p_character_id UUID,
  p_won BOOLEAN,
  p_rep_delta INT,
  p_summary JSONB DEFAULT '{}'::jsonb
) RETURNS UUID
```

- `service_role` JWT required inside the function
- Rate limit via `award_rep_rate_limits`
- Match status must be `active` or `completed`
- Idempotent: `ON CONFLICT (match_id, user_id) DO NOTHING` — return existing id, do not re-apply rep
- `GRANT EXECUTE` to `service_role` only; revoked from `PUBLIC` / `anon` / `authenticated`

**Client path:** `RepPipeline` → `POST /functions/v1/award-match-rep` with
`apikey` + `Authorization: Bearer <user access_token>` and the same `p_*` body.
If `NetworkManager.auth_bearer` is empty → reject `"Not authenticated"`.

`log_match` remote remains a no-op; local fallback still logs. RepPipeline is the
canonical rewards path.

## Auth headers

| Caller | Headers |
|--------|---------|
| Auth sign-up / sign-in (`NetworkManager`) | `apikey: <anon>`, `Authorization: Bearer <anon>`, `Content-Type: application/json` |
| REST / edge after sign-in (`SupabaseManager.auth_headers`) | `apikey: <anon>`, `Authorization: Bearer <access_token or anon>`, `Content-Type: application/json`, optional `Prefer: return=representation` for inserts |

URL and anon key live only on `SupabaseManager` (`SUPABASE_URL`, `SUPABASE_ANON_KEY`).
`NetworkManager` must not duplicate them.

## What clients must never do

1. Call `/rest/v1/rpc/award_match_rep` with the anon key
2. Embed or ship `service_role` in the client / APK
3. POST to phantom `/rest/v1/matchmaking`
4. Write lobby columns `host_user_id`, `state`, or `player_ids`
5. Store `characters.appearance` as a JSON array
6. Update `characters.rep` from the client (RESTRICTIVE RLS blocks it)

## Related files

- `backend/supabase_schema.sql` — full canonical DDL
- `backend/migrations/20260813_canonical_schema.sql` — incremental apply
- `backend/edge_functions/award_match_rep.sql` — same RPC signature (Deno wraps it)
- `backend/edge_functions/README.md` — edge deploy / session validation notes
- `net/lobby_manager.gd`, `backend/supabase_manager.gd`, `systems/rep_pipeline.gd`, `autoloads/network_manager.gd`
