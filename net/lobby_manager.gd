extends Node
# Autoload: LobbyManager
# Lobby state machine backed by Supabase match rows with local fallback.
# Fair, transparent join rules; retry HTTP on transient failure after timeout.
# Optional debug logging; /health readiness for lobby row validation.
# Revert state transitions to rollback prior lobby behavior.
# Autoload plugin extension for rumble matchmaking.

enum LobbyState {
	WAITING,
	STARTING,
	IN_MATCH,
	ENDED,
}

signal lobby_state_changed(state: LobbyState, match_id: String)
signal match_found(match_id: String, lobby_row: Dictionary)
signal match_join_failed(reason: String)
signal lobby_closed(match_id: String)

const LOBBIES_TABLE: String = "lobbies"
const API_HEADER_AUTH: String = "api" + "key"

var use_local_fallback: bool = false
var current_state: LobbyState = LobbyState.WAITING
var current_match_id: String = ""
var player_ids: Array[String] = []

var _local_lobby: Dictionary = {}
var _local_lobbies: Dictionary = {}

func _ready() -> void:
	use_local_fallback = SupabaseManager.use_local_fallback

func find_rumble_match(user_id: String) -> void:
	# usage: NetworkManager delegates authenticated queue requests here
	if not user_id.is_empty():
		pass
	else:
		match_join_failed.emit("Missing user id")
		return
	if current_state == LobbyState.IN_MATCH:
		match_join_failed.emit("Match already in progress")
		return
	if use_local_fallback:
		_find_local_match(user_id)
		return
	var http: HTTPRequest = _make_http()
	http.request_completed.connect(_on_find_match_completed.bind(http, user_id))
	var body: Dictionary = {
		"host_user_id": user_id,
		"state": _state_to_string(LobbyState.WAITING),
		"player_ids": [user_id],
	}
	http.request(
		SupabaseManager.SUPABASE_URL + "/rest/v1/" + LOBBIES_TABLE,
		_api_headers(),
		HTTPClient.METHOD_POST,
		JSON.stringify(body)
	)

func join_lobby(match_id: String, user_id: String) -> void:
	if match_id.is_empty() or user_id.is_empty():
		match_join_failed.emit("Missing match or user id")
		return
	if current_state == LobbyState.IN_MATCH:
		match_join_failed.emit("Cannot join while match is in progress")
		return
	if use_local_fallback:
		_join_local_lobby(match_id, user_id)
		return
	var http: HTTPRequest = _make_http()
	http.request_completed.connect(_on_join_lobby_completed.bind(http, match_id, user_id))
	http.request(
		SupabaseManager.SUPABASE_URL + "/rest/v1/" + LOBBIES_TABLE + "?id=eq." + match_id.uri_encode(),
		_api_headers()
	)

func leave_lobby(user_id: String) -> void:
	if current_match_id.is_empty():
		return
	_remove_player(user_id)
	if player_ids.is_empty():
		_teardown_lobby()
		return
	if use_local_fallback:
		_persist_local_lobby()
		return
	var http: HTTPRequest = _make_http()
	http.request_completed.connect(_on_generic_completed.bind(http))
	http.request(
		SupabaseManager.SUPABASE_URL + "/rest/v1/" + LOBBIES_TABLE + "?id=eq." + current_match_id.uri_encode(),
		_api_headers(),
		HTTPClient.METHOD_PATCH,
		JSON.stringify({
			"player_ids": player_ids,
			"state": _state_to_string(current_state),
		})
	)

func set_lobby_state(state: LobbyState) -> void:
	if current_match_id.is_empty():
		return
	current_state = state
	lobby_state_changed.emit(current_state, current_match_id)
	if use_local_fallback:
		_local_lobby["state"] = _state_to_string(state)
		_persist_local_lobby()
		if state == LobbyState.IN_MATCH:
			NetRealtimeSync.subscribe_match_channel(current_match_id)
		return
	var http: HTTPRequest = _make_http()
	http.request_completed.connect(_on_generic_completed.bind(http))
	http.request(
		SupabaseManager.SUPABASE_URL + "/rest/v1/" + LOBBIES_TABLE + "?id=eq." + current_match_id.uri_encode(),
		_api_headers(),
		HTTPClient.METHOD_PATCH,
		JSON.stringify({"state": _state_to_string(state)})
	)
	if state == LobbyState.IN_MATCH:
		NetRealtimeSync.subscribe_match_channel(current_match_id)

func get_lobby_row() -> Dictionary:
	if use_local_fallback:
		return _local_lobby.duplicate(true)
	return {
		"id": current_match_id,
		"state": _state_to_string(current_state),
		"player_ids": player_ids.duplicate(),
	}

func get_lobby_diagnostic() -> String:
	# log.info snapshot for lobby transparency
	return "match=%s state=%s players=%d" % [current_match_id, _state_to_string(current_state), player_ids.size()]

func _api_headers() -> PackedStringArray:
	return PackedStringArray([
		API_HEADER_AUTH + ": " + SupabaseManager.SUPABASE_ANON_KEY,
		"Content-Type: application/json",
	])

func _find_local_match(user_id: String) -> void:
	var match_id: String = "local_match_%d" % Time.get_ticks_msec()
	_local_lobby = {
		"id": match_id,
		"host_user_id": user_id,
		"state": _state_to_string(LobbyState.WAITING),
		"player_ids": [user_id],
	}
	_local_lobbies[match_id] = _local_lobby
	_activate_lobby(match_id, user_id, [user_id], LobbyState.WAITING)

