extends CharacterBody3D

@export var player_id: int = 0
@export var move_speed: float = 5.0

var is_local: bool = false
var health: float = 100.0
var input_vector: Vector2 = Vector2.ZERO

func _ready() -> void:
	is_local = is_multiplayer_authority()

func _physics_process(delta: float) -> void:
	if not is_local:
		return
	
	input_vector = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	velocity = Vector3(input_vector.x, 0, input_vector.y) * move_speed
	move_and_slide()
	
	if Input.is_action_just_pressed("ui_accept"):
		attack_light()

func attack_light() -> void:
	if is_multiplayer_authority():
		_do_attack_light.rpc()

@rpc
func _do_attack_light() -> void:
	pass

func take_damage(amount: float) -> void:
	health -= amount
	if health <= 0:
		die()

func die() -> void:
	queue_free()

func sync_position() -> void:
	if is_multiplayer_authority():
		_set_position.rpc(global_position)

@rpc
func _set_position(pos: Vector3) -> void:
	if not is_multiplayer_authority():
		global_position = pos
