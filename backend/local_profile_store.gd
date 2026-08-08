extends Node
# Local JSON fallback when Supabase credentials are not configured.
# Stores player profiles and match history under user://gutterumble_local/

const STORE_DIR := "user://gutterumble_local"
const CHARACTERS_PATH := STORE_DIR + "/characters.json"
const MATCHES_PATH := STORE_DIR + "/matches.json"
const MATCH_RESULTS_PATH := STORE_DIR + "/match_results.json"

func _ready() -> void:
	_ensure_store()

func _ensure_store() -> void:
	var dir := DirAccess.open("user://")
	if dir and not dir.dir_exists("gutterumble_local"):
		dir.make_dir("gutterumble_local")
	if not FileAccess.file_exists(CHARACTERS_PATH):
		_write_json(CHARACTERS_PATH, [])
	if not FileAccess.file_exists(MATCHES_PATH):
		_write_json(MATCHES_PATH, [])
	if not FileAccess.file_exists(MATCH_RESULTS_PATH):
		_write_json(MATCH_RESULTS_PATH, [])

func _read_json(path: String) -> Variant:
	if not FileAccess.file_exists(path):
		return []
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return []
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	f.close()
	return parsed if parsed != null else []

func _write_json(path: String, data: Variant) -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		return
	f.store_string(JSON.stringify(data, "\t"))
	f.close()

func get_characters(user_id: String) -> Array:
	var all: Array = _read_json(CHARACTERS_PATH)
	if user_id.is_empty():
		return all
	var out: Array = []
	for row in all:
		if row is Dictionary and row.get("user_id", "") == user_id:
			out.append(row)
	return out

func create_character(user_id: String, char_data: Dictionary) -> String:
	var all: Array = _read_json(CHARACTERS_PATH)
	var row := char_data.duplicate()
	row["user_id"] = user_id
	row["id"] = "local_%d" % Time.get_ticks_msec()
	row["created_at"] = Time.get_datetime_string_from_system()
	all.append(row)
	_write_json(CHARACTERS_PATH, all)
	return row["id"]

func update_character(char_id: String, appearance: Array) -> void:
	var all: Array = _read_json(CHARACTERS_PATH)
	for i in all.size():
		if all[i] is Dictionary and all[i].get("id", "") == char_id:
			all[i]["appearance"] = appearance
			_write_json(CHARACTERS_PATH, all)
			return

func log_match(user_id: String, summary: Dictionary) -> void:
	var all: Array = _read_json(MATCHES_PATH)
	var row := summary.duplicate()
	row["user_id"] = user_id
	row["logged_at"] = Time.get_datetime_string_from_system()
	all.append(row)
	_write_json(MATCHES_PATH, all)

func queue_for_match(user_id: String) -> bool:
	# Local mode: instant "queued" — no remote matchmaking server.
	return not user_id.is_empty()

func record_match_result(payload: Dictionary) -> String:
	var match_id: String = str(payload.get("match_id", ""))
	var user_id: String = str(payload.get("user_id", ""))
	if match_id.is_empty() or user_id.is_empty():
		return ""

	var all: Array = _read_json(MATCH_RESULTS_PATH)
	for row in all:
		if row is Dictionary and row.get("match_id", "") == match_id and row.get("user_id", "") == user_id:
			return str(row.get("id", ""))

	var result_id: String = "local_result_%d" % Time.get_ticks_msec()
	var row := payload.duplicate()
	row["id"] = result_id
	row["logged_at"] = Time.get_datetime_string_from_system()
	all.append(row)
	_write_json(MATCH_RESULTS_PATH, all)

	var char_id: String = str(payload.get("character_id", ""))
	var rep_delta: int = int(payload.get("rep_delta", 0))
	if not char_id.is_empty() and rep_delta != 0:
		_award_rep_local(char_id, user_id, rep_delta)

	log_match(user_id, {
		"match_id": match_id,
		"won": payload.get("won", false),
		"rep_delta": rep_delta,
		"summary": payload.get("summary", {}),
	})
	return result_id

func _award_rep_local(char_id: String, user_id: String, rep_delta: int) -> void:
	var all: Array = _read_json(CHARACTERS_PATH)
	for i in all.size():
		if all[i] is Dictionary and all[i].get("id", "") == char_id and all[i].get("user_id", "") == user_id:
			all[i]["rep"] = int(all[i].get("rep", 0)) + rep_delta
			_write_json(CHARACTERS_PATH, all)
			return
