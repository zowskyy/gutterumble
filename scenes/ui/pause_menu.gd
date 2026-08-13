extends CanvasLayer
# Pause menu — ESC / pause_menu / Start toggles pause. Sits on layer 20 (above HUD on 10).

signal resumed
signal quit_to_menu

var _toggle_frame: int = -1

func _ready() -> void:
	visible = false
	layer   = 20
	var resume_btn: Button = get_node_or_null("Panel/ResumeButton") as Button
	var quit_btn: Button = get_node_or_null("Panel/QuitButton") as Button
	if resume_btn:
		resume_btn.pressed.connect(_on_resume)
	if quit_btn:
		quit_btn.pressed.connect(_on_quit)

func _unhandled_input(event: InputEvent) -> void:
	# is_action_just_pressed() is an Input-singleton POLLING method (for use
	# in _process/_physics_process) — it doesn't exist on InputEvent itself.
	# is_action_pressed() on the event is the correct per-event "just
	# pressed" check here.
	var should_toggle := false
	if event.is_action_pressed("ui_cancel"):
		should_toggle = true
	elif event.is_action_pressed("pause_menu"):
		should_toggle = true
	elif event is InputEventJoypadButton:
		var jb := event as InputEventJoypadButton
		if jb.pressed and jb.button_index == JOY_BUTTON_START:
			should_toggle = true
	if not should_toggle:
		return
	_toggle_pause()
	get_viewport().set_input_as_handled()

func _process(_delta: float) -> void:
	# Touch pause (and pause_menu InputMap) surface on InputCommand.pause.
	# Existing ui_cancel path stays in _unhandled_input. Debounced per frame.
	if InputRouter == null:
		return
	var cmd: InputCommand = InputRouter.consume_command()
	if cmd != null and cmd.pause:
		_toggle_pause()

func _toggle_pause() -> void:
	var frame: int = Engine.get_process_frames()
	if _toggle_frame == frame:
		return
	_toggle_frame = frame
	if visible:
		_on_resume()
	else:
		_pause()

func _pause() -> void:
	get_tree().paused = true
	visible           = true
	Engine.time_scale = 1.0   # override any hit-stop that was mid-frame

func _on_resume() -> void:
	get_tree().paused = false
	visible           = false
	resumed.emit()

func _on_quit() -> void:
	get_tree().paused = false
	Engine.time_scale = 1.0
	quit_to_menu.emit()
	GameManager.go_to_main_menu()
