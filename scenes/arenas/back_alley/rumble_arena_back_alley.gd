extends Node3D
# Back Alley arena — complete match manager.
# Reads warriors_mode from SaveManager so main menu drives the mode.
# Supports: 1v1 classic | Warriors multi-wave | pause | rematch | dynamic camera | round pips

enum MatchState { SETUP, COUNTDOWN, FIGHTING, ROUND_END, ENDED }

signal match_ended(player_won: bool)

const PLAYER_SCENE := preload("res://scenes/player/fighter.tscn")
const ENEMY_SCENE  := preload("res://scenes/enemies/mouse_enemy.tscn")
const PAUSE_SCENE  := preload("res://scenes/ui/pause_menu.tscn")

const COUNTDOWN_SECS := 3.0
const ROUND_END_WAIT := 2.5   # seconds before next round or menu

@export var waves: Array = [
	{"team": 1, "count": 1},
	{"team": 1, "count": 2},
	{"team": 1, "count": 3},
]

var warriors_mode: bool       = false
var match_state: MatchState   = MatchState.SETUP
var _countdown: float         = COUNTDOWN_SECS
var _player: Node3D           = null
var _enemy: Node3D            = null
var _pause_menu: CanvasLayer  = null

# ── Node refs ─────────────────────────────────────────────────────────────────
@onready var _player_spawn: Node3D   = $SpawnPoints/PlayerSpawn
@onready var _enemy_spawn: Node3D    = $SpawnPoints/EnemySpawn
@onready var _camera: Camera3D       = $Camera3D
@onready var _hud_player_hp: ProgressBar = $HUD/HUDRoot/PlayerHealthBar
@onready var _hud_enemy_hp: ProgressBar  = $HUD/HUDRoot/EnemyHealthBar
@onready var _hud_countdown: Label       = $HUD/HUDRoot/CountdownLabel
@onready var _hud_result: Label          = $HUD/HUDRoot/RoundResultLabel
@onready var _hud_rounds: Label          = $HUD/HUDRoot/RoundsLabel

# ── Boot ──────────────────────────────────────────────────────────────────────

func _ready() -> void:
	warriors_mode = SaveManager.load_setting("warriors_mode", false)

	# Swap camera to dynamic script
	var cam_script := load("res://scenes/arenas/back_alley/arena_camera.gd")
	_camera.set_script(cam_script)

	# Pause menu
	_pause_menu = PAUSE_SCENE.instantiate()
	add_child(_pause_menu)
	_pause_menu.quit_to_menu.connect(func() -> void: GameManager.go_to_main_menu())

	# Pre-warm pool
	FighterPool.preload_scene(PLAYER_SCENE.resource_path, self)
	FighterPool.preload_scene(ENEMY_SCENE.resource_path, self)

	# GangSpawner
	var all_points: Array = []
	for child in $SpawnPoints.get_children():
		all_points.append(child)
	GangSpawner.configure(self, all_points, [1, int(waves[0].get("count", 1))], waves)
	GangSpawner.wave_cleared.connect(_on_wave_cleared)
	GangSpawner.all_waves_cleared.connect(_on_all_waves_cleared)

	# RoundManager
	RoundManager.reset()
	RoundManager.round_over.connect(_on_round_over)
	RoundManager.match_over.connect(_on_match_over)

	AudioManager.play_music("arena_theme")
	_refresh_round_pips()

	if warriors_mode:
		_spawn_warriors_mode()
	else:
		_spawn_classic_mode()

	match_state = MatchState.COUNTDOWN

# ── Classic 1v1 ───────────────────────────────────────────────────────────────

func _spawn_classic_mode() -> void:
	_player = FighterPool.pull(PLAYER_SCENE.resource_path, _player_spawn.global_transform)
	if _player == null:
		return
	_player.set_physics_process(false)
	_player.died.connect(_on_player_died)
	_player.health_changed.connect(_on_player_health_changed)

	_enemy = FighterPool.pull(ENEMY_SCENE.resource_path, _enemy_spawn.global_transform)
	if _enemy == null:
		return
	_enemy.set_physics_process(false)
	if _enemy.has_method("set_target"):
		_enemy.set_target(_player)
	_enemy.died.connect(_on_enemy_died)
	_enemy.health_changed.connect(_on_enemy_health_changed)

	# Face each other
	var gap := _enemy_spawn.global_position - _player_spawn.global_position
	_player.rotation.y = atan2(gap.x, gap.z)
	_enemy.rotation.y  = atan2(-gap.x, -gap.z)

	_sync_hp_bars()

	# Dynamic camera targets
	_camera.call_deferred("set_targets", _player, _enemy)

