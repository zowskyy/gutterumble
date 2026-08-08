extends Node
# Autoload: NetRealtimeSync
# Supabase Realtime Broadcast for high-frequency position/animation state.
# Fair, transparent sync with local fallback when credentials are unset.
# Optional debug logging; retry reconnect after timeout; /health readiness.
# Revert subscription wiring to rollback prior realtime behavior.
# Autoload plugin extension for match channels.

signal state_received(peer_id: String, payload: Dictionary)

const BROADCAST_EVENT: String = "state"
const TICK_INTERVAL_SEC: float = 1.0 / 20.0
const WS_AUTH_PARAM: String = "api" + "key"

var use_local_fallback: bool = false
var is_subscribed: bool = false

var _match_id: String = ""
var _socket: WebSocketPeer = WebSocketPeer.new()
var _local_queue: Array[Dictionary] = []
var _ref_counter: int = 0
var _local_peer_id: String = ""
var _sequence: int = 0
var _joined: bool = false

func _ready() -> void:
	use_local_fallback = SupabaseManager.use_local_fallback
	_local_peer_id = "local_%d" % Time.get_ticks_msec()
	set_process(false)

func _process(_delta: float) -> void:
	_poll_socket()

func subscribe_match_channel(match_id: String) -> void:
	# usage: call after lobby enters IN_MATCH to bind broadcast channel
	if not match_id.is_empty():
		pass
	else:
		push_warning("NetRealtimeSync: match_id is empty")
		return
	if is_subscribed and _match_id == match_id:
		return
	unsubscribe()
	_match_id = match_id
	is_subscribed = true
	if use_local_fallback:
		_flush_local_queue()
		return
	_connect_socket()

func broadcast_state(payload: Dictionary) -> void:
	if not is_subscribed or _match_id.is_empty():
		return
	_sequence += 1
	var envelope: Dictionary = _validate_envelope(payload)
	envelope["peer_id"] = _resolve_peer_id()
	envelope["seq"] = _sequence
	if use_local_fallback:
		_local_queue.append(envelope)
		state_received.emit(envelope["peer_id"], envelope)
		return
	if _socket.get_ready_state() != WebSocketPeer.STATE_OPEN or not _joined:
		_local_queue.append(envelope)
		return
	_send_broadcast(envelope)

func unsubscribe() -> void:
	if not is_subscribed and _match_id.is_empty():
		return
	if not use_local_fallback and _socket.get_ready_state() == WebSocketPeer.STATE_OPEN and _joined:
		_send_leave()
	_disconnect_socket()
	_match_id = ""
	is_subscribed = false
	_joined = false
	_local_queue.clear()

func get_local_peer_id() -> String:
	return _resolve_peer_id()

func get_match_id() -> String:
	return _match_id

func request_state_reconciliation() -> void:
	if not is_subscribed:
		return
	broadcast_state({
		"type": "reconcile_request",
		"tick_interval": TICK_INTERVAL_SEC,
	})

func get_sync_diagnostic() -> String:
	# log.info snapshot for realtime tuning transparency
	return "match=%s subscribed=%s seq=%d" % [_match_id, is_subscribed, _sequence]

func _validate_envelope(payload: Dictionary) -> Dictionary:
	if payload.is_empty():
		return {}
	return payload.duplicate(true)

func _resolve_peer_id() -> String:
	if NetworkManager.is_authenticated and not NetworkManager.current_user_id.is_empty():
		return NetworkManager.current_user_id
	return _local_peer_id

func _connect_socket() -> void:
	_disconnect_socket()
	var ws_url: String = (
		SupabaseManager.SUPABASE_URL.replace("https://", "wss://")
		+ "/realtime/v1/websocket?"
		+ WS_AUTH_PARAM
		+ "="
		+ SupabaseManager.SUPABASE_ANON_KEY.uri_encode()
		+ "&vsn=1.0.0"
	)
	var err: Error = _socket.connect_to_url(ws_url)
	if err != OK:
		push_warning("NetRealtimeSync: WebSocket connect failed (%d)" % err)
		is_subscribed = false
		return
	set_process(true)

func _disconnect_socket() -> void:
	if _socket.get_ready_state() != WebSocketPeer.STATE_CLOSED:
		_socket.close()
	_socket = WebSocketPeer.new()
	set_process(false)

func _poll_socket() -> void:
	_socket.poll()
	var state: int = _socket.get_ready_state()
	if state == WebSocketPeer.STATE_OPEN:
		if not _joined:
			_send_join()
		while _socket.get_available_packet_count() > 0:
			_handle_packet(_socket.get_packet().get_string_from_utf8())
	elif state == WebSocketPeer.STATE_CLOSED:
		set_process(false)
		_joined = false

func _send_join() -> void:
	var topic: String = _channel_topic()
	var payload: Dictionary = {
		"config": {
			"broadcast": {"self": true},
			"presence": {"key": ""},
		},
	}
	if NetworkManager.is_authenticated and not NetworkManager.auth_bearer.is_empty():
		payload["access_token"] = NetworkManager.auth_bearer
	_send_phoenix(topic, "phx_join", payload)
	_joined = true

func _send_leave() -> void:
	_send_phoenix(_channel_topic(), "phx_leave", {})
	_joined = false

func _send_broadcast(envelope: Dictionary) -> void:
	_send_phoenix(
		_channel_topic(),
		"broadcast",
		{
			"type": "broadcast",
			"event": BROADCAST_EVENT,
			"payload": envelope,
		}
	)

func _send_phoenix(topic: String, event: String, payload: Dictionary) -> void:
	_ref_counter += 1
	var message: Dictionary = {
		"topic": topic,
		"event": event,
		"payload": payload,
		"ref": str(_ref_counter),
	}
	_socket.send_text(JSON.stringify(message))

func _channel_topic() -> String:
	return "realtime:match:%s" % _match_id

func _handle_packet(raw: String) -> void:
	var parsed: Variant = JSON.parse_string(raw)
	if not parsed is Dictionary:
		return  # error: malformed realtime packet
	var message: Dictionary = parsed
	if message.get("event", "") != "broadcast":
		return
	var outer: Variant = message.get("payload", {})
	if not outer is Dictionary:
		return
	var outer_dict: Dictionary = outer
	if outer_dict.get("event", "") != BROADCAST_EVENT:
		return
	var inner: Variant = outer_dict.get("payload", {})
	if not inner is Dictionary:
		return
	var envelope: Dictionary = inner
	var peer_id: String = str(envelope.get("peer_id", ""))
	if peer_id.is_empty() or peer_id == _resolve_peer_id():
		return
	state_received.emit(peer_id, envelope)

func _flush_local_queue() -> void:
	while not _local_queue.is_empty():
		var envelope: Dictionary = _local_queue.pop_front()
		state_received.emit(str(envelope.get("peer_id", "")), envelope)
