# Auth & RLS Adversarial Test Plan (Phase 4.3)

Run against a **staging** Supabase project. Record pass/fail for each step.
All attacks must **fail** (4xx/empty result) unless noted as the legitimate control case.

## Setup

| Actor | Credential | Purpose |
|-------|------------|---------|
| User A | `alice@test.gutterumble.dev` | Primary test account |
| User B | `bob@test.gutterumble.dev` | Cross-account attacker |
| Anon | Supabase anon key, no JWT | Unauthenticated client |
| Service | service_role key (CI only) | Privileged control path |

Create one character per user before running cross-account tests.

---

## 1. Anonymous access (default deny)

| # | Attack | Request | Expected |
|---|--------|---------|----------|
| 1.1 | Read another player's profile | `GET /rest/v1/players?id=eq.<B>` with anon key | `401` or `[]` |
| 1.2 | Read characters | `GET /rest/v1/characters` with anon key | `401` or `[]` |
| 1.3 | Read match results | `GET /rest/v1/match_results` with anon key | `401` or `[]` |
| 1.4 | Read inventory | `GET /rest/v1/customization_inventory` with anon key | `401` or `[]` |
| 1.5 | Read appearance catalog | `GET /rest/v1/appearance_items` with anon key | `200` + rows (public catalog) |

---

## 2. Cross-account reads

| # | Attack | Request | Expected |
|---|--------|---------|----------|
| 2.1 | A reads B's characters | A JWT → `GET /characters?user_id=eq.<B>` | `[]` |
| 2.2 | A reads B's match history | A JWT → `GET /match_results?user_id=eq.<B>` | `[]` |
| 2.3 | A reads B's inventory | A JWT → `GET /customization_inventory?user_id=eq.<B>` | `[]` |
| 2.4 | A reads B's player row | A JWT → `GET /players?id=eq.<B>` | `[]` |
| 2.5 | A reads B's lobby | A JWT → `GET /lobbies` (B is host, A not member) | `[]` |

---

## 3. Cross-account writes

| # | Attack | Request | Expected |
|---|--------|---------|----------|
| 3.1 | A patches B's character rep | A JWT → `PATCH /characters?id=eq.<B_char>` body `{"rep":9999}` | `0 rows` or `403` |
| 3.2 | A inserts inventory for B | A JWT → `POST /customization_inventory` body `{"user_id":"<B>",...}` | `403` / RLS violation |
| 3.3 | A inserts match result for B | A JWT → `POST /match_results` body `{"user_id":"<B>",...}` | `403` / RLS violation |
| 3.4 | A deletes B's character | A JWT → `DELETE /characters?id=eq.<B_char>` | `0 rows` |
| 3.5 | A updates B's lobby | A JWT → `PATCH /lobbies?id=eq.<B_lobby>` | `0 rows` |

---

## 4. Token tampering

| # | Attack | Request | Expected |
|---|--------|---------|----------|
| 4.1 | Expired JWT | Use token from 24h+ ago | `401 JWT expired` |
| 4.2 | Tampered payload | Change `sub` claim, re-sign with wrong secret | `401 invalid JWT` |
| 4.3 | Missing Authorization | Valid anon key, no Bearer header on privileged route | `401` or `[]` |
| 4.4 | Refresh token as access token | Send refresh token in Authorization header | `401` |

---

## 5. Rep inflation & privileged RPC

| # | Attack | Request | Expected |
|---|--------|---------|----------|
| 5.1 | Client PATCH rep on own character | A JWT → `PATCH /characters?id=eq.<A_char>` `{"rep":9999}` | `0 rows` (restrictive policy) |
| 5.2 | Anon calls award_match_rep | `POST /rest/v1/rpc/award_match_rep` with anon key | `401` / permission denied |
| 5.3 | User JWT calls award_match_rep | A JWT → RPC with inflated rep_delta | `401` / permission denied |
| 5.4 | Service role award (control) | service_role → valid RPC | `200` + rep incremented |
| 5.5 | Replay same award 15× in 60s | service_role → repeated RPC for same user | `429` after 10th call |

---

## 6. Sign-up abuse

| # | Attack | Request | Expected |
|---|--------|---------|----------|
| 6.1 | Rapid sign-up burst | 50 sign-ups from same IP in 5 min | `429` rate limited by Supabase Auth |
| 6.2 | Disposable email flood | 20 `+alias` variants | Platform spam filter / rate limit |
| 6.3 | SQL injection in email | `email: "a'; DROP TABLE players;--"` | `400` validation error, tables intact |

---

## 7. Lobby edge cases

| # | Attack | Request | Expected |
|---|--------|---------|----------|
| 7.1 | A joins as B | `POST /lobby_members` body `{"lobby_id":"...","user_id":"<B>"}` with A JWT | `403` (WITH CHECK fails) |
| 7.2 | A evicts B from A's lobby | A JWT → `DELETE /lobby_members?user_id=eq.<B>` | `0 rows` (can only delete self) |
| 7.3 | A reads match via lobby they left | After leaving, `GET /matches?id=eq.<match>` | `[]` |

---

## Sign-off

| Tester | Date | Environment | Pass/Fail |
|--------|------|-------------|-----------|
| | | staging | |

All rows must show **Expected** outcome. Any unexpected success is a **P0** security bug.
