extends Node
# Autoload: PerfLogger
# Logs FPS, draw calls, and physics steps to user://perf_log.csv every N seconds.
# Check the log after playtests to catch regressions before they ship.
# Toggle via PerfLogger.enabled = false to disable in release builds.

var enabled: bool        = true
var interval: float      = 2.0   # seconds between log entries
var _timer: float        = 0.0
var _file: FileAccess    = null
var _session_start: int  = 0

func _ready() -> void:
	if not enabled:
		return
	_session_start = Time.get_ticks_msec()
	_file = FileAccess.open("user://perf_log.csv", FileAccess.WRITE)
	if _file == null:
		push_error("PerfLogger: cannot open user://perf_log.csv")
		return
	_file.store_line("session_time_ms,fps,draw_calls,active_objects,physics_steps")

func _process(delta: float) -> void:
	if not enabled or _file == null:
		return
	_timer += delta
	if _timer < interval:
		return
	_timer = 0.0
	_write_row()

func _write_row() -> void:
	var session_ms  := Time.get_ticks_msec() - _session_start
	var fps         := Engine.get_frames_per_second()
	var draw_calls  := Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
	var active_obj  := Performance.get_monitor(Performance.OBJECT_COUNT)
	var phys_steps  := Performance.get_monitor(Performance.PHYSICS_3D_ACTIVE_OBJECTS)
	_file.store_line("%d,%.1f,%d,%d,%d" % [session_ms, fps, draw_calls, active_obj, phys_steps])

func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE and _file != null:
		_file.close()

func get_log_path() -> String:
	return ProjectSettings.globalize_path("user://perf_log.csv")
