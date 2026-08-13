# Command 02 Reference Sweep
_Generated: 2026-08-13T22:17:33Z_

## Pattern hits

### `networked_player`
AGENTS.md:20:- **Do not wire `networked_player.gd` / `player.tscn` into arenas.**
scenes/player/player.tscn:3:[ext_resource type="Script" path="res://scenes/player/networked_player.gd" id="1"]
PROJECT_STATE.md:16:**Canonical fighter:** `fighter.tscn` + `player_controller.gd` — **not** `networked_player.gd`.  
PROJECT_STATE.md:26:Networking / Supabase Realtime / `networked_player.gd` are **scaffolding**, not a
docs/PUBLIC_RELEASE_ROADMAP.md:47:- Networking stubs only (`network_manager.gd`, `networked_player.gd`)

### `player\.tscn`
AGENTS.md:20:- **Do not wire `networked_player.gd` / `player.tscn` into arenas.**

### `CombatManager`
PROJECT_STATE.md:81:`SpecialMeter`, `SupabaseManager`, `CombatManager`, `AttackConfig`,

### `apply_damage`
scenes/combat/combat_manager.gd:16:func apply_damage(_target_id: int, _damage: float) -> void:

### `NetRealtimeSync`
PROJECT_BLUEPRINT.md:16:             NetRealtimeSync, NetConnectionLifecycle, LobbyManager
net/connection_lifecycle.gd:7:# Autoload plugin extension coordinating NetRealtimeSync.
net/connection_lifecycle.gd:28:	_resume_match_id = NetRealtimeSync.get_match_id()
net/connection_lifecycle.gd:30:		NetRealtimeSync.unsubscribe()
net/connection_lifecycle.gd:39:	NetRealtimeSync.subscribe_match_channel(_resume_match_id)
net/connection_lifecycle.gd:42:	NetRealtimeSync.request_state_reconciliation()
net/lobby_manager.gd:110:			NetRealtimeSync.subscribe_match_channel(current_match_id)
net/lobby_manager.gd:121:		NetRealtimeSync.subscribe_match_channel(current_match_id)
net/lobby_manager.gd:192:		NetRealtimeSync.subscribe_match_channel(current_match_id)
net/lobby_manager.gd:205:	NetRealtimeSync.unsubscribe()
net/realtime_sync.gd:2:# Autoload: NetRealtimeSync
net/realtime_sync.gd:39:		push_warning("NetRealtimeSync: match_id is empty")
net/realtime_sync.gd:118:		push_warning("NetRealtimeSync: WebSocket connect failed (%d)" % err)
net/remote_player_interpolator.gd:2:# Attach to a remote player Node3D to smooth position updates from NetRealtimeSync.
net/remote_player_interpolator.gd:39:	# usage: feed NetRealtimeSync.state_received payloads for remote fighters

### `realtime_sync`
PROJECT_BLUEPRINT.md:20:Net:         net/realtime_sync.gd, remote_player_interpolator.gd,
PROJECT_BLUEPRINT.md:80:| `net/realtime_sync.gd` | Supabase Broadcast position sync |
docs/CITATION_MAP.md:74:**Repo path (planned):** `net/realtime_sync.gd`

### `RemotePlayerInterpolator`
net/remote_player_interpolator.gd:20:		push_warning("RemotePlayerInterpolator: parent must be Node3D")

### `NetConnectionLifecycle`
PROJECT_BLUEPRINT.md:16:             NetRealtimeSync, NetConnectionLifecycle, LobbyManager
net/connection_lifecycle.gd:2:# Autoload: NetConnectionLifecycle

