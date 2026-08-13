# Supabase Edge Functions — Security Notes

## award_match_rep / award-match-rep

Privileged server-side path that records match results and applies rep.

**Clients must never call the Postgres RPC with the anon key.**
Use the Deno edge function:

`POST /functions/v1/award-match-rep`

Headers:

- `apikey: <anon>`
- `Authorization: Bearer <user access_token>` (from sign-in — not anon, not service_role)
- `Content-Type: application/json`

Body (same `p_*` fields as `RepPipeline` / SQL):

```json
{
  "p_match_id": "<uuid>",
  "p_user_id": "<uuid>",
  "p_character_id": "<uuid>",
  "p_won": true,
  "p_rep_delta": 25,
  "p_summary": {}
}
```

`service_role` stays server-side only (edge secrets). Never ship it in the APK/client.

Canonical SQL signature (reference: `award_match_rep.sql`, `supabase_schema.sql`):

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

### Session validation (Deno wrapper)

1. Edge function receives `Authorization: Bearer <access_token>`.
2. Validate JWT with `supabase.auth.getUser(token)` — reject expired/malformed/missing (`401`).
3. Confirm `p_user_id` in the body matches `auth.user.id`.
4. Invoke `award_match_rep` RPC using the **service_role** key (server-side only).

### Rate limiting

| Layer | Limit | Window | Action on exceed |
|-------|-------|--------|------------------|
| Supabase Auth sign-up | Platform default (~30/hr per IP) | 1 hour | `429` from Auth API |
| `award_match_rep` DB function | 10 calls per user | 60 seconds | SQL exception → `429` |
| Edge function (recommended) | 5 requests per user | 60 seconds | Return `429` before hitting DB |

### Deployment checklist

- [ ] Apply `backend/supabase_schema.sql` or `backend/migrations/20260813_canonical_schema.sql`
- [ ] Deploy edge SQL reference (`award_match_rep.sql`) if applying piecemeal
- [ ] Create edge function `award-match-rep` with `verify_jwt = true`
- [ ] Store `SUPABASE_SERVICE_ROLE_KEY` in edge function secrets (never in APK)
- [ ] Integration test: valid session → `200`, tampered token → `401`, cross-user body → `403`, anon RPC → denied
