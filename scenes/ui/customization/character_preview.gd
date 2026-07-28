extends Node3D

@onready var base_body: Node3D = $BaseBody

func _ready() -> void:
	pass

func load_character(character_data: Dictionary) -> void:
	CustomizationManager.load_character_appearance(character_data)

func rotate_preview(delta: float) -> void:
	base_body.rotate_y(delta)
