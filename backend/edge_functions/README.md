# Supabase Edge Functions — Security Notes

## award_match_rep

Privileged server-side function that records match results and applies rep.
Clients must **never** call this directly with the anon key.

### Session validation

1. Edge function receives the caller's `Authorization: Bearer <access_token>` header.
2. Validate JWT with `supabase.auth.getUser(token)` — reject expired, malformed, or missing tokens (`401`).
3. Confirm `user_id` in the request body matches `auth.user.id` from the validated session.
4. Invoke `award_match_rep` RPC using the **service_role** key (server-side only).

### Rate limiting

| Layer | Limit | Window | Action on exceed |
|-------|-------|--------|------------------|
| Supabase Auth sign-up | Platform default (~30/hr per IP) | 1 hour | `429` from Auth API |
| `award_match_rep` DB function | 10 calls per user | 60 seconds | SQL exception → `429` |
| Edge function (recommended) | 5 requests per user | 60 seconds | Return `429` before hitting DB |

Add an edge-level counter (e.g. Upstash Redis or `award_rep_rate_limits` pre-check) to absorb bursts before they reach Postgres.

### Deployment checklist

- [ ] Deploy `award_match_rep.sql` via Supabase SQL editor
- [ ] Create edge function `award-match-rep` with `verify_jwt = true`
- [ ] Store `SUPABASE_SERVICE_ROLE_KEY` in edge function secrets (never in APK)
- [ ] Integration test: valid session → `200`, tampered token → `401`, cross-user body → `403`
