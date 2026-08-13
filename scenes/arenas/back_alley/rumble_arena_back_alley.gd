extends Node3D
# Back Alley arena — complete match manager.
# Reads warriors_mode from SaveManager so main menu drives the mode.
# Supports: 1v1 classic | Warriors multi-wave | pause | rematch | dynamic camera | round pips

enum MatchState { SETUP, COUNTDOWN, FIGHTING, ROUND_END, ENDED }

signal match_ended(player_won: bool)

const PLAYER_SCENE := preload("res://scenes/player/sprite_fighter.tscn")
const ENEMY_SCENE  := preload("res://scenes/enemies/sprite_enemy.tscn")
const PAUSE_SCENE  := preload("res://scenes/ui/pause_menu.tscn")
const TOUCH_SCENE  := preload("res://scenes/ui/touch_controls.tscn")

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
@onready var _hud_combo: Label           = $HUD/HUDRoot/ComboLabel
@onready var _hud_special: ProgressBar   = $HUD/HUDRoot/SpecialGaugeBar
@onready var _hud_enemies_left: Label    = $HUD/HUDRoot/EnemiesRemainingLabel
@onready var _hud_wave: Label            = $HUD/HUDRoot/WaveLabel

const COMBO_RESET_SECS := 1.8
var _combo_count: int        = 0
var _combo_timer: float      = 0.0
var _combo_tween: Tween      = null
var _combo_milestone: int    = 0    # highest flavor tier already announced this streak
var _last_player_hp: float   = -1.0

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

	var _touch := TOUCH_SCENE.instantiate()
	add_child(_touch)

	# Pre-warm pool
	FighterPool.preload_scene(PLAYER_SCENE.resource_path, self)
	FighterPool.preload_scene(ENEMY_SCENE.resource_path, self)

	# GangSpawner
	_configure_gang_spawner()
	GangSpawner.wave_cleared.connect(_on_wave_cleared)
	GangSpawner.all_waves_cleared.connect(_on_all_waves_cleared)

	# RoundManager
	RoundManager.reset()
	RoundManager.round_over.connect(_on_round_over)
	RoundManager.match_over.connect(_on_match_over)

	# SpecialMeter — fresh match starts empty; persists across rounds after that
	SpecialMeter.reset()
	SpecialMeter.charge_changed.connect(_on_special_charge_changed)

	AudioManager.play_music("arena_theme")
	_refresh_round_pips()

	if warriors_mode:
		_spawn_warriors_mode()
	else:
		_spawn_classic_mode()

	match_state = MatchState.COUNTDOWN

# ── Classic 1v1 ───────────────────────────────────────────────────────────────

func _spawn_classic_mode() -> void:
	if _hud_enemy_hp: _hud_enemy_hp.visible = true
	if _hud_enemies_left: _hud_enemies_left.visible = false
	if _hud_wave: _hud_wave.visible = false

	_player = FighterPool.pull(PLAYER_SCENE.resource_path, _player_spawn.global_transform)
	if _player == null:
		return
	_player.set_physics_process(false)
	_connect_player(_player)

	_enemy = FighterPool.pull(ENEMY_SCENE.resource_path, _enemy_spawn.global_transform)
	if _enemy == null:
		return
	_enemy.set_physics_process(false)
	if _enemy.has_method("set_target"):
		_enemy.set_target(_player)
	_connect_enemy(_enemy)

	# Align both spawns onto the shared fight lane (XZ side-view).
	var lane_z: float = (_player_spawn.global_position.z + _enemy_spawn.global_position.z) * 0.5
	if _player.has_method("set_lane"):
		_player.set_lane(lane_z, _enemy)
	if _enemy.has_method("set_lane"):
		_enemy.set_lane(lane_z, _player)
	# Face along X: player on left faces right; enemy on right faces left.
	# set_lane already applied facing from opponent X; reinforce for spawn order.
	if "facing_right" in _player:
		_player.facing_right = true
	if "facing_right" in _enemy:
		_enemy.facing_right = false
	if _player.has_method("_apply_lane_facing"):
		_player._apply_lane_facing()
	if _enemy.has_method("_apply_lane_facing"):
		_enemy._apply_lane_facing()

	_sync_hp_bars()
	_last_player_hp = _player.max_health

	# Dynamic camera targets
	_camera.call_deferred("set_targets", _player, _enemy)

# ── Warriors mode ─────────────────────────────────────────────────────────────

func _configure_gang_spawner() -> void:
	# GangSpawner.configure() resets its internal _wave_index to 0 — must be
	# called again on every round restart, not just once in _ready(), or a
	# second round in Warriors mode silently spawns zero enemies (the wave
	# index would already be exhausted from the previous round's clear).
	var all_points: Array = []
	for child in $SpawnPoints.get_children():
		all_points.append(child)
	GangSpawner.configure(self, all_points, [1, int(waves[0].get("count", 1))], waves)

