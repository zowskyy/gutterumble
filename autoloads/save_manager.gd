extends Node
# Autoload: SaveManager
# Persists player appearance and settings via ConfigFile (user://save.cfg).

const SAVE_PATH := "user://save.cfg"

var _cfg := ConfigFile.new()

func _ready() -> void:
	_cfg.load(SAVE_PATH)   # silently no-ops if file doesn't exist yet

# ── Appearance ────────────────────────────────────────────────────────────────

func save_appearance(data: Dictionary) -> void:
	for key in data:
		_cfg.set_value("appearance", key, data[key])
	_cfg.save(SAVE_PATH)

func load_appearance() -> Dictionary:
	var out: Dictionary = {}
	if not _cfg.has_section("appearance"):
		return out
	for key in _cfg.get_section_keys("appearance"):
		out[key] = _cfg.get_value("appearance", key)
	return out

# ── Settings ──────────────────────────────────────────────────────────────────

func save_setting(key: String, value: Variant) -> void:
	_cfg.set_value("settings", key, value)
	_cfg.save(SAVE_PATH)

func load_setting(key: String, default: Variant = null) -> Variant:
	return _cfg.get_value("settings", key, default)

# ── Stats (local only — wins / losses) ───────────────────────────────────────

func increment_stat(key: String) -> void:
	var current: int = _cfg.get_value("stats", key, 0)
	_cfg.set_value("stats", key, current + 1)
	_cfg.save(SAVE_PATH)

func get_stat(key: String) -> int:
	return _cfg.get_value("stats", key, 0)
