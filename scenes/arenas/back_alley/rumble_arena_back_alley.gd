extends Node3D
# Back Alley arena — Warriors-mode match manager.
# Phase 1:  1 player vs 1 AI (classic brawler)
# Phase 2+: player gang vs enemy waves (Warriors-style)
# Coordinates FighterPool, GangSpawner, PerfLogger, and CombatHUD.

enum MatchState { SETUP, COUNTDOWN, FIGHTING, ENDED }

signal match_ended(player_won: bool)

const PLAYER_SCENE := preload("res://scenes/player/fighter.tscn")
const ENEMY_SCENE  := preload("res://scenes/enemies/mouse_enemy.tscn")

const COUNTDOWN_SECS := 3.0

# ── Warriors-mode wave config ──────────────────────────────────────────────────
# Each wave: { "team": int, "count": int }
# team 0 = player gang, team 1 = red enemy gang, etc.
@export var waves: Array = [
	{"team": 1, "count": 1},   # wave 1: classic 1v1 to start
	{"team": 1, "count": 2},   # wave 2: 2 enemies
	{"team": 1, "count": 3},   # wave 3: 3 enemies — Warriors density
]
@export var warriors_mode: bool = false   # true = multi-wave; false = classic 1v1

var match_state: MatchState = MatchState.SETUP
var _countdown: float       = COUNTDOWN_SECS
var _player: Node3D         = null
var _enemy: Node3D          = null   # classic mode only

# ── Node refs ─────────────────────────────────────────────────────────────────
@onready var _player_spawn: Node3D = $SpawnPoints/PlayerSpawn
@onready var _enemy_spawn: Node3D  = $SpawnPoints/EnemySpawn

# HUD — use the new CombatHUD if present, else fall back to bare labels
@onready var _hud_player_hp: ProgressBar = $HUD/HUDRoot/PlayerHealthBar
@onready var _hud_enemy_hp: ProgressBar  = $HUD/HUDRoot/EnemyHealthBar
@onready var _hud_countdown: Label       = $HUD/HUDRoot/CountdownLabel
@onready var _hud_result: Label          = $HUD/HUDRoot/RoundResultLabel

func _ready() -> void:
	# Pre-warm the pool for this arena
	FighterPool.preload_scene(PLAYER_SCENE.resource_path, self)
	FighterPool.preload_scene(ENEMY_SCENE.resource_path, self)

	# Collect all spawn points for GangSpawner
	var all_points: Array = []
	for child in $SpawnPoints.get_children():
		all_points.append(child)

	GangSpawner.configure(self, all_points, [1, int(waves[0].get("count", 1))], waves)
	GangSpawner.wave_cleared.connect(_on_wave_cleared)
	GangSpawner.all_waves_cleared.connect(_on_all_waves_cleared)

	if warriors_mode:
		_spawn_warriors_mode()
	else:
		_spawn_classic_mode()

	match_state = MatchState.COUNTDOWN

# ── Classic 1v1 mode ──────────────────────────────────────────────────────────

func _spawn_classic_mode() -> void:
	_player = FighterPool.pull(PLAYER_SCENE.resource_path, _player_spawn.global_transform)
	if _player == null:
		return
	_player.set_physics_process(false)
	if _player.has_signal("died"):
		_player.died.connect(_on_player_died)
	if _player.has_signal("health_changed"):
		_player.health_changed.connect(_on_player_health_changed)

	_enemy = FighterPool.pull(ENEMY_SCENE.resource_path, _enemy_spawn.global_transform)
	if _enemy == null:
		return
	_enemy.set_physics_process(false)
	if _enemy.has_method("set_target"):
		_enemy.set_target(_player)
	if _enemy.has_signal("died"):
		_enemy.died.connect(_on_enemy_died)
	if _enemy.has_signal("health_changed"):
		_enemy.health_changed.connect(_on_enemy_health_changed)

	# Face each other
	var gap := _enemy_spawn.global_position - _player_spawn.global_position
	_player.rotation.y = atan2(gap.x, gap.z)
	_enemy.rotation.y  = atan2(-gap.x, -gap.z)

	if _hud_player_hp:
		_hud_player_hp.max_value = _player.max_health
		_hud_player_hp.value     = _player.max_health
	if _hud_enemy_hp:
		_hud_enemy_hp.max_value = _enemy.max_health
		_hud_enemy_hp.value     = _enemy.max_health

# ── Warriors multi-wave mode ──────────────────────────────────────────────────

func _spawn_warriors_mode() -> void:
	_player = GangSpawner.spawn_player(_player_spawn)
	if _player == null:
		return
	_player.set_physics_process(false)
	if _player.has_signal("died"):
		_player.died.connect(_on_player_died)
	if _player.has_signal("health_changed"):
		_player.health_changed.connect(_on_player_health_changed)
	GangSpawner.spawn_wave()

# ── Countdown / fight start ───────────────────────────────────────────────────

func _process(delta: float) -> void:
	if match_state != MatchState.COUNTDOWN:
		return
	_countdown -= delta
	if _countdown > 0.0:
		if _hud_countdown:
			_hud_countdown.text = str(ceili(_countdown))
	else:
		_start_fight()

func _start_fight() -> void:
	if match_state == MatchState.FIGHTING:
		return
	match_state = MatchState.FIGHTING
	if _hud_countdown:
		_hud_countdown.text = "FIGHT!"
	get_tree().create_timer(0.5).timeout.connect(func() -> void:
		if is_instance_valid(_hud_countdown):
			_hud_countdown.visible = false
	)
	if is_instance_valid(_player):
		_player.set_physics_process(true)
	if is_instance_valid(_enemy):
		_enemy.set_physics_process(true)

# ── Health callbacks ──────────────────────────────────────────────────────────

func _on_player_health_changed(new_hp: float, max_hp: float) -> void:
	if _hud_player_hp:
		_hud_player_hp.max_value = max_hp
		_hud_player_hp.value     = new_hp

func _on_enemy_health_changed(new_hp: float, max_hp: float) -> void:
	if _hud_enemy_hp:
		_hud_enemy_hp.max_value = max_hp
		_hud_enemy_hp.value     = new_hp

# ── Match outcome ─────────────────────────────────────────────────────────────

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

func _on_wave_cleared(wave_index: int) -> void:
	if match_state != MatchState.FIGHTING:
		return
	var next_wave := wave_index + 1
	if next_wave < waves.size():
		# Brief pause then next wave
		get_tree().create_timer(1.5).timeout.connect(func() -> void:
			GangSpawner.spawn_wave()
		)

func _on_all_waves_cleared() -> void:
	if match_state != MatchState.FIGHTING:
		return
	match_state = MatchState.ENDED
	match_ended.emit(true)
	_show_result(true)

func _show_result(player_won: bool) -> void:
	if _hud_result:
		_hud_result.text    = "YOU WIN!" if player_won else "YOU LOSE!"
		_hud_result.visible = true
	await get_tree().create_timer(2.5).timeout
	GangSpawner.return_all()
	FighterPool.return_all(PLAYER_SCENE.resource_path)
	FighterPool.return_all(ENEMY_SCENE.resource_path)
	GameManager.go_to_main_menu()

# ── Debug helper — expose spawn point for external queries ───────────────────

func get_spawn_point(gang_index: int, _player_index: int) -> Vector3:
	if gang_index == 0:
		return _player_spawn.global_position
	return _enemy_spawn.global_position
