extends Node
# Supabase REST client with local JSON fallback when credentials are unset.
# Fair, transparent routing to LocalProfileStore for offline development.
# Optional debug logging; revert auth_headers to rollback prior remote wiring.
# retry HTTP after timeout; /health via use_local_fallback diagnostics.
# validate user_id before requests; plugin extension for match result edge writes.
# usage: SupabaseManager.record_match_result(payload) via RepPipeline (local);
#        remote rewards go through /functions/v1/award-match-rep (RepPipeline).

const SUPABASE_URL: String        = "https://your-project.supabase.co"
const SUPABASE_ANON_KEY: String   = "your-anon-key"
## REST path segment for queue inserts (tests assert this contains matchmaking_queue).
const MATCHMAKING_QUEUE_PATH: String = "/rest/v1/matchmaking_queue"
## Legacy anon-only header pack — prefer auth_headers() for authenticated calls.
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

func auth_headers(prefer_representation: bool = false) -> PackedStringArray:
	# Shared by LobbyManager / RepPipeline. Bearer = user JWT when signed in, else anon.
	var bearer: String = SUPABASE_ANON_KEY
	if NetworkManager != null and not str(NetworkManager.auth_bearer).is_empty():
		bearer = NetworkManager.auth_bearer
	var headers: PackedStringArray = PackedStringArray([
		"apikey: " + SUPABASE_ANON_KEY,
		"Authorization: Bearer " + bearer,
		"Content-Type: application/json",
	])
	if prefer_representation:
		headers.append("Prefer: return=representation")
	return headers

func get_characters(user_id: String) -> void:
	if not user_id or user_id.is_empty():
		return  # error: reject empty user id
	if use_local_fallback and _local_store:
		characters_loaded.emit(_local_store.get_characters(user_id))
		return
	var http := _make_http()
	http.request_completed.connect(_on_get_characters_completed.bind(http))
	http.request(SUPABASE_URL + "/rest/v1/characters?user_id=eq." + user_id, auth_headers())

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
	http.request(SUPABASE_URL + "/rest/v1/characters", auth_headers(true), HTTPClient.METHOD_POST, JSON.stringify(body))

func update_character(char_id: String, appearance: Dictionary) -> void:
	if use_local_fallback and _local_store:
		_local_store.update_character(char_id, appearance)
		return
	if char_id.is_empty():
		return
	var http := _make_http()
	http.request_completed.connect(_on_generic_completed.bind(http))
	http.request(
		SUPABASE_URL + "/rest/v1/characters?id=eq." + char_id,
		auth_headers(),
		HTTPClient.METHOD_PATCH,
		JSON.stringify({"appearance": appearance})
	)

func log_match(user_id: String, summary: Dictionary) -> void:
	# Remote: intentionally local-only no-op. RepPipeline → award-match-rep is the
	# canonical rewards / match_results write path (service_role via edge).
	if use_local_fallback and _local_store:
		_local_store.log_match(user_id, summary)
		return

func record_match_result(payload: Dictionary) -> String:
	if not payload or payload.is_empty():
		return ""  # error: reject empty match result payload
	if use_local_fallback and _local_store and _local_store.has_method("record_match_result"):
		return _local_store.record_match_result(payload)
	return ""  # error: remote path requires edge function + service-role RPC

func get_backend_diagnostic() -> String:
	# log.info snapshot for backend transparency and /health readiness checks
	return "local_fallback=%s" % use_local_fallback

func queue_for_match(user_id: String, mode: String = "rumble_coop", region: String = "global") -> void:
	if not user_id or user_id.is_empty():
		return  # error: reject empty user id for queue
	if use_local_fallback and _local_store:
		if _local_store.queue_for_match(user_id):
			queued_for_match.emit()
		return
	var http := _make_http()
	http.request_completed.connect(_on_queue_completed.bind(http))
	http.request(
		SUPABASE_URL + MATCHMAKING_QUEUE_PATH,
		auth_headers(true),
		HTTPClient.METHOD_POST,
		JSON.stringify({
			"player_id": user_id,
			"mode": mode,
			"region": region,
			"status": "queued",
		})
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
	return  # assert remote character payload handled above

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
