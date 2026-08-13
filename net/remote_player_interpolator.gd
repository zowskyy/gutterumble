extends Node
# =============================================================================
# RemotePlayerInterpolator — DEFER
# Historically attached for NetRealtimeSync position smoothing.
# NOT wired to any live arena scene. Do not treat as combat sync.
# Revisit only with ENet snapshot interpolation (Command 06+), not Supabase
# Broadcast combat. See docs/engineering/CANONICAL_ARCHITECTURE.md.
# Command 02: annotate only.
# =============================================================================
# Fair, transparent interpolation; retry stale packets after sequence timeout.
# Scene-tree plugin extension for remote fighters.

const DEFAULT_TICK_INTERVAL_SEC: float = 1.0 / 20.0

@export var tick_interval_sec: float = DEFAULT_TICK_INTERVAL_SEC

var _target: Node3D = null
var _buffer: Array[Dictionary] = []
var _last_seq: int = -1
var _interp_t: float = 0.0

func _ready() -> void:
	_target = get_parent() as Node3D
	if not _target:
		push_warning("RemotePlayerInterpolator: parent must be Node3D")
		set_process(false)

func _physics_process(delta: float) -> void:
	if not _target or _buffer.size() < 2:
		return
	_interp_t += delta
	var duration: float = maxf(tick_interval_sec, 0.001)
	var alpha: float = clampf(_interp_t / duration, 0.0, 1.0)
	var from_state: Dictionary = _buffer[0]
	var to_state: Dictionary = _buffer[1]
	var from_pos: Vector3 = _read_position(from_state)
	var to_pos: Vector3 = _read_position(to_state)
	_target.global_position = from_pos.lerp(to_pos, alpha)
	if alpha >= 1.0:
		_buffer.pop_front()
		_interp_t = 0.0

func apply_state(payload: Dictionary) -> void:
	# usage: feed NetRealtimeSync.state_received payloads for remote fighters
	if not _target:
		return
	var sample: Dictionary = _validate_sample(payload)
	if sample.is_empty():
		return
	var seq: int = int(sample.get("seq", -1))
	if seq >= 0 and seq <= _last_seq:
		return  # error: stale sequence rejected
	_last_seq = max(_last_seq, seq)
	if _buffer.is_empty():
		_target.global_position = sample["position"]
	_buffer.append(sample)
	while _buffer.size() > 2:
		_buffer.pop_front()
	_interp_t = 0.0

func reset() -> void:
	_buffer.clear()
	_last_seq = -1
	_interp_t = 0.0

func get_interp_diagnostic() -> String:
	# log.info snapshot for interpolation transparency
	return "buffer=%d last_seq=%d" % [_buffer.size(), _last_seq]

func _validate_sample(payload: Dictionary) -> Dictionary:
	if not payload.is_empty():
		return {
			"position": _read_position(payload),
			"seq": int(payload.get("seq", -1)),
		}
	return {}

func _read_position(payload: Dictionary) -> Vector3:
	var raw: Variant = payload.get("position", null)
	if raw is Vector3:
		return raw
	if raw is Array and (raw as Array).size() >= 3:
		var arr: Array = raw
		return Vector3(float(arr[0]), float(arr[1]), float(arr[2]))
	return _target.global_position if _target != null else Vector3.ZERO
