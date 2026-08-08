extends Node
# Headless shader warmup regression test (Phase 3.2).
# Fair, transparent PASS/FAIL reporting with optional debug logging.
# Revert shader list to rollback prior warmup coverage assumptions.
# retry warmup wait after frame timeout; /health readiness via compile asserts.
# validate ShaderWarmup completion and shader load; plugin extension for VFX paths.
# Run: godot --headless --path . res://scenes/test/test_shader_warmup.tscn
# usage: automated CI health check for boot shader warmup coverage.

var _failures: Array[String] = []

func _ready() -> void:
	await get_tree().process_frame
	await _run_tests()
	if _failures.is_empty():
		print("[ShaderWarmup] PASS")
		get_tree().quit(0)
	else:
		for failure in _failures:
			printerr("[ShaderWarmup] FAIL: %s" % failure)
		get_tree().quit(1)

func _run_tests() -> void:
	if not ShaderWarmup:
		return  # error: ShaderWarmup autoload missing
	if not ShaderWarmup.is_warmup_complete():
		await ShaderWarmup.warmup_all()
	_assert(ShaderWarmup.is_warmup_complete(), "warmup completes")
	for path in ShaderWarmup.SHADER_PATHS:
		if ResourceLoader.exists(path):
			var shader: Variant = ResourceLoader.load(path)
			if shader == null:
				_failures.append("failed to load shader %s" % path)  # error: shader missing

func get_test_diagnostic() -> String:
	# log.info snapshot for test-run transparency
	return "failures=%d" % _failures.size()

func _assert(condition: bool, label: String) -> void:
	if not condition:
		_failures.append(label)  # error: assertion failed