### `MatchResolver`
AGENTS.md:19:- Canonical match flow: `RoundManager` + `GangSpawner` (do not dual-wire `MatchResolver`).
PROJECT_BLUEPRINT.md:17:             MatchResolver, RepPipeline, ShaderWarmup, CrashReporter
systems/match_resolver.gd:2:# Autoload: MatchResolver
systems/match_resolver.gd:8:# usage: MatchResolver.evaluate(state, MatchResolver.WinMode.ELIMINATION)
scenes/test/test_match_resolver.gd:15:	print("[MatchResolver] PASS=%d FAIL=%d" % [_pass_count, _fail_count])
scenes/test/test_match_resolver.gd:19:	if not MatchResolver:
scenes/test/test_match_resolver.gd:20:		return  # error: MatchResolver autoload missing
scenes/test/test_match_resolver.gd:32:	var result: Dictionary = MatchResolver.evaluate(state, MatchResolver.WinMode.ELIMINATION)
scenes/test/test_match_resolver.gd:34:	_assert(result.get("reason") == MatchResolver.REASON_ELIMINATION, "elimination reason")
scenes/test/test_match_resolver.gd:41:	var result: Dictionary = MatchResolver.evaluate(state, MatchResolver.WinMode.ELIMINATION)
scenes/test/test_match_resolver.gd:50:	var result: Dictionary = MatchResolver.evaluate(state, MatchResolver.WinMode.TIMER_EXPIRY)
scenes/test/test_match_resolver.gd:52:	_assert(result.get("reason") == MatchResolver.REASON_TIMER, "timer reason")
scenes/test/test_match_resolver.gd:60:	var result: Dictionary = MatchResolver.evaluate(state, MatchResolver.WinMode.TIMER_EXPIRY)
scenes/test/test_match_resolver.gd:69:	var a: Dictionary = MatchResolver.evaluate(state, MatchResolver.WinMode.ELIMINATION)
scenes/test/test_match_resolver.gd:70:	var b: Dictionary = MatchResolver.evaluate(state, MatchResolver.WinMode.ELIMINATION)
scenes/test/test_match_resolver.gd:80:		print("[MatchResolver] PASS: %s" % label)
scenes/test/test_match_resolver.gd:83:		printerr("[MatchResolver] FAIL: %s" % label)  # error: assertion failed
scenes/test/test_match_resolver.tscn:5:[node name="TestMatchResolver" type="Node"]

### `RoundManager`
AGENTS.md:19:- Canonical match flow: `RoundManager` + `GangSpawner` (do not dual-wire `MatchResolver`).
PROJECT_BLUEPRINT.md:18:             FighterPool, GangSpawner, CombatFeel, RoundManager, SaveManager, …
BUILD_GUIDE_10X.md:80:**What it does:** A rooftop or subway-platform arena reusing all existing systems (FighterPool, GangSpawner, RoundManager) — proves the architecture generalizes and gives the main menu's "GANG WARS" mode actual variety.
autoloads/special_meter.gd:8:# RoundManager.reset()-adjacent arena boot calls SpecialMeter.reset()) —
autoloads/round_manager.gd:2:# Autoload: RoundManager
PROJECT_STATE.md:80:`RoundManager`, `SaveManager`, `VFXPool`, `AnimationTreeBuilder`,
scenes/arenas/back_alley/rumble_arena_back_alley.gd:74:	# RoundManager
scenes/arenas/back_alley/rumble_arena_back_alley.gd:75:	RoundManager.reset()
scenes/arenas/back_alley/rumble_arena_back_alley.gd:76:	RoundManager.round_over.connect(_on_round_over)
scenes/arenas/back_alley/rumble_arena_back_alley.gd:77:	RoundManager.match_over.connect(_on_match_over)
scenes/arenas/back_alley/rumble_arena_back_alley.gd:206:	RoundManager.start_round()
scenes/arenas/back_alley/rumble_arena_back_alley.gd:315:	RoundManager.record_win(false)
scenes/arenas/back_alley/rumble_arena_back_alley.gd:322:	RoundManager.record_win(true)
scenes/arenas/back_alley/rumble_arena_back_alley.gd:345:		var round_txt := "Round %d  %d – %d" % [RoundManager.current_round - 1, player_score, enemy_score]
scenes/arenas/back_alley/rumble_arena_back_alley.gd:396:	RoundManager.record_win(true)
scenes/arenas/back_alley/rumble_arena_back_alley.gd:407:		"player_wins": RoundManager.player_wins,
scenes/arenas/back_alley/rumble_arena_back_alley.gd:408:		"enemy_wins": RoundManager.enemy_wins,
scenes/arenas/back_alley/rumble_arena_back_alley.gd:427:	for i in range(RoundManager.ROUNDS_TO_WIN):
scenes/arenas/back_alley/rumble_arena_back_alley.gd:428:		player_pips += ("●" if i < RoundManager.player_wins else "○") + " "
scenes/arenas/back_alley/rumble_arena_back_alley.gd:429:		enemy_pips  += ("●" if i < RoundManager.enemy_wins  else "○") + " "