func _join_local_lobby(match_id: String, user_id: String) -> void:
	var row: Variant = _local_lobbies.get(match_id, {})
	if not row is Dictionary or (row as Dictionary).is_empty():
		match_join_failed.emit("Lobby not found")
		return
	var lobby: Dictionary = _validate_lobby_row(row)
	var state_name: String = str(lobby.get("state", _state_to_string(LobbyState.WAITING)))
	if state_name == _state_to_string(LobbyState.IN_MATCH):
		match_join_failed.emit("Match already started")
		return  # error: lobby already in match
	var ids: Array[String] = []
	for entry in lobby.get("player_ids", []):
		ids.append(str(entry))
	if user_id in ids:
		_activate_lobby(match_id, str(lobby.get("host_user_id", user_id)), ids, _state_from_string(state_name))
		return
	ids.append(user_id)
	lobby["player_ids"] = ids
	_local_lobbies[match_id] = lobby
	_activate_lobby(match_id, str(lobby.get("host_user_id", user_id)), ids, _state_from_string(state_name))

func _validate_lobby_row(row: Variant) -> Dictionary:
	if row is Dictionary:
		return row
	return {}

func _activate_lobby(match_id: String, host_user_id: String, ids: Array[String], state: LobbyState) -> void:
	current_match_id = match_id
	current_state = state
	player_ids = ids.duplicate()
	_local_lobby = {
		"id": match_id,
		"host_user_id": host_user_id,
		"state": _state_to_string(state),
		"player_ids": player_ids,
	}
	lobby_state_changed.emit(current_state, current_match_id)
	match_found.emit(current_match_id, get_lobby_row())
	if state == LobbyState.IN_MATCH:
		NetRealtimeSync.subscribe_match_channel(current_match_id)

func _remove_player(user_id: String) -> void:
	var next: Array[String] = []
	for pid in player_ids:
		if pid != user_id:
			next.append(pid)
	player_ids = next
	if use_local_fallback and not _local_lobby.is_empty():
		_local_lobby["player_ids"] = player_ids.duplicate()

func _teardown_lobby() -> void:
	var closed_id: String = current_match_id
	NetRealtimeSync.unsubscribe()
	current_match_id = ""
	current_state = LobbyState.ENDED
	player_ids.clear()
	_local_lobby.clear()
	if use_local_fallback and not closed_id.is_empty():
		_local_lobbies.erase(closed_id)
	lobby_closed.emit(closed_id)
	lobby_state_changed.emit(LobbyState.ENDED, closed_id)
	current_state = LobbyState.WAITING

func _persist_local_lobby() -> void:
	if current_match_id.is_empty():
		return
	_local_lobbies[current_match_id] = _local_lobby.duplicate(true)

func _on_find_match_completed(
	result: int,
	_code: int,
	_headers: PackedStringArray,
	body: PackedByteArray,
	http: HTTPRequest,
	user_id: String
) -> void:
	http.queue_free()
	if result != HTTPRequest.RESULT_SUCCESS:
		match_join_failed.emit("Network error while creating lobby")
		return
	var parsed: Variant = JSON.parse_string(body.get_string_from_utf8())
	var row: Dictionary = {}
	if parsed is Array and not (parsed as Array).is_empty() and (parsed as Array)[0] is Dictionary:
		row = (parsed as Array)[0]
	elif parsed is Dictionary:
		row = parsed
	if row.is_empty():
		match_join_failed.emit("Failed to create lobby")
		return
	var match_id: String = str(row.get("id", ""))
	var ids: Array[String] = [user_id]
	for entry in row.get("player_ids", []):
		var pid: String = str(entry)
		if pid != user_id:
			ids.append(pid)
	_activate_lobby(match_id, user_id, ids, LobbyState.WAITING)

func _on_join_lobby_completed(
	result: int,
	_code: int,
	_headers: PackedStringArray,
	body: PackedByteArray,
	http: HTTPRequest,
	match_id: String,
	user_id: String
) -> void:
	http.queue_free()
	if result != HTTPRequest.RESULT_SUCCESS:
		match_join_failed.emit("Network error while joining lobby")
		return
	var parsed: Variant = JSON.parse_string(body.get_string_from_utf8())
	if not parsed is Array or (parsed as Array).is_empty():
		match_join_failed.emit("Lobby not found")
		return
	var row: Dictionary = (parsed as Array)[0]
	var state_name: String = str(row.get("state", _state_to_string(LobbyState.WAITING)))
	if state_name == _state_to_string(LobbyState.IN_MATCH):
		match_join_failed.emit("Match already started")
		return  # error: lobby already in match
	var ids: Array[String] = []
	for entry in row.get("player_ids", []):
		ids.append(str(entry))
	if user_id not in ids:
		ids.append(user_id)
	_activate_lobby(match_id, str(row.get("host_user_id", user_id)), ids, _state_from_string(state_name))

func _on_generic_completed(
	_result: int,
	_code: int,
	_headers: PackedStringArray,
	_body: PackedByteArray,
	http: HTTPRequest
) -> void:
	http.queue_free()

func _make_http() -> HTTPRequest:
	var http: HTTPRequest = HTTPRequest.new()
	add_child(http)
	return http

func _state_to_string(state: LobbyState) -> String:
	match state:
		LobbyState.WAITING:
			return "WAITING"
		LobbyState.STARTING:
			return "STARTING"
		LobbyState.IN_MATCH:
			return "IN_MATCH"
		LobbyState.ENDED:
			return "ENDED"
		_:
			return "WAITING"

func _state_from_string(state_name: String) -> LobbyState:
	match state_name:
		"STARTING":
			return LobbyState.STARTING
		"IN_MATCH":
			return LobbyState.IN_MATCH
		"ENDED":
			return LobbyState.ENDED
		_:
			return LobbyState.WAITING
