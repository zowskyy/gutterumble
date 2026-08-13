extends Node
# Headless Supabase client/SQL contract regression (Command 04).
# Asserts lobby status mapping, matchmaking_queue path, appearance Dictionary,
# and local RepPipeline submit-once. Run via godot-ci / headless Godot.
# Run: godot --headless --path . res://scenes/test/test_supabase_contract.tscn

var _pass_count: int = 0
var _fail_count: int = 0

func _ready() -> void:
	await get_tree().process_frame
	await _run_all_tests()
	print("[SupabaseContract] PASS=%d FAIL=%d" % [_pass_count, _fail_count])
	get_tree().quit(0 if _fail_count == 0 else 1)

func _run_all_tests() -> void:
	_test_lobby_status_mapping()
	_test_matchmaking_queue_path()
	_test_appearance_dictionary_local()
	await _test_rep_pipeline_local_once()

func _test_lobby_status_mapping() -> void:
	_assert(
		LobbyManager._state_to_string(LobbyManager.LobbyState.WAITING) == "open",
		"WAITING maps to open"
	)
	_assert(
		LobbyManager._state_to_string(LobbyManager.LobbyState.STARTING) == "starting",
		"STARTING maps to starting"
	)
	_assert(
		LobbyManager._state_to_string(LobbyManager.LobbyState.IN_MATCH) == "closed",
		"IN_MATCH maps to closed"
	)
	_assert(
		LobbyManager._state_to_string(LobbyManager.LobbyState.ENDED) == "closed",
		"ENDED maps to closed"
	)
	_assert(
		LobbyManager._state_from_string("open") == LobbyManager.LobbyState.WAITING,
		"open maps back to WAITING"
	)
	_assert(
		LobbyManager._state_from_string("starting") == LobbyManager.LobbyState.STARTING,
		"starting maps back to STARTING"
	)

func _test_matchmaking_queue_path() -> void:
	var path: String = SupabaseManager.MATCHMAKING_QUEUE_PATH
	_assert(path.contains("matchmaking_queue"), "queue path contains matchmaking_queue")
	_assert(not path.ends_with("/matchmaking"), "queue path is not phantom /matchmaking")

func _test_appearance_dictionary_local() -> void:
	if not SupabaseManager.use_local_fallback:
		_assert(false, "expected local fallback for appearance test")
		return
	var store: Node = SupabaseManager.get_node_or_null("LocalProfileStore")
	if store == null:
		_assert(false, "LocalProfileStore missing under SupabaseManager")
		return
	var user_id: String = "contract_user_%d" % Time.get_ticks_msec()
	var char_id: String = store.create_character(user_id, {"name": "ContractFighter", "appearance": {}})
	_assert(not char_id.is_empty(), "local character created")
	var appearance: Dictionary = {
		"skin_idx": 1,
		"hair_idx": 2,
		"shirt_idx": 0,
		"pants_idx": 0,
		"shoe_idx": 0,
		"gang_idx": 0,
		"gang_color": "#aabbcc",
	}
	# Typed Dictionary path exercised by SupabaseManager public API.
	SupabaseManager.update_character(char_id, appearance)
	var rows: Array = store.get_characters(user_id)
	var found: bool = false
	for row in rows:
		if row is Dictionary and str(row.get("id", "")) == char_id:
			var got: Variant = row.get("appearance", null)
			found = got is Dictionary and int((got as Dictionary).get("skin_idx", -1)) == 1
			break
	_assert(found, "appearance update_character accepts Dictionary locally")

func _test_rep_pipeline_local_once() -> void:
	if RepPipeline == null:
		_assert(false, "RepPipeline autoload missing")
		return
	RepPipeline.reset_session()
	var state: Dictionary = {"awarded": false, "delta": -1}
	var handler := func(_uid: String, delta: int, _rid: String) -> void:
		state["delta"] = delta
		state["awarded"] = (delta == RepPipeline.WIN_REP)
	RepPipeline.rep_awarded.connect(handler)
	var match_id: String = "contract_match_%d" % Time.get_ticks_msec()
	RepPipeline.submit_match_result(match_id, "contract_rep_user", true, {"arena": "back_alley"})
	await get_tree().process_frame
	_assert(bool(state["awarded"]), "RepPipeline local submit awards once")
	_assert(RepPipeline.has_submitted(match_id, "contract_rep_user"), "submission tracked")
	if RepPipeline.rep_awarded.is_connected(handler):
		RepPipeline.rep_awarded.disconnect(handler)

func get_test_diagnostic() -> String:
	return "pass=%d fail=%d" % [_pass_count, _fail_count]

func _assert(condition: bool, label: String) -> void:
	if condition:
		_pass_count += 1
		print("[SupabaseContract] PASS: %s" % label)
	else:
		_fail_count += 1
		printerr("[SupabaseContract] FAIL: %s" % label)  # error: assertion failed
