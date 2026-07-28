extends CanvasLayer
# CombatHUD — Warriors-mode HUD.
# Tracks: player health, enemy health, round timer, kill count, current combo.
# Connect via arena script after spawning fighters.

signal time_up
signal round_complete(player_won: bool)

@export var round_time: float = 90.0

@onready var _player_hp_bar: ProgressBar = $Root/PlayerHealthBar
@onready var _enemy_hp_bar: ProgressBar  = $Root/EnemyHealthBar
@onready var _timer_label: Label         = $Root/TimerLabel
@onready var _combo_label: Label         = $Root/ComboLabel
@onready var _kill_label: Label          = $Root/KillLabel
@onready var _result_label: Label        = $Root/RoundResultLabel
@onready var _countdown_label: Label     = $Root/CountdownLabel

var _time_remaining: float = 0.0
var _running: bool         = false
var _kill_count: int       = 0
var _combo_count: int      = 0
var _combo_reset_timer: float = 0.0

const COMBO_RESET_SECS := 1.8

func _ready() -> void:
	_time_remaining = round_time
	_result_label.visible = false
	_combo_label.visible  = false

func start_timer() -> void:
	_running = true

func stop_timer() -> void:
	_running = false

func _process(delta: float) -> void:
	if _running:
		_time_remaining = maxf(0.0, _time_remaining - delta)
		var secs := int(_time_remaining)
		_timer_label.text = "%02d:%02d" % [secs / 60, secs % 60]
		if _timer_label:
			_timer_label.modulate = Color.RED if _time_remaining <= 10.0 else Color.WHITE
		if _time_remaining <= 0.0:
			_running = false
			time_up.emit()

	# Combo decay
	if _combo_count > 0:
		_combo_reset_timer -= delta
		if _combo_reset_timer <= 0.0:
			_combo_count = 0
			_combo_label.visible = false

# ── Public API ────────────────────────────────────────────────────────────────

func set_player_health(hp: float, max_hp: float) -> void:
	if _player_hp_bar:
		_player_hp_bar.max_value = max_hp
		_player_hp_bar.value     = hp

func set_enemy_health(hp: float, max_hp: float) -> void:
	if _enemy_hp_bar:
		_enemy_hp_bar.max_value = max_hp
		_enemy_hp_bar.value     = hp

func register_kill() -> void:
	_kill_count += 1
	_kill_label.text = "KO  %d" % _kill_count
	register_hit()   # killing blow also registers as a combo hit

func register_hit() -> void:
	_combo_count        += 1
	_combo_reset_timer   = COMBO_RESET_SECS
	if _combo_count >= 2:
		_combo_label.visible = true
		_combo_label.text    = "%d HIT COMBO!" % _combo_count

func show_countdown(text: String) -> void:
	if _countdown_label:
		_countdown_label.text    = text
		_countdown_label.visible = true

func hide_countdown() -> void:
	if _countdown_label:
		_countdown_label.visible = false

func show_result(player_won: bool) -> void:
	if _result_label:
		_result_label.text    = "YOU WIN!" if player_won else "YOU LOSE!"
		_result_label.visible = true
