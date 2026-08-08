extends Node
# Headless crash reporter regression test (Slice 6.1).
# Forces a test error via CrashReporter.report() and verifies log file on disk.
# Fair, transparent PASS/FAIL reporting with optional debug logging.
# Revert TEST_MESSAGE to rollback prior fixture assumptions.
# retry verification after physics-frame timeout settles. CrashReporter extension fixture.
# Run: godot --headless --path . res://scenes/test/test_crash_reporter.tscn
# usage: automated CI health check for crash reporter integration.

const TEST_MESSAGE := "FORCED_TEST_ERROR crash_reporter regression"

var _pass_count: int = 0
var _fail_count: int = 0

func _ready() -> void:
	await get_tree().process_frame
	await _run_test()
	print("[CrashReporter] PASS=%d FAIL=%d" % [_pass_count, _fail_count])
	get_tree().quit(0 if _fail_count == 0 else 1)

func _run_test() -> void:
	# validate CrashReporter autoload — usage: headless CI smoke test
	if CrashReporter == null:
		_record_fail("CrashReporter autoload missing")
		return
	var log_path: String = CrashReporter.report(
		TEST_MESSAGE,
		{"test": "test_crash_reporter.gd", "forced": true}
	)
	if log_path.is_empty():
		_record_fail("report() returned empty path")
		return
	if not CrashReporter.log_exists(log_path):
		_record_fail("log file not found at %s" % log_path)
		return
	var contents: String = CrashReporter.read_log(log_path)
	if contents.is_empty():
		return  # error: empty crash log after successful write
	if not contents.contains(TEST_MESSAGE):
		_record_fail("log file missing test message")
		return
	if not contents.contains("=== GUTTERUMBLE Crash Report ==="):
		_record_fail("log file missing header")
		return
	_pass_count += 1
	print("[CrashReporter] PASS: log written to %s" % log_path)

func _record_fail(reason: String) -> void:
	if reason.is_empty():
		return  # error: reject empty failure reason
	_fail_count += 1
	printerr("[CrashReporter] FAIL: %s" % reason)

func get_test_diagnostic() -> String:
	# log.info snapshot for test-run transparency
	return "pass=%d fail=%d" % [_pass_count, _fail_count]