func _spawn_warriors_mode() -> void:
	if _hud_enemy_hp: _hud_enemy_hp.visible = false
	if _hud_enemies_left: _hud_enemies_left.visible = true
	if _hud_wave: _hud_wave.visible = true

	# Use whatever gang color the player actually picked in the character
	# creator instead of GangSpawner's hardcoded default blue — this was a
	# dead-end before: the color picker had zero effect on gameplay.
	var player_color: Color = GangSpawner.TEAM_COLORS[0]
	var saved_color: String = SaveManager.load_appearance().get("gang_color", "")
	if not saved_color.is_empty():
		player_color = Color.html(saved_color)

	_player = GangSpawner.spawn_player(_player_spawn, player_color)
	if _player == null:
		return
	_player.set_physics_process(false)
	_connect_player(_player)
	_last_player_hp = _player.max_health
	GangSpawner.spawn_wave()
	var lane_z: float = _player_spawn.global_position.z
	var first_enemy: Node3D = null
	for child in get_children():
		if child == _player:
			continue
		if child.has_method("set_lane") and child.has_method("set_target"):
			if first_enemy == null:
				first_enemy = child
			child.set_lane(lane_z, _player)
	if _player.has_method("set_lane"):
		_player.set_lane(lane_z, first_enemy)
	_camera.call_deferred("set_targets", _player, first_enemy if first_enemy else _player)

# ── Signal wiring (guarded — pooled instances are reused, connecting twice
#    without a guard would fire every callback multiple times per event) ──────

func _connect_player(p: Node3D) -> void:
	if not p.died.is_connected(_on_player_died):
		p.died.connect(_on_player_died)
	if not p.health_changed.is_connected(_on_player_health_changed):
		p.health_changed.connect(_on_player_health_changed)
	if p.has_signal("hit_landed") and not p.hit_landed.is_connected(_on_player_hit_landed):
		p.hit_landed.connect(_on_player_hit_landed)

func _connect_enemy(e: Node3D) -> void:
	if not e.died.is_connected(_on_enemy_died):
		e.died.connect(_on_enemy_died)
	if not e.health_changed.is_connected(_on_enemy_health_changed):
		e.health_changed.connect(_on_enemy_health_changed)

# ── Countdown ─────────────────────────────────────────────────────────────────

func _process(delta: float) -> void:
	if match_state == MatchState.COUNTDOWN:
		_countdown -= delta
		if _countdown > 0.0:
			if _hud_countdown:
				_hud_countdown.text = str(ceili(_countdown))
		else:
			_start_fight()

	if _combo_count > 0:
		_combo_timer -= delta
		if _combo_timer <= 0.0:
			_break_combo()

	# Enemies-remaining / wave counters — polled rather than event-driven since
	# GangSpawner only signals wave_cleared/all_waves_cleared, not per-kill;
	# a cheap once-a-frame label update isn't worth adding new plumbing for.
	if warriors_mode and match_state == MatchState.FIGHTING:
		if _hud_enemies_left:
			_hud_enemies_left.text = "ENEMIES: %d" % GangSpawner.active_enemy_count()
		if _hud_wave:
			_hud_wave.text = "WAVE %d / %d" % [GangSpawner.current_wave_number(), GangSpawner.total_wave_count()]

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
	# Getting hit breaks the streak — a fresh respawn's reset_for_respawn()
	# also emits health_changed at full HP, which never reads as a drop.
	if _last_player_hp >= 0.0 and new_hp < _last_player_hp:
		_break_combo()
	_last_player_hp = new_hp

func _on_enemy_health_changed(new_hp: float, max_hp: float) -> void:
	if _hud_enemy_hp:
		_hud_enemy_hp.max_value = max_hp
		_hud_enemy_hp.value     = new_hp

func _on_special_charge_changed(value: float, max_value: float) -> void:
	if _hud_special:
		_hud_special.max_value = max_value
		_hud_special.value     = value

# ── "Gutter Streak" — persistent combo, unique to this game ──────────────────
# Most brawlers wipe your combo the instant a round ends. Here it survives
# every round transition and wave clear — it only breaks if YOU get tagged,
# or if you go quiet for COMBO_RESET_SECS. Escalating flavor text ties back
# to the game's own tagline ("Every gutter has a king"): rack up enough hits
# across an entire match and you earn the title, not just a number.

func _on_player_hit_landed(_target: Node3D, _attack_id: String, _damage: float) -> void:
	_combo_count += 1
	_combo_timer  = COMBO_RESET_SECS
	if _combo_count < 2 or not _hud_combo:
		return

	_hud_combo.text     = _combo_text(_combo_count)
	_hud_combo.visible  = true
	_hud_combo.modulate = _combo_color(_combo_count)
	_maybe_announce_milestone(_combo_count)

	if _combo_tween and _combo_tween.is_valid():
		_combo_tween.kill()
	_hud_combo.scale = Vector2(1.35, 1.35)
	_combo_tween = create_tween()
	_combo_tween.tween_property(_hud_combo, "scale", Vector2.ONE, 0.18) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _combo_text(count: int) -> String:
	if count >= 15:
		return "%d HIT — GUTTER KING!" % count
	if count >= 10:
		return "%d HIT — RAMPAGE!" % count
	if count >= 6:
		return "%d HIT — ON A TEAR!" % count
	return "%d HIT COMBO!" % count

