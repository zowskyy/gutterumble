# Command 04 GATE — Reconcile Supabase

```
COMMAND GATE
Implementation: PASS
Integration: PASS (LobbyManager host_id/status + lobby_members; queue → matchmaking_queue; RepPipeline → award-match-rep edge; appearance Dictionary)
Regression: see Tests
Architecture: PASS (SQL wins; single award_match_rep signature; no service_role in client; Realtime untouched)
Security: PASS (anon cannot EXECUTE award_match_rep; edge + user JWT required; auth headers documented)
Documentation: PASS (docs/backend/SUPABASE_CANONICAL_SCHEMA.md)
Unresolved defects: Live Supabase apply / Deno edge deploy UNVERIFIED in this agent (schema + client contract only)
New risks: Existing DBs with array appearance rows need migration UPDATE before CHECK; dual old RPC must be dropped on apply
Files changed:
  backend/supabase_schema.sql
  backend/migrations/20260813_canonical_schema.sql
  backend/edge_functions/award_match_rep.sql
  backend/edge_functions/README.md
  net/lobby_manager.gd
  autoloads/network_manager.gd
  backend/supabase_manager.gd
  backend/local_profile_store.gd
  systems/rep_pipeline.gd
  docs/backend/SUPABASE_CANONICAL_SCHEMA.md
  docs/engineering/COMMAND_04_GATE.md
  scenes/test/test_supabase_contract.gd
  scenes/test/test_supabase_contract.tscn
  .github/workflows/godot-ci.yml
Tests executed:
  scenes/test/test_supabase_contract.tscn — PASS=12 FAIL=0
  scenes/test/test_rep_pipeline.tscn — PASS=3 FAIL=0 (await fix so asserts actually run)
  existing godot-ci suite still listed (+ test_supabase_contract.tscn)
Next command permitted: YES (Command 05) after this PR lands and supabase contract + rep pipeline regression are green in CI
```
