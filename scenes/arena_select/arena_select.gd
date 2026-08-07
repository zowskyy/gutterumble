extends Control
# Arena select — pick a 1v1 arena before fighting.

@onready var _back_alley_btn: Button = $ButtonContainer/BackAlleyButton
@onready var _rooftop_btn: Button    = $ButtonContainer/RooftopButton
@onready var _back_btn: Button       = $ButtonContainer/BackButton

func _ready() -> void:
	if _back_alley_btn:
		_back_alley_btn.pressed.connect(_on_back_alley)
	if _rooftop_btn:
		_rooftop_btn.pressed.connect(_on_rooftop)
	if _back_btn:
		_back_btn.pressed.connect(_on_back)

func _on_back_alley() -> void:
	AudioManager.play_sfx("ui_confirm")
	SaveManager.save_setting("warriors_mode", false)
	SaveManager.save_setting("selected_arena", "back_alley")
	GameManager.go_to_rumble_arena_back_alley()

func _on_rooftop() -> void:
	AudioManager.play_sfx("ui_confirm")
	SaveManager.save_setting("warriors_mode", false)
	SaveManager.save_setting("selected_arena", "rooftop")
	GameManager.go_to_rumble_arena_rooftop()

func _on_back() -> void:
	AudioManager.play_sfx("ui_back")
	GameManager.go_to_main_menu()