func _combo_color(count: int) -> Color:
	if count >= 15:
		return Color(0.85, 0.55, 1.0)   # violet-gold — the "king" tier
	if count >= 10:
		return Color(1.0, 0.25, 0.2)    # red — rampage
	if count >= 6:
		return Color(1.0, 0.75, 0.1)    # gold — on a tear
	return Color(1.0, 1.0, 1.0)          # white — starting out

func _maybe_announce_milestone(count: int) -> void:
	var tier := 0
	if count >= 15: tier = 3
	elif count >= 10: tier = 2
	elif count >= 6: tier = 1
	if tier > _combo_milestone:
		_combo_milestone = tier
		AudioManager.play_sfx("combo_milestone")

func _break_combo() -> void:
	_combo_count     = 0
	_combo_timer     = 0.0
	_combo_milestone = 0
	if _hud_combo:
		_hud_combo.visible = false

# ── Round / match outcome ─────────────────────────────────────────────────────

func _on_player_died() -> void:
	if match_state != MatchState.FIGHTING:
		return
	match_state = MatchState.ROUND_END
	SaveManager.increment_stat("losses")
	_play_finisher_beat()
	RoundManager.record_win(false)

func _on_enemy_died() -> void:
	if match_state != MatchState.FIGHTING:
		return
	match_state = MatchState.ROUND_END
	_play_finisher_beat()
	RoundManager.record_win(true)

# ── Finisher cinematic ────────────────────────────────────────────────────────
# Always focuses the camera on _player, win or lose — Warriors-mode wave
# clears don't surface which specific enemy delivered the last blow to the
# arena (GangSpawner only bubbles up wave_cleared/all_waves_cleared, not
# individual deaths), so tracking a "killer" reference here would need
# deeper plumbing than this beat is worth. Focusing the protagonist works
# for both outcomes and needs no mode-specific branching.
func _play_finisher_beat() -> void:
	if not is_instance_valid(_player):
		return
	if CombatFeel._was_paused:
		await CombatFeel.hit_stop_ended
	CombatFeel.finisher_slowmo()
	if _camera and _camera.has_method("zoom_in_on"):
		_camera.zoom_in_on(_player, CombatFeel.FINISHER_SLOWMO_DURATION)

func _on_round_over(player_won: bool, player_score: int, enemy_score: int) -> void:
	_refresh_round_pips()
	# Combo deliberately NOT reset here — it's a running "Gutter Streak" that
	# survives round transitions (see _break_combo for the only ways it ends).
	if _hud_result:
		var round_txt := "Round %d  %d – %d" % [RoundManager.current_round - 1, player_score, enemy_score]
		_hud_result.text    = ("WIN!" if player_won else "LOSE!") + "\n" + round_txt
		_hud_result.visible = true

	await get_tree().create_timer(ROUND_END_WAIT).timeout
	if match_state == MatchState.ENDED:
		return   # _on_match_over already fired and owns cleanup/scene change
	_start_next_round()

func _on_match_over(player_won: bool) -> void:
	match_state = MatchState.ENDED   # set synchronously so _on_round_over's
									  # delayed check (above) reads it correctly
	if player_won:
		SaveManager.increment_stat("wins")
	match_ended.emit(player_won)
	_show_final_result(player_won)

func _start_next_round() -> void:
	if _hud_result:
		_hud_result.visible = false
	if _hud_countdown:
		_hud_countdown.visible = true
	_countdown   = COUNTDOWN_SECS
	match_state  = MatchState.SETUP

	if warriors_mode:
		GangSpawner.return_all()
		_configure_gang_spawner()
		_spawn_warriors_mode()
	else:
		if is_instance_valid(_player):
			FighterPool.push(PLAYER_SCENE.resource_path, _player)
		if is_instance_valid(_enemy):
			FighterPool.push(ENEMY_SCENE.resource_path, _enemy)
		_spawn_classic_mode()

	match_state = MatchState.COUNTDOWN

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
	_play_finisher_beat()
	RoundManager.record_win(true)

func _show_final_result(player_won: bool) -> void:
	if _hud_result:
		_hud_result.text    = "YOU WIN!" if player_won else "YOU LOSE!"
		_hud_result.visible = true
	var arena_name := "rooftop" if SaveManager.load_setting("selected_arena", "back_alley") == "rooftop" else "back_alley"
	SupabaseManager.log_match("local_player", {
		"arena": arena_name,
		"warriors_mode": warriors_mode,
		"player_won": player_won,
		"player_wins": RoundManager.player_wins,
		"enemy_wins": RoundManager.enemy_wins,
	})
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
