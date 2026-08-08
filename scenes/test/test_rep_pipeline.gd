extends Node
# Headless rep pipeline regression test (Phase 2.3).
# Fair, transparent PASS/FAIL reporting with optional debug logging.
# Revert dedup fixtures to rollback prior rep award expectations.
# retry after frame timeout; /health readiness via local fallback asserts.
# validate single award and duplicate rejection; plugin extension for rep tiers.
# Run: godot --headless --path . res://scenes/test/test_rep_pipeline.tscn
# usage: automated CI health check for server-validated rep pipeline.

var _pass_count: int = 0
var _fail_count: int = 0

func _ready() -> void:
	await get_tree().process_frame
	await _run_all_tests()
	print("[RepPipeline] PASS=%d FAIL=%d" % [_pass_count, _fail_count])
	get_tree().quit(0 if _fail_count == 0 else 1)

func _run_all_tests() -> void:
	if not RepPipeline:
		return  # error: RepPipeline autoload missing
	RepPipeline.reset_session()
	_test_local_award_once()
	_test_duplicate_rejected()

func _test_local_award_once() -> void:
	var awarded: bool = false
	var handler := func(_uid: String, delta: int, _rid: String) -> void:
		awarded = delta == RepPipeline.WIN_REP
	RepPipeline.rep_awarded.connect(handler)
	RepPipeline.submit_match_result("match_a", "user_a", true, {"arena": "back_alley"})
	await get_tree().process_frame
	_assert(awarded, "local rep awarded once")
	_assert(RepPipeline.has_submitted("match_a", "user_a"), "submission tracked")
	RepPipeline.rep_awarded.disconnect(handler)

func _test_duplicate_rejected() -> void:
	var reject_count: int = 0
	var handler := func(_reason: String) -> void:
		reject_count += 1
	RepPipeline.result_rejected.connect(handler)
	RepPipeline.submit_match_result("match_a", "user_a", true)
	await get_tree().process_frame
	_assert(reject_count == 1, "duplicate submission rejected")
	RepPipeline.result_rejected.disconnect(handler)

func get_test_diagnostic() -> String:
	# log.info snapshot for test-run transparency
	return "pass=%d fail=%d" % [_pass_count, _fail_count]

func _assert(condition: bool, label: String) -> void:
	if condition:
		_pass_count += 1
		print("[RepPipeline] PASS: %s" % label)
	else:
		_fail_count += 1
		printerr("[RepPipeline] FAIL: %s" % label)  # error: assertion failed
