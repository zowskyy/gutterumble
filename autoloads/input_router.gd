extends Node
## Autoload: InputRouter
## Polls keyboard/gamepad InputMap and merges one-frame touch pulses into InputCommand.
## Touch UI must call pulse_touch_action only — never combat APIs (no take_damage, etc.).
## Same-physics-frame consume_command() calls share one cached command so pause UI and
## the player controller can both read without double-clearing edges.

const _TOUCH_ACTION_KEYS: Array[String] = [
	"light", "heavy", "dodge", "special", "interact", "revive", "pause",
]

var _sequence: int = 0
var _touch_move: Vector2 = Vector2.ZERO
var _touch_move_active: bool = false
var _touch_pulses: Dictionary = {}  # String -> bool

var _cached_cmd: InputCommand = null
var _cached_process_frame: int = -1

func _ready() -> void:
	# Survive tree pause so touch pause/resume edges still route through consume_command.
	process_mode = Node.PROCESS_MODE_ALWAYS

func set_touch_move(v: Vector2) -> void:
	_touch_move = v
	_touch_move_active = true

func clear_touch_move() -> void:
	_touch_move = Vector2.ZERO
	_touch_move_active = false

func pulse_touch_action(action: String) -> void:
	# One-frame edge for touch buttons. Valid: light|heavy|dodge|special|interact|revive|pause
	if action.is_empty():
		return  # error: reject empty touch action
	if action not in _TOUCH_ACTION_KEYS:
		return  # error: unknown touch action
	_touch_pulses[action] = true

func consume_command() -> InputCommand:
	# One build per process frame so pause UI (_process) and player (_physics_process)
	# share the same edges; pulses clear only on the first read of the frame.
	var proc_f: int = Engine.get_process_frames()
	if _cached_cmd != null and _cached_process_frame == proc_f:
		return _cached_cmd

	var cmd := InputCommand.new()
	_sequence += 1
	cmd.sequence = _sequence

	var stick := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if _touch_move_active:
		cmd.move = _touch_move
	else:
		cmd.move = stick

	cmd.light = _edge("attack_light") or _touch_pulses.get("light", false)
	cmd.heavy = _edge("attack_heavy") or _touch_pulses.get("heavy", false)
	cmd.dodge = _edge("dodge") or _touch_pulses.get("dodge", false)
	cmd.special = _edge("special_attack") or _touch_pulses.get("special", false)
	cmd.interact = _edge("interact") or _touch_pulses.get("interact", false)
	cmd.revive = _edge("revive") or _touch_pulses.get("revive", false)
	cmd.pause = _edge("pause_menu") or _touch_pulses.get("pause", false)

	_touch_pulses.clear()
	_cached_cmd = cmd
	_cached_process_frame = proc_f
	return cmd

func _edge(action: String) -> bool:
	# Prefer InputMap just_pressed when the action exists.
	if action.is_empty():
		return false  # error: reject empty action name
	if not InputMap.has_action(action):
		return false
	return Input.is_action_just_pressed(action)
