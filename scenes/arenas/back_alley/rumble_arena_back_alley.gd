extends Node3D
# Back Alley arena — Phase 1 match manager.
# Spawns one player (fighter.tscn) and one AI opponent (mouse_enemy.tscn),
# runs a 3-second countdown, then starts the fight.

enum MatchState { SETUP, COUNTDOWN, FIGHTING, ENDED }

signal match_ended(player_won: bool)

const PLAYER_SCENE := preload("res://scenes/player/fighter.tscn")
const ENEMY_SCENE  := preload("res://scenes/enemies/mouse_enemy.tscn")

const COUNTDOWN_SECS := 3.0

var match_state: MatchState = MatchState.SETUP
var _player: Node3D         = null
var _enemy: Node3D          = null
var _countdown: float       = COUNTDOWN_SECS

@onready var _player_spawn: Node3D        = $SpawnPoints/PlayerSpawn
@onready var _enemy_spawn: Node3D         = $SpawnPoints/EnemySpawn
@onready var _player_health_bar: ProgressBar = $HUD/HUDRoot/PlayerHealthBar
@onready var _enemy_health_bar: ProgressBar  = $HUD/HUDRoot/EnemyHealthBar
@onready var _countdown_label: Label         = $HUD/HUDRoot/CountdownLabel
@onready var _result_label: Label            = $HUD/HUDRoot/RoundResultLabel

func _ready() -> void:
	_spawn_fighters()
	match_state = MatchState.COUNTDOWN

func _process(delta: float) -> void:
	if match_state != MatchState.COUNTDOWN:
		return
	_countdown -= delta
	if _countdown > 0.0:
		_countdown_label.text = str(ceili(_countdown))
	else:
		_start_fight()

func _spawn_fighters() -> void:
	_player = PLAYER_SCENE.instantiate()
	add_child(_player)
	_player.global_position = _player_spawn.global_position
	_player.died.connect(_on_player_died)
	_player.health_changed.connect(_on_player_health_changed)
	_player.set_physics_process(false)

	_enemy = ENEMY_SCENE.instantiate()
	add_child(_enemy)
	_enemy.global_position = _enemy_spawn.global_position
	_enemy.died.connect(_on_enemy_died)
	_enemy.health_changed.connect(_on_enemy_health_changed)
	_enemy.set_target(_player)
	_enemy.set_physics_process(false)

	var gap := _enemy_spawn.global_position - _player_spawn.global_position
	_player.rotation.y = atan2(gap.x, gap.z)
	_enemy.rotation.y  = atan2(-gap.x, -gap.z)

	if _player_health_bar:
		_player_health_bar.max_value = _player.max_health
		_player_health_bar.value     = _player.max_health
	if _enemy_health_bar:
		_enemy_health_bar.max_value = _enemy.max_health
		_enemy_health_bar.value     = _enemy.max_health

func _start_fight() -> void:
	if match_state == MatchState.FIGHTING:
		return
	match_state = MatchState.FIGHTING
	_countdown_label.text = "FIGHT!"
	get_tree().create_timer(0.5).timeout.connect(func() -> void:
		if is_instance_valid(_countdown_label):
			_countdown_label.visible = false
	)
	if is_instance_valid(_player):
		_player.set_physics_process(true)
	if is_instance_valid(_enemy):
		_enemy.set_physics_process(true)

func _on_player_health_changed(new_hp: float, _max_hp: float) -> void:
	if _player_health_bar:
		_player_health_bar.value = new_hp

func _on_enemy_health_changed(new_hp: float, _max_hp: float) -> void:
	if _enemy_health_bar:
		_enemy_health_bar.value = new_hp

func _on_player_died() -> void:
	if match_state != MatchState.FIGHTING:
		return
	match_state = MatchState.ENDED
	match_ended.emit(false)
	_show_result(false)

func _on_enemy_died() -> void:
	if match_state != MatchState.FIGHTING:
		return
	match_state = MatchState.ENDED
	match_ended.emit(true)
	_show_result(true)

func _show_result(player_won: bool) -> void:
	if _result_label:
		_result_label.text    = "YOU WIN!" if player_won else "YOU LOSE!"
		_result_label.visible = true
	await get_tree().create_timer(2.5).timeout
	GameManager.go_to_main_menu()

func get_spawn_point(gang_index: int, _player_index: int) -> Vector3:
	if gang_index == 0:
		return _player_spawn.global_position
	return _enemy_spawn.global_position