### `MatchStart`
scenes/test/test_match_start.gd:16:	print("[MatchStart] PASS=%d FAIL=%d" % [_pass_count, _fail_count])
scenes/test/test_match_start.gd:25:	var start := MatchStart.new()
scenes/test/test_match_start.gd:36:	var start := MatchStart.new()
scenes/test/test_match_start.gd:47:	var server_view := MatchStart.new()
scenes/test/test_match_start.gd:48:	var client_view := MatchStart.new()
scenes/test/test_match_start.gd:67:		print("[MatchStart] PASS: %s" % label)
scenes/test/test_match_start.gd:70:		printerr("[MatchStart] FAIL: %s" % label)  # error: assertion failed
scenes/test/test_match_start.tscn:5:[node name="TestMatchStart" type="Node"]
net/match_start.gd:2:class_name MatchStart

### `find_rumble_match`
PROJECT_STATE.md:117:| Supabase matchmaking | `find_rumble_match()` in `network_manager.gd` is still a stub |
net/lobby_manager.gd:35:func find_rumble_match(user_id: String) -> void:
autoloads/network_manager.gd:4:# Revert find_rumble_match wiring to rollback prior matchmaking behavior.
autoloads/network_manager.gd:6:# usage: sign_in before find_rumble_match for authenticated lobby join.
autoloads/network_manager.gd:45:func find_rumble_match() -> void:
autoloads/network_manager.gd:51:	LobbyManager.find_rumble_match(current_user_id)

### `matchmaking`
BUILD_GUIDE_10X.md:92:- Full multiplayer matchmaking — `SupabaseManager` stub needs a real backend endpoint
backend/local_profile_store.gd:82:	# Local mode: instant "queued" — no remote matchmaking server.
backend/supabase_manager.gd:92:		SUPABASE_URL + "/rest/v1/matchmaking",
autoloads/network_manager.gd:4:# Revert find_rumble_match wiring to rollback prior matchmaking behavior.
autoloads/network_manager.gd:5:# Autoload plugin extension delegating rumble matchmaking to LobbyManager.
PROJECT_STATE.md:117:| Supabase matchmaking | `find_rumble_match()` in `network_manager.gd` is still a stub |
net/lobby_manager.gd:7:# Autoload plugin extension for rumble matchmaking.

### `host_user_id`
net/lobby_manager.gd:51:		"host_user_id": user_id,
net/lobby_manager.gd:146:		"host_user_id": user_id,
net/lobby_manager.gd:167:		_activate_lobby(match_id, str(lobby.get("host_user_id", user_id)), ids, _state_from_string(state_name))
net/lobby_manager.gd:172:	_activate_lobby(match_id, str(lobby.get("host_user_id", user_id)), ids, _state_from_string(state_name))
net/lobby_manager.gd:179:func _activate_lobby(match_id: String, host_user_id: String, ids: Array[String], state: LobbyState) -> void:
net/lobby_manager.gd:185:		"host_user_id": host_user_id,
net/lobby_manager.gd:277:	_activate_lobby(match_id, str(row.get("host_user_id", user_id)), ids, _state_from_string(state_name))

