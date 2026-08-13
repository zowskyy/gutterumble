extends Node
# Headless InputCommand / InputRouter regression test.
# Builds InputCommand, pulses touch actions, overrides stick, consumes command.
# Fair, transparent PASS/FAIL reporting with optional debug logging.
# Run: godot --headless --path . res://scenes/test/test_input_command.tscn
# usage: automated CI health check for offline input routing.

var _pass_count: int = 0
var _fail_count: int = 0

func _ready() -> void:
	await get_tree().process_frame
	_run_tests()
	print("[InputCommand] PASS=%d FAIL=%d" % [_pass_count, _fail_count])
	get_tree().quit(0 if _fail_count == 0 else 1)

func _run_tests() -> void:
	_test_command_shape()
	_test_touch_pulse_and_move()
	_test_clear_edges()

func _test_command_shape() -> void:
	var cmd := InputCommand.new()
	if cmd == null:
		_record_fail("InputCommand.new() returned null")
		return
	if cmd.sequence != 0:
		_record_fail("default sequence should be 0")
		return
	if cmd.move != Vector2.ZERO:
		_record_fail("default move should be ZERO")
		return
	if cmd.light or cmd.heavy or cmd.dodge or cmd.special:
		_record_fail("default edges should be false")
		return
	_pass_count += 1
	print("[InputCommand] PASS: command shape")

func _test_touch_pulse_and_move() -> void:
	if InputRouter == null:
		_record_fail("InputRouter autoload missing")
		return
	InputRouter.clear_touch_move()
	InputRouter.set_touch_move(Vector2(0.5, -0.25))
	InputRouter.pulse_touch_action("light")
	InputRouter.pulse_touch_action("dodge")
	InputRouter.pulse_touch_action("special")
	var cmd: InputCommand = InputRouter.consume_command()
	if cmd == null:
		_record_fail("consume_command returned null")
		return
	if cmd.sequence < 1:
		_record_fail("sequence should increment")
		return
	if not cmd.light:
		_record_fail("expected light pulse")
		return
	if not cmd.dodge:
		_record_fail("expected dodge pulse")
		return
	if not cmd.special:
		_record_fail("expected special pulse")
		return
	if cmd.heavy:
		_record_fail("heavy should be false")
		return
	if absf(cmd.move.x - 0.5) > 0.001 or absf(cmd.move.y - (-0.25)) > 0.001:
		_record_fail("touch move not applied")
		return
	# Second consume same process frame should return cached edges (not cleared twice).
	var again: InputCommand = InputRouter.consume_command()
	if again.sequence != cmd.sequence:
		_record_fail("same-frame consume should reuse sequence")
		return
	if not again.light:
		_record_fail("cached command lost light edge")
		return
	InputRouter.clear_touch_move()
	_pass_count += 1
	print("[InputCommand] PASS: touch pulse + move consume")

func _test_clear_edges() -> void:
	var cmd := InputCommand.new()
	cmd.light = true
	cmd.heavy = true
	cmd.dodge = true
	cmd.special = true
	cmd.interact = true
	cmd.revive = true
	cmd.pause = true
	cmd.clear_edges()
	if cmd.light or cmd.heavy or cmd.dodge or cmd.special or cmd.interact or cmd.revive or cmd.pause:
		_record_fail("clear_edges left an edge true")
		return
	_pass_count += 1
	print("[InputCommand] PASS: clear_edges")

func _record_fail(reason: String) -> void:
	if reason.is_empty():
		return  # error: reject empty failure reason
	_fail_count += 1
	printerr("[InputCommand] FAIL: %s" % reason)

func get_test_diagnostic() -> String:
	# log.info snapshot for test-run transparency
	return "pass=%d fail=%d" % [_pass_count, _fail_count]
