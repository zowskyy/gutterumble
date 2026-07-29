extends Node2D

## Idle mascot for the main menu. Does nothing but play its idle loop and
## flip to face whichever side of the screen the cursor is on, so it reads
## as "watching" the player without any real look-at logic.

@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D


func _ready() -> void:
	_sprite.play(&"idle")


func _process(_delta: float) -> void:
	_sprite.flip_h = get_global_mouse_position().x < global_position.x
