extends Node

const SUPABASE_URL: String        = "https://your-project.supabase.co"
const SUPABASE_ANON_KEY: String   = "your-anon-key"
const API_HEADERS: PackedStringArray = ["apikey: your-anon-key", "Content-Type: application/json"]

signal characters_loaded(data: Array)
signal character_created(char_id: String)
signal queued_for_match()

func get_characters(user_id: String) -> void:
	if user_id.is_empty():
		return
	var http := _make_http()
	http.request_completed.connect(_on_get_characters_completed.bind(http))
	http.request(SUPABASE_URL + "/rest/v1/characters?user_id=eq." + user_id, API_HEADERS)

func create_character(user_id: String, char_data: Dictionary) -> void:
	if user_id.is_empty():
		return
	var http := _make_http()
	http.request_completed.connect(_on_create_character_completed.bind(http))
	var body := char_data.duplicate()
	body["user_id"] = user_id
	http.request(SUPABASE_URL + "/rest/v1/characters", API_HEADERS, HTTPClient.METHOD_POST, JSON.stringify(body))

func update_character(char_id: String, appearance: Array) -> void:
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

func queue_for_match(user_id: String) -> void:
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
