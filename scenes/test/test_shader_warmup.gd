extends Node
# Headless shader warmup regression test (Phase 3.2).
# Run: godot --headless --path . res://scenes/test/test_shader_warmup.tscn

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
	if not ShaderWarmup.is_warmup_complete():
		await ShaderWarmup.warmup_all()
	_assert(ShaderWarmup.is_warmup_complete(), "warmup completes")
	for path in ShaderWarmup.SHADER_PATHS:
		if ResourceLoader.exists(path):
			var shader: Variant = ResourceLoader.load(path)
			if shader == null:
				_failures.append("failed to load shader %s" % path)

func _assert(condition: bool, label: String) -> void:
	if not condition:
		_failures.append(label)
