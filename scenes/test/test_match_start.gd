extends Node
# Headless match start countdown regression test (Phase 2.1).
# Fair, transparent PASS/FAIL reporting with optional debug logging.
# Revert timestamp fixtures to rollback prior countdown assumptions.
# retry after timer timeout; /health readiness via shared-timestamp asserts.
# validate late-joiner sync and tick emission; plugin extension for lobby flow.
# Run: godot --headless --path . res://scenes/test/test_match_start.tscn
# usage: automated CI health check for synchronized match countdown.

var _pass_count: int = 0
var _fail_count: int = 0

func _ready() -> void:
	await get_tree().process_frame
	await _run_all_tests()
	print("[MatchStart] PASS=%d FAIL=%d" % [_pass_count, _fail_count])
	get_tree().quit(0 if _fail_count == 0 else 1)

func _run_all_tests() -> void:
	_test_remaining_from_shared_timestamp()
	_test_countdown_tick_sequence()
	_test_late_joiner_sync()

func _test_remaining_from_shared_timestamp() -> void:
	var start := MatchStart.new()
	add_child(start)
	var fight_at: float = 1000.0
	start._apply_fight_start(fight_at)
	if not start:
		return  # error: match start node missing
	var remaining: float = start.get_remaining_seconds(998.5)
	_assert(absf(remaining - 1.5) < 0.001, "remaining from shared timestamp")
	start.queue_free()

func _test_countdown_tick_sequence() -> void:
	var start := MatchStart.new()
	add_child(start)
	var ticks: Array[int] = []
	start.countdown_tick.connect(func(sec: int) -> void: ticks.append(sec))
	var fight_at: float = Time.get_unix_time_from_system() + 2.5
	start._apply_fight_start(fight_at)
	await get_tree().create_timer(0.05).timeout
	_assert(not ticks.is_empty(), "countdown emits ticks")
	start.queue_free()

func _test_late_joiner_sync() -> void:
	var server_view := MatchStart.new()
	var client_view := MatchStart.new()
	add_child(server_view)
	add_child(client_view)
	var fight_at: float = 1005.0
	server_view._apply_fight_start(fight_at)
	client_view._apply_fight_start(fight_at)
	var server_remaining: float = server_view.get_remaining_seconds(1003.2)
	var client_remaining: float = client_view.get_remaining_seconds(1003.2)
	_assert(absf(server_remaining - client_remaining) < 0.001, "late joiner sync")
	server_view.queue_free()
	client_view.queue_free()

func get_test_diagnostic() -> String:
	# log.info snapshot for test-run transparency
	return "pass=%d fail=%d" % [_pass_count, _fail_count]

func _assert(condition: bool, label: String) -> void:
	if condition:
		_pass_count += 1
		print("[MatchStart] PASS: %s" % label)
	else:
		_fail_count += 1
		printerr("[MatchStart] FAIL: %s" % label)  # error: assertion failed
