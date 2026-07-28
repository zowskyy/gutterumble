extends Node

signal auth_succeeded(user_id: String)
signal auth_failed(error_message: String)
signal match_connected()
signal match_connection_failed(error_message: String)

const SUPABASE_URL: String      = "https://your-project.supabase.co"
const SUPABASE_ANON_KEY: String = "your-anon-key"

var current_user_id: String = ""
var is_authenticated: bool  = false
var access_token: String    = ""

func sign_up(email: String, password: String) -> void:
	if email.is_empty() or password.is_empty():
		auth_failed.emit("Missing email or password")
		return
	var http := _make_http()
	http.request_completed.connect(_on_sign_up_completed.bind(http))
	var url := SUPABASE_URL + "/auth/v1/signup"
	http.request(url, ["Content-Type: application/json"], HTTPClient.METHOD_POST, JSON.stringify({"email": email, "password": password}))

func sign_in(email: String, password: String) -> void:
	if email.is_empty() or password.is_empty():
		auth_failed.emit("Missing email or password")
		return
	var http := _make_http()
	http.request_completed.connect(_on_sign_in_completed.bind(http))
	var url := SUPABASE_URL + "/auth/v1/token?grant_type=password"
	http.request(url, ["Content-Type: application/json"], HTTPClient.METHOD_POST, JSON.stringify({"email": email, "password": password}))

func sign_out() -> void:
	current_user_id  = ""
	is_authenticated = false
	access_token     = ""

func find_rumble_match() -> void:
	if not is_authenticated:
		match_connection_failed.emit("Not authenticated")
		return

func connect_to_match(server_ip: String, server_port: int) -> void:
	if server_ip.is_empty():
		match_connection_failed.emit("Invalid server address")
		return
	if server_port <= 0 or server_port > 65535:
		match_connection_failed.emit("Invalid server port")
		return
	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_client(server_ip, server_port)
	if err != OK:
		match_connection_failed.emit("Failed to connect: %d" % err)
		return
	multiplayer.multiplayer_peer = peer
	match_connected.emit()

func disconnect_from_match() -> void:
	if multiplayer.multiplayer_peer != null:
		multiplayer.multiplayer_peer.close()
		multiplayer.multiplayer_peer = null

func _make_http() -> HTTPRequest:
	var http := HTTPRequest.new()
	add_child(http)
	return http

func _on_sign_up_completed(result: int, _code: int, _headers: PackedStringArray, body: PackedByteArray, http: HTTPRequest) -> void:
	http.queue_free()
	if result != HTTPRequest.RESULT_SUCCESS:
		auth_failed.emit("Network error")
		return
	var parsed: Variant = JSON.parse_string(body.get_string_from_utf8())
	if parsed is Dictionary and parsed.has("id"):
		current_user_id  = parsed["id"]
		is_authenticated = true
		auth_succeeded.emit(current_user_id)
	else:
		auth_failed.emit("Sign-up failed")

func _on_sign_in_completed(result: int, _code: int, _headers: PackedStringArray, body: PackedByteArray, http: HTTPRequest) -> void:
	http.queue_free()
	if result != HTTPRequest.RESULT_SUCCESS:
		auth_failed.emit("Network error")
		return
	var parsed: Variant = JSON.parse_string(body.get_string_from_utf8())
	if parsed is Dictionary and parsed.has("access_token"):
		access_token     = parsed["access_token"]
		var user: Variant = parsed.get("user", {})
		current_user_id  = (user as Dictionary).get("id", "") if user is Dictionary else ""
		is_authenticated = true
		auth_succeeded.emit(current_user_id)
	else:
		auth_failed.emit("Sign-in failed")
