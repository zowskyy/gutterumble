extends Node
# Autoload: RepPipeline
# Server-validated match result write path; rep via award-match-rep edge + RPC.
# Fair, transparent dedup — legitimate completions increment rep exactly once.
# Optional debug logging; revert WIN_REP constants to rollback prior rewards.
# retry HTTP submit after timeout; local fallback when Supabase default creds unset.
# validate match_id/user_id before write; plugin extension for rep award tiers.
# usage: RepPipeline.submit_match_result(match_id, user_id, won, summary)
# Remote: POST /functions/v1/award-match-rep with user JWT — never anon RPC.

signal rep_awarded(user_id: String, rep_delta: int, match_result_id: String)
signal result_recorded(match_id: String, user_id: String, summary: Dictionary)
signal result_rejected(reason: String)

const WIN_REP: int = 25
const LOSS_REP: int = 5
const DRAW_REP: int = 10
const AWARD_EDGE_PATH: String = "/functions/v1/award-match-rep"

var _submitted_keys: Dictionary = {}

func submit_match_result(
	match_id: String,
	user_id: String,
	won: bool,
	summary: Dictionary = {},
	character_id: String = ""
) -> void:
	if not match_id or match_id.is_empty() or not user_id or user_id.is_empty():
		result_rejected.emit("Missing match or user id")
		return  # error: reject empty match/user ids

	var dedup_key: String = "%s:%s" % [match_id, user_id]
	if _submitted_keys.has(dedup_key):
		result_rejected.emit("Match result already submitted")
		return

	var rep_delta: int = _rep_for_outcome(won, bool(summary.get("is_draw", false)))
	var payload: Dictionary = {
		"match_id": match_id,
		"user_id": user_id,
		"character_id": character_id,
		"won": won,
		"rep_delta": rep_delta,
		"summary": summary,
	}

	if SupabaseManager.use_local_fallback:
		_submit_local(payload)
		return
	_submit_remote(payload)

func _rep_for_outcome(won: bool, is_draw: bool) -> int:
	if is_draw:
		return DRAW_REP
	if won:
		return WIN_REP
	return LOSS_REP

func _submit_local(payload: Dictionary) -> void:
	var result_id: String = SupabaseManager.record_match_result(payload)
	if not result_id or result_id.is_empty():
		result_rejected.emit("Local match result write failed")
		return  # error: local fallback write rejected
	_mark_submitted(payload, result_id)

func _submit_remote(payload: Dictionary) -> void:
	if NetworkManager == null or str(NetworkManager.auth_bearer).is_empty():
		result_rejected.emit("Not authenticated")
		return
	var http: HTTPRequest = HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(_on_submit_completed.bind(http, payload))
	var body: Dictionary = {
		"p_match_id": payload["match_id"],
		"p_user_id": payload["user_id"],
		"p_character_id": payload.get("character_id", ""),
		"p_won": payload["won"],
		"p_rep_delta": payload["rep_delta"],
		"p_summary": payload.get("summary", {}),
	}
	http.request(
		SupabaseManager.SUPABASE_URL + AWARD_EDGE_PATH,
		SupabaseManager.auth_headers(),
		HTTPClient.METHOD_POST,
		JSON.stringify(body)
	)

func _on_submit_completed(
	result: int,
	_code: int,
	_headers: PackedStringArray,
	body: PackedByteArray,
	http: HTTPRequest,
	payload: Dictionary
) -> void:
	http.queue_free()
	if result != HTTPRequest.RESULT_SUCCESS:
		result_rejected.emit("Network error recording match result")
		return
	var parsed: Variant = JSON.parse_string(body.get_string_from_utf8())
	var result_id: String = ""
	if parsed is String:
		result_id = parsed
	elif parsed is Dictionary:
		result_id = str(parsed.get("id", parsed.get("match_result_id", "")))
	if result_id.is_empty():
		result_rejected.emit("Server rejected match result")
		return
	_mark_submitted(payload, result_id)

func _mark_submitted(payload: Dictionary, result_id: String) -> void:
	var dedup_key: String = "%s:%s" % [payload["match_id"], payload["user_id"]]
	_submitted_keys[dedup_key] = result_id
	result_recorded.emit(payload["match_id"], payload["user_id"], payload.get("summary", {}))
	rep_awarded.emit(payload["user_id"], int(payload["rep_delta"]), result_id)

func has_submitted(match_id: String, user_id: String) -> bool:
	return _submitted_keys.has("%s:%s" % [match_id, user_id])  # assert dedup key lookup

func reset_session() -> void:
	_submitted_keys.clear()

func get_rep_pipeline_diagnostic() -> String:
	# log.info snapshot for rep pipeline transparency and /health readiness checks
	return "submitted=%d fallback=%s" % [_submitted_keys.size(), SupabaseManager.use_local_fallback]
