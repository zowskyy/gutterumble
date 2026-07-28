extends Control

@onready var rumble_button: Button = $ButtonContainer/RumbleButton
@onready var customize_button: Button = $ButtonContainer/CustomizeButton
@onready var crew_button: Button = $ButtonContainer/CrewButton

func _ready() -> void:
	if rumble_button == null or customize_button == null or crew_button == null:
		return
	rumble_button.pressed.connect(_on_rumble_pressed)
	customize_button.pressed.connect(_on_customize_pressed)
	crew_button.pressed.connect(_on_crew_pressed)

func _on_rumble_pressed() -> void:
	GameManager.go_to_rumble_arena_back_alley()

func _on_customize_pressed() -> void:
	GameManager.go_to_character_creator()

func _on_crew_pressed() -> void:
	pass