# ── Warriors mode ─────────────────────────────────────────────────────────────

func _spawn_warriors_mode() -> void:
	_player = GangSpawner.spawn_player(_player_spawn)
	if _player == null:
		return
	_player.set_physics_process(false)
	_player.died.connect(_on_player_died)
	_player.health_changed.connect(_on_player_health_changed)
	GangSpawner.spawn_wave()
	_camera.call_deferred("set_targets", _player, _player)   # will update when enemies spawn

# ── Countdown ─────────────────────────────────────────────────────────────────

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
	AudioManager.play_sfx("fight_start")
	RoundManager.start_round()
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

# ── Health sync ───────────────────────────────────────────────────────────────

func _sync_hp_bars() -> void:
	if _hud_player_hp and _player:
		_hud_player_hp.max_value = _player.max_health
		_hud_player_hp.value     = _player.max_health
	if _hud_enemy_hp and _enemy:
		_hud_enemy_hp.max_value = _enemy.max_health
		_hud_enemy_hp.value     = _enemy.max_health

func _on_player_health_changed(new_hp: float, max_hp: float) -> void:
	if _hud_player_hp:
		_hud_player_hp.max_value = max_hp
		_hud_player_hp.value     = new_hp

func _on_enemy_health_changed(new_hp: float, max_hp: float) -> void:
	if _hud_enemy_hp:
		_hud_enemy_hp.max_value = max_hp
		_hud_enemy_hp.value     = new_hp

# ── Round / match outcome ─────────────────────────────────────────────────────

func _on_player_died() -> void:
	if match_state != MatchState.FIGHTING:
		return
	match_state = MatchState.ROUND_END
	SaveManager.increment_stat("losses")
	RoundManager.record_win(false)

func _on_enemy_died() -> void:
	if match_state != MatchState.FIGHTING:
		return
	match_state = MatchState.ROUND_END
	RoundManager.record_win(true)

func _on_round_over(player_won: bool, player_score: int, enemy_score: int) -> void:
	_refresh_round_pips()
	if _hud_result:
		var round_txt := "Round %d  %d – %d" % [RoundManager.current_round - 1, player_score, enemy_score]
		_hud_result.text    = ("WIN!" if player_won else "LOSE!") + "\n" + round_txt
		_hud_result.visible = true

func _on_match_over(player_won: bool) -> void:
	if player_won:
		SaveManager.increment_stat("wins")
	match_ended.emit(player_won)
	_show_final_result(player_won)

func _on_wave_cleared(wave_index: int) -> void:
	if match_state != MatchState.FIGHTING:
		return
	if wave_index + 1 < waves.size():
		get_tree().create_timer(1.5).timeout.connect(func() -> void:
			GangSpawner.spawn_wave()
		)

func _on_all_waves_cleared() -> void:
	if match_state != MatchState.FIGHTING:
		return
	match_state = MatchState.ROUND_END
	RoundManager.record_win(true)

func _show_final_result(player_won: bool) -> void:
	if _hud_result:
		_hud_result.text    = "YOU WIN!" if player_won else "YOU LOSE!"
		_hud_result.visible = true
	await get_tree().create_timer(ROUND_END_WAIT).timeout
	_cleanup()
	GameManager.go_to_main_menu()

func _cleanup() -> void:
	GangSpawner.return_all()
	FighterPool.return_all(PLAYER_SCENE.resource_path)
	FighterPool.return_all(ENEMY_SCENE.resource_path)
	Engine.time_scale = 1.0

# ── Round pip display ─────────────────────────────────────────────────────────

func _refresh_round_pips() -> void:
	if not _hud_rounds:
		return
	var player_pips := ""
	var enemy_pips  := ""
	for i in range(RoundManager.ROUNDS_TO_WIN):
		player_pips += ("●" if i < RoundManager.player_wins else "○") + " "
		enemy_pips  += ("●" if i < RoundManager.enemy_wins  else "○") + " "
	_hud_rounds.text = player_pips.strip_edges() + "   vs   " + enemy_pips.strip_edges()

# ── Public helper for GangSpawner queries ─────────────────────────────────────

func get_spawn_point(gang_index: int, _player_index: int) -> Vector3:
	if gang_index == 0:
		return _player_spawn.global_position
	return _enemy_spawn.global_position
