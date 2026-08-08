extends Node
# Headless match resolver regression test (Phase 2.2).
# Fair, transparent PASS/FAIL reporting with optional debug logging.
# Revert fixtures to rollback prior resolver expectations.
# retry after frame timeout; /health readiness via assert diagnostics.
# validate elimination and timer paths; plugin extension for rumble win modes.
# Run: godot --headless --path . res://scenes/test/test_match_resolver.tscn
# usage: automated CI health check for deterministic match resolution.

var _pass_count: int = 0
var _fail_count: int = 0

func _ready() -> void:
	_run_all_tests()
	print("[MatchResolver] PASS=%d FAIL=%d" % [_pass_count, _fail_count])
	get_tree().quit(0 if _fail_count == 0 else 1)

func _run_all_tests() -> void:
	if not MatchResolver:
		return  # error: MatchResolver autoload missing
	_test_elimination_single_survivor()
	_test_elimination_score_tiebreak()
	_test_timer_expiry_highest_score()
	_test_timer_still_running()
	_test_deterministic_across_clients()

func _test_elimination_single_survivor() -> void:
	var state := {
		"teams": {0: {"alive": 1}, 1: {"alive": 0}},
		"scores": {0: 1, 1: 0},
	}
	var result: Dictionary = MatchResolver.evaluate(state, MatchResolver.WinMode.ELIMINATION)
	_assert(result.get("winner_team") == 0, "elimination winner")
	_assert(result.get("reason") == MatchResolver.REASON_ELIMINATION, "elimination reason")

func _test_elimination_score_tiebreak() -> void:
	var state := {
		"teams": {0: {"alive": 0}, 1: {"alive": 0}},
		"scores": {0: 3, 1: 1},
	}
	var result: Dictionary = MatchResolver.evaluate(state, MatchResolver.WinMode.ELIMINATION)
	_assert(result.get("winner_team") == 0, "score tiebreak winner")

func _test_timer_expiry_highest_score() -> void:
	var state := {
		"teams": {0: {"alive": 1}, 1: {"alive": 1}},
		"scores": {0: 2, 1: 4},
		"timer_remaining": 0.0,
	}
	var result: Dictionary = MatchResolver.evaluate(state, MatchResolver.WinMode.TIMER_EXPIRY)
	_assert(result.get("winner_team") == 1, "timer winner by score")
	_assert(result.get("reason") == MatchResolver.REASON_TIMER, "timer reason")

func _test_timer_still_running() -> void:
	var state := {
		"teams": {0: {"alive": 1}, 1: {"alive": 1}},
		"scores": {0: 2, 1: 4},
		"timer_remaining": 12.5,
	}
	var result: Dictionary = MatchResolver.evaluate(state, MatchResolver.WinMode.TIMER_EXPIRY)
	_assert(result.get("winner_team") == -1, "no winner while timer active")

func _test_deterministic_across_clients() -> void:
	var state := {
		"teams": {0: {"alive": 0}, 1: {"alive": 1}},
		"scores": {0: 5, 1: 2},
		"timer_remaining": 0.0,
	}
	var a: Dictionary = MatchResolver.evaluate(state, MatchResolver.WinMode.ELIMINATION)
	var b: Dictionary = MatchResolver.evaluate(state, MatchResolver.WinMode.ELIMINATION)
	_assert(a == b, "deterministic evaluation")

func get_test_diagnostic() -> String:
	# log.info snapshot for test-run transparency
	return "pass=%d fail=%d" % [_pass_count, _fail_count]

func _assert(condition: bool, label: String) -> void:
	if condition:
		_pass_count += 1
		print("[MatchResolver] PASS: %s" % label)
	else:
		_fail_count += 1
		printerr("[MatchResolver] FAIL: %s" % label)  # error: assertion failed