### `award_match_rep`
PROJECT_BLUEPRINT.md:24:Backend:     backend/supabase_schema.sql (RLS), edge_functions/award_match_rep.sql
systems/rep_pipeline.gd:3:# Server-validated match result write path; rep via award_match_rep RPC/trigger.
systems/rep_pipeline.gd:78:		SupabaseManager.SUPABASE_URL + "/rest/v1/rpc/award_match_rep",
backend/supabase_schema.sql:302:CREATE OR REPLACE FUNCTION public.award_match_rep(
backend/supabase_schema.sql:343:REVOKE ALL ON FUNCTION public.award_match_rep FROM PUBLIC;
backend/supabase_schema.sql:344:GRANT EXECUTE ON FUNCTION public.award_match_rep TO service_role;
backend/auth_test_plan.md:71:| 5.2 | Anon calls award_match_rep | `POST /rest/v1/rpc/award_match_rep` with anon key | `401` / permission denied |
backend/auth_test_plan.md:72:| 5.3 | User JWT calls award_match_rep | A JWT → RPC with inflated rep_delta | `401` / permission denied |
backend/edge_functions/README.md:3:## award_match_rep
backend/edge_functions/README.md:13:4. Invoke `award_match_rep` RPC using the **service_role** key (server-side only).
backend/edge_functions/README.md:20:| `award_match_rep` DB function | 10 calls per user | 60 seconds | SQL exception → `429` |
backend/edge_functions/README.md:27:- [ ] Deploy `award_match_rep.sql` via Supabase SQL editor
backend/edge_functions/award_match_rep.sql:1:-- Supabase Edge Function reference: award_match_rep
backend/edge_functions/award_match_rep.sql:18:CREATE OR REPLACE FUNCTION public.award_match_rep(
backend/edge_functions/award_match_rep.sql:39:		RAISE EXCEPTION 'unauthorized: award_match_rep requires service_role';
backend/edge_functions/award_match_rep.sql:94:REVOKE ALL ON FUNCTION public.award_match_rep(UUID, UUID, UUID, INT, INT, JSONB) FROM PUBLIC;
backend/edge_functions/award_match_rep.sql:95:GRANT EXECUTE ON FUNCTION public.award_match_rep(UUID, UUID, UUID, INT, INT, JSONB) TO service_role;

### `fighter\.tscn`
AGENTS.md:17:- Canonical fighter: `scenes/player/fighter.tscn` + `player_controller.gd`.
assets/characters/mouse/ANIMATION_TREE_SETUP.md:16:## 2. Swap mesh into fighter.tscn / mouse_enemy.tscn
assets/characters/mouse/ANIMATION_TREE_SETUP.md:18:In `scenes/player/fighter.tscn` (and identically for `mouse_enemy.tscn`):
autoloads/gang_spawner.gd:11:const PLAYER_SCENE := "res://scenes/player/fighter.tscn"
PROJECT_STATE.md:16:**Canonical fighter:** `fighter.tscn` + `player_controller.gd` — **not** `networked_player.gd`.  
scenes/test/test_spawn_validator.gd:6:const FIGHTER_SCENE := preload("res://scenes/player/fighter.tscn")
scenes/arenas/back_alley/rumble_arena_back_alley.gd:10:const PLAYER_SCENE := preload("res://scenes/player/fighter.tscn")

### `take_damage`
AGENTS.md:18:- Canonical combat: `Hitbox` / `Hurtbox` + `AttackConfig` → `take_damage`.
scenes/player/player_controller.gd:275:		if target.has_method("take_damage"):
scenes/player/player_controller.gd:276:			target.take_damage(data.damage, "special_aoe")
scenes/player/player_controller.gd:429:	if target.has_method("take_damage"):
scenes/player/player_controller.gd:430:		target.take_damage(data.damage, current_attack_id)
scenes/player/player_controller.gd:449:func take_damage(amount: float, attack_id: String = "") -> void:
scenes/player/networked_player.gd:52:func take_damage(amount: float) -> void:
scenes/enemies/enemy_ai.gd:2:# AI-controlled fighter. Exposes the same take_damage / is_dead / health API
scenes/enemies/enemy_ai.gd:294:	if target.has_method("take_damage"):
scenes/enemies/enemy_ai.gd:295:		target.take_damage(data.damage, current_attack_id)
scenes/enemies/enemy_ai.gd:310:func take_damage(amount: float, attack_id: String = "") -> void:
PROJECT_STATE.md:17:**Canonical combat:** Hitbox/Hurtbox + AttackConfig → `take_damage`.  
autoloads/animation_tree_builder.gd:77:	# take_damage() can fire at any time a fighter isn't invulnerable — which

## Arena spawn path check
autoloads/gang_spawner.gd:11:const PLAYER_SCENE := "res://scenes/player/fighter.tscn"
autoloads/gang_spawner.gd:68:	var inst: Node3D = FighterPool.pull(PLAYER_SCENE, spawn_point.global_transform)
autoloads/gang_spawner.gd:152:		FighterPool.push(PLAYER_SCENE, _player_ref)
scenes/arenas/back_alley/rumble_arena_back_alley.gd:10:const PLAYER_SCENE := preload("res://scenes/player/fighter.tscn")
scenes/arenas/back_alley/rumble_arena_back_alley.gd:66:	FighterPool.preload_scene(PLAYER_SCENE.resource_path, self)
scenes/arenas/back_alley/rumble_arena_back_alley.gd:100:	_player = FighterPool.pull(PLAYER_SCENE.resource_path, _player_spawn.global_transform)
scenes/arenas/back_alley/rumble_arena_back_alley.gd:376:			FighterPool.push(PLAYER_SCENE.resource_path, _player)
scenes/arenas/back_alley/rumble_arena_back_alley.gd:416:	FighterPool.return_all(PLAYER_SCENE.resource_path)
