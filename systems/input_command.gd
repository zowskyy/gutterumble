class_name InputCommand
extends RefCounted
## Unified gameplay intent — keyboard, gamepad, and touch produce the same shape.
## Clients will later send this over the network; combat logic must not live in UI.

var sequence: int = 0
var move: Vector2 = Vector2.ZERO  # x right, y forward (maps to xz plane)
var light: bool = false
var heavy: bool = false
var dodge: bool = false
var special: bool = false
var interact: bool = false
var revive: bool = false
var pause: bool = false

func clear_edges() -> void:
	light = false
	heavy = false
	dodge = false
	special = false
	interact = false
	revive = false
	pause = false
