extends Node
class_name MatchStart
# Server-authoritative match countdown synchronized via shared unix timestamp.
# Clients derive remaining seconds locally so late joiners stay in visual sync.
# Integrates with LobbyManager when that autoload is present.

signal countdown_tick(seconds_remaining: int)
signal countdown_finished()

const COUNTDOWN_SECS: float = 3.0

var _fight_start_unix: float = 0.0
var _active: bool = false
var _finished: bool = false
var _last_tick: int = -1

func _ready() -> void:
	set_process(false)

func is_active() -> bool:
	return _active and not _finished

func get_fight_start_unix() -> float:
	return _fight_start_unix

func get_remaining_seconds(now_unix: float = -1.0) -> float:
	if _fight_start_unix <= 0.0:
		return COUNTDOWN_SECS
	var now: float = now_unix if now_unix >= 0.0 else Time.get_unix_time_from_system()
	return maxf(_fight_start_unix - now, 0.0)

func begin_countdown_as_server() -> void:
	if multiplayer.has_multiplayer_peer() and not multiplayer.is_server():
		return
	var start_at: float = Time.get_unix_time_from_system() + COUNTDOWN_SECS
	_set_lobby_state("STARTING")
	if multiplayer.has_multiplayer_peer():
		_rpc_sync_fight_start.rpc(start_at)
	else:
		_apply_fight_start(start_at)

@rpc("authority", "call_local", "reliable")
func _rpc_sync_fight_start(fight_start_unix: float) -> void:
	_apply_fight_start(fight_start_unix)

func _apply_fight_start(fight_start_unix: float) -> void:
	_fight_start_unix = fight_start_unix
	_active = true
	_finished = false
	_last_tick = -1
	set_process(true)
	_emit_tick_if_changed()

func _process(_delta: float) -> void:
	if not _active or _finished:
		return
	var remaining: float = get_remaining_seconds()
	_emit_tick_if_changed()
	if remaining <= 0.0:
		_finish_countdown()

func _emit_tick_if_changed() -> void:
	var tick: int = maxi(0, ceili(get_remaining_seconds()))
	if tick == _last_tick:
		return
	_last_tick = tick
	countdown_tick.emit(tick)

func _finish_countdown() -> void:
	if _finished:
		return
	_finished = true
	_active = false
	set_process(false)
	_set_lobby_state("IN_MATCH")
	countdown_finished.emit()

func _set_lobby_state(state_name: String) -> void:
	var lobby: Node = get_tree().root.get_node_or_null("LobbyManager")
	if lobby == null:
		return
	if not lobby.has_method("set_lobby_state"):
		return
	if lobby.has_method("_state_from_string"):
		lobby.set_lobby_state(lobby._state_from_string(state_name))
		return
	if lobby.has_method("LobbyState"):
		pass
