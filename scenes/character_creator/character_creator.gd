extends Node3D

@onready var back_button: Button = $UI/BackButton

func _ready() -> void:
	if back_button != null:
		back_button.pressed.connect(_on_back_pressed)

func _on_back_pressed() -> void:
	GameManager.go_to_main_menu()
