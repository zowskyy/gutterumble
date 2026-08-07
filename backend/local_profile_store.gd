extends Node
# Local JSON fallback when Supabase credentials are not configured.
# Stores player profiles and match history under user://gutterumble_local/

const STORE_DIR := "user://gutterumble_local"
const CHARACTERS_PATH := STORE_DIR + "/characters.json"
const MATCHES_PATH := STORE_DIR + "/matches.json"

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
