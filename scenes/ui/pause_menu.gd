extends CanvasLayer
# Pause menu — ESC toggles pause. Sits on layer 20 (above HUD on 10).

signal resumed
signal quit_to_menu

func _ready() -> void:
	visible = false
	layer   = 20

func _unhandled_input(event: InputEvent) -> void:
	# is_action_just_pressed() is an Input-singleton POLLING method (for use
	# in _process/_physics_process) — it doesn't exist on InputEvent itself.
	# is_action_pressed() on the event is the correct per-event "just
	# pressed" check here.
	if event.is_action_pressed("ui_cancel"):
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
