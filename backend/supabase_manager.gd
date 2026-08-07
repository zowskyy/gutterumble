extends Node

const SUPABASE_URL: String        = "https://your-project.supabase.co"
const SUPABASE_ANON_KEY: String   = "your-anon-key"
const API_HEADERS: PackedStringArray = ["apikey: your-anon-key", "Content-Type: application/json"]

signal characters_loaded(data: Array)
signal character_created(char_id: String)
signal queued_for_match()

var use_local_fallback: bool = false
var _local_store: Node = null

func _ready() -> void:
	use_local_fallback = SUPABASE_URL.contains("your-project") or SUPABASE_ANON_KEY.contains("your-anon")
	if use_local_fallback:
		_local_store = preload("res://backend/local_profile_store.gd").new()
		_local_store.name = "LocalProfileStore"
		add_child(_local_store)
		print("SupabaseManager: using local profile fallback (user://gutterumble_local/)")

func get_characters(user_id: String) -> void:
	if use_local_fallback and _local_store:
		characters_loaded.emit(_local_store.get_characters(user_id))
		return
	if user_id.is_empty():
		return
	var http := _make_http()
	http.request_completed.connect(_on_get_characters_completed.bind(http))
	http.request(SUPABASE_URL + "/rest/v1/characters?user_id=eq." + user_id, API_HEADERS)

func create_character(user_id: String, char_data: Dictionary) -> void:
	if use_local_fallback and _local_store:
		var char_id: String = _local_store.create_character(user_id, char_data)
		character_created.emit(char_id)
		return
	if user_id.is_empty():
		return
	var http := _make_http()
	http.request_completed.connect(_on_create_character_completed.bind(http))
	var body := char_data.duplicate()
	body["user_id"] = user_id
	http.request(SUPABASE_URL + "/rest/v1/characters", API_HEADERS, HTTPClient.METHOD_POST, JSON.stringify(body))

func update_character(char_id: String, appearance: Array) -> void:
	if use_local_fallback and _local_store:
		_local_store.update_character(char_id, appearance)
		return
	if char_id.is_empty():
		return
	var http := _make_http()
	http.request_completed.connect(_on_generic_completed.bind(http))
	http.request(
		SUPABASE_URL + "/rest/v1/characters?id=eq." + char_id,
		API_HEADERS,
		HTTPClient.METHOD_PATCH,
		JSON.stringify({"appearance": appearance})
	)

func log_match(user_id: String, summary: Dictionary) -> void:
	if use_local_fallback and _local_store:
		_local_store.log_match(user_id, summary)
		return

func queue_for_match(user_id: String) -> void:
	if use_local_fallback and _local_store:
		if _local_store.queue_for_match(user_id):
			queued_for_match.emit()
		return
	if user_id.is_empty():
		return
	var http := _make_http()
	http.request_completed.connect(_on_queue_completed.bind(http))
	http.request(
		SUPABASE_URL + "/rest/v1/matchmaking",
		API_HEADERS,
		HTTPClient.METHOD_POST,
		JSON.stringify({"user_id": user_id, "queue_time": Time.get_ticks_msec()})
	)

func _make_http() -> HTTPRequest:
	var http := HTTPRequest.new()
	add_child(http)
	return http

func _on_get_characters_completed(result: int, _code: int, _headers: PackedStringArray, body: PackedByteArray, http: HTTPRequest) -> void:
	http.queue_free()
	if result != HTTPRequest.RESULT_SUCCESS:
		return
	var parsed: Variant = JSON.parse_string(body.get_string_from_utf8())
	if parsed is Array:
		characters_loaded.emit(parsed)

func _on_create_character_completed(result: int, _code: int, _headers: PackedStringArray, body: PackedByteArray, http: HTTPRequest) -> void:
	http.queue_free()
	if result != HTTPRequest.RESULT_SUCCESS:
		return
	var parsed: Variant = JSON.parse_string(body.get_string_from_utf8())
	if parsed is Array and not (parsed as Array).is_empty():
		character_created.emit(((parsed as Array)[0] as Dictionary).get("id", ""))

func _on_queue_completed(result: int, _code: int, _headers: PackedStringArray, _body: PackedByteArray, http: HTTPRequest) -> void:
	http.queue_free()
	if result == HTTPRequest.RESULT_SUCCESS:
		queued_for_match.emit()

func _on_generic_completed(_result: int, _code: int, _headers: PackedStringArray, _body: PackedByteArray, http: HTTPRequest) -> void:
	http.queue_free()
