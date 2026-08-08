# Play Console Data Safety Form — Field Mapping

Template for GUTTERUMBLE. Cross-check against `backend/supabase_schema.sql` before each release.

**App package:** `com.gutterumble.game` (update when finalized)  
**Last reviewed:** 2026-08-08

---

## Data collection summary

| Collected? | Data type | Purpose | Encrypted in transit | User can request deletion |
|------------|-----------|---------|----------------------|---------------------------|
| Yes | Email address | Account creation, sign-in | Yes (TLS) | Yes |
| Yes | User IDs | Account linking, match history | Yes | Yes |
| Yes | Gameplay stats (wins, placement, rep) | Leaderboards, progression | Yes | Yes |
| Yes | In-app purchase history | Unlock verification (if IAP added) | Yes | Yes |
| Yes | App interactions (match events) | Analytics, crash debugging | Yes | Yes |
| Yes | Crash logs | Stability (local `user://crashes/`) | Yes (if uploaded) | Yes |
| No | Precise location | — | — | — |
| No | Contacts | — | — | — |
| No | Photos / videos | — | — | — |
| No | Financial info (direct) | — | — | — |

---

## Schema → Play Console mapping

### Account info

| Schema field | Table | Play Console category | Notes |
|--------------|-------|----------------------|-------|
| `email` | `players` | Personal info → Email address | Required for Supabase Auth |
| `id` (UUID) | `players` | Personal info → User IDs | Opaque identifier |
| `display_name` | `players` | Personal info → Name (optional) | Only if user sets one |

### Gameplay & progression

| Schema field | Table | Play Console category | Notes |
|--------------|-------|----------------------|-------|
| `rep`, `level`, `health` | `characters` | App activity → Gameplay info | In-game progression |
| `appearance` | `characters` | App activity → Other user-generated content | Cosmetic JSON, no PII |
| `placement`, `rep_delta`, `stats` | `match_results` | App activity → Gameplay info | Per-match summary |
| `status`, `gangs` | `matches` | App activity → Gameplay info | Match metadata |
| `settings` | `lobbies` | App activity → Gameplay info | Lobby preferences |
| `item_id`, `source` | `customization_inventory` | App activity → Gameplay info | Cosmetic unlocks |

### Diagnostics

| Source | Play Console category | Notes |
|--------|----------------------|-------|
| `user://crashes/*.log` (CrashReporter) | App info and performance → Crash logs | Local file; declare if telemetry upload added |
| `user://perf_log.csv` (PerfLogger) | App info and performance → Diagnostics | Dev/QA only; disable in release |

### Public / non-personal

| Schema field | Table | Collected? | Notes |
|--------------|-------|------------|-------|
| `name`, `category`, `rarity` | `appearance_items` | No (catalog) | Static game content |
| `name`, `color_*` | `gangs` | No (in-game) | Fictional gang names |

---

## Play Console form answers (draft)

1. **Does your app collect or share user data?** → Yes  
2. **Is all data encrypted in transit?** → Yes (HTTPS to Supabase)  
3. **Can users request data deletion?** → Yes (support email + Supabase account delete)  
4. **Data shared with third parties?** → Yes — Supabase (hosting/auth/database)  
5. **Data used for advertising?** → No  
6. **Committed to Play Families policy?** → No (rated Teen due to cartoon violence)

---

## Pre-submit checklist

- [ ] Schema diff reviewed — new columns added to this doc
- [ ] Privacy policy URL matches Play listing
- [ ] Crash/perf logging matches actual release build flags
- [ ] Supabase DPA on file
