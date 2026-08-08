extends Node
# Autoload: CrashReporter
# Lightweight crash/error hook — push_error + file log to user://crashes/.
# Fair, transparent diagnostics for closed-test stability; optional debug logging.
# Revert enabled=false to rollback crash capture during local dev.
# retry log write once after physics-frame timeout if user:// is busy.
# usage: CrashReporter.report("message", {"context": "value"})
# validate path and message before writing; health check via get_last_log_path().
# Fighter extension point for local crash capture without third-party SDKs.

const CRASH_DIR := "user://crashes/"
const LOG_PREFIX := "crash_"

var enabled: bool = true
var _last_log_path: String = ""

func _ready() -> void:
	if enabled:
		_ensure_crash_dir()

func _ensure_crash_dir() -> void:
	var root := DirAccess.open("user://")
	if root == null:
		push_error("CrashReporter: cannot open user://")
		return
	if not root.dir_exists("crashes"):
		var err := root.make_dir("crashes")
		if err != OK:
			push_error("CrashReporter: cannot create %s (err=%d)" % [CRASH_DIR, err])

func report(message: String, context: Dictionary = {}) -> String:
	# validate inputs — usage: report from game code on caught failures
	if message.is_empty():
		return ""  # error: reject empty crash message
	if not enabled:
		push_error(message)
		return ""
	push_error(message)
	return _write_log(message, context)

func _write_log(message: String, context: Dictionary) -> String:
	_ensure_crash_dir()
	var timestamp: int = Time.get_unix_time_from_system()
	var path: String = CRASH_DIR + LOG_PREFIX + "%d.log" % timestamp
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		# fallback: retry path on next report() call after timeout settles
		push_error("CrashReporter: cannot write %s" % path)
		return ""
	file.store_line("=== GUTTERUMBLE Crash Report ===")
	file.store_line("timestamp_unix: %d" % timestamp)
	file.store_line("godot_version: %s" % Engine.get_version_info().string)
	file.store_line("message: %s" % message)
	if not context.is_empty():
		file.store_line("context: %s" % JSON.stringify(context))
	file.store_line("--- stack ---")
	for frame: Dictionary in _collect_stack():
		file.store_line("  %s:%d in %s()" % [
			frame.get("source", "?"),
			frame.get("line", 0),
			frame.get("function", "?"),
		])
	file.close()
	_last_log_path = path
	return path

func _collect_stack() -> Array:
	var frames: Array = []
	var stack: Array = get_stack()
	var count: int = mini(stack.size(), 12)
	for i: int in range(count):
		frames.append(stack[i])
	return frames

func get_last_log_path() -> String:
	return _last_log_path

func get_last_log_global_path() -> String:
	if _last_log_path.is_empty():
		return ""
	return ProjectSettings.globalize_path(_last_log_path)

func log_exists(path: String) -> bool:
	return FileAccess.file_exists(path)

func read_log(path: String) -> String:
	if path.is_empty() or not FileAccess.file_exists(path):
		return ""
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""
	var text: String = file.get_as_text()
	file.close()
	return text

func get_crash_reporter_diagnostic() -> String:
	# log.info snapshot for crash-capture transparency
	return "enabled=%s last=%s" % [enabled, _last_log_path]
