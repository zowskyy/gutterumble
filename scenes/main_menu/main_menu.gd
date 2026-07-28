extends Control

@onready var _rumble_btn: Button   = $ButtonContainer/RumbleButton
@onready var _warriors_btn: Button = $ButtonContainer/WarriorsButton
@onready var _customize_btn: Button = $ButtonContainer/CustomizeButton
@onready var _quit_btn: Button     = $ButtonContainer/QuitButton
@onready var _stats_label: Label   = $StatsLabel

func _ready() -> void:
	AudioManager.play_music("menu_theme")
	_update_stats()

	if _rumble_btn:
		_rumble_btn.pressed.connect(_on_rumble)
	if _warriors_btn:
		_warriors_btn.pressed.connect(_on_warriors)
	if _customize_btn:
		_customize_btn.pressed.connect(_on_customize)
	if _quit_btn:
		_quit_btn.pressed.connect(_on_quit)

func _update_stats() -> void:
	if not _stats_label:
		return
	var w := SaveManager.get_stat("wins")
	var l := SaveManager.get_stat("losses")
	_stats_label.text = "W %d  |  L %d" % [w, l]

func _on_rumble() -> void:
	AudioManager.play_sfx("ui_confirm")
	SaveManager.save_setting("warriors_mode", false)
	GameManager.go_to_rumble_arena_back_alley()

func _on_warriors() -> void:
	AudioManager.play_sfx("ui_confirm")
	SaveManager.save_setting("warriors_mode", true)
	GameManager.go_to_rumble_arena_back_alley()

func _on_customize() -> void:
	AudioManager.play_sfx("ui_confirm")
	GameManager.go_to_character_creator()

func _on_quit() -> void:
	AudioManager.play_sfx("ui_back")
	GameManager.quit_game()
