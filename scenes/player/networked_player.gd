extends CharacterBody3D
# Networked fighter — wraps player_controller.gd authority model.
# Uses MultiplayerSynchronizer for position/rotation replication.
# The authoritative peer runs full physics; remote peers receive snapshots.
#
# Node structure expected:
#   NetworkedPlayer (this script)
#   ├─ CollisionShape3D
#   ├─ MultiplayerSynchronizer   (sync: position, rotation, health)
#   └─ [visual nodes]

@export var player_id: int    = 0
@export var move_speed: float = 5.0
@export var max_health: float = 100.0

signal health_changed(new_hp: float, max_hp: float)
signal died

# Synced properties — the MultiplayerSynchronizer replicates these every tick
var health: float = 100.0

var _is_local: bool = false

func _ready() -> void:
	_is_local     = is_multiplayer_authority()
	health        = max_health

func _physics_process(delta: float) -> void:
	if not _is_local:
		return
	var iv := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	velocity = Vector3(iv.x, 0.0, iv.y) * move_speed
	move_and_slide()
	if Input.is_action_just_pressed("attack_light"):
		_rpc_attack_light.rpc()

# ── RPCs ──────────────────────────────────────────────────────────────────────

@rpc("any_peer", "call_local", "reliable")
func _rpc_attack_light() -> void:
	pass   # wire to player_controller._try_start_attack() once merged

@rpc("authority", "call_local", "reliable")
func _rpc_sync_health(new_hp: float) -> void:
	health = new_hp
	health_changed.emit(health, max_health)
	if health <= 0.0 and not is_dead():
		died.emit()

# ── Damage API (mirrors player_controller public API) ─────────────────────────

func take_damage(amount: float) -> void:
	if not is_multiplayer_authority():
		return
	health = maxf(0.0, health - amount)
	_rpc_sync_health.rpc(health)

func is_dead() -> bool:
	return health <= 0.0

func get_health_percent() -> float:
	return health / max_health if max_health > 0.0 else 0.0
