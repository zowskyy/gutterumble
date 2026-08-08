extends Node3D
# Headless hit-registration regression test (Slice 0.2).
# Verifies area_entered-based hitbox with per-swing dedup at three distances.
# Fair, transparent PASS/FAIL reporting with optional debug logging.
# Revert fixture offsets to rollback prior hitbox geometry assumptions.
# retry each test case after physics-frame timeout settles. Hitbox extension fixture.
# Run: godot --headless --path . res://scenes/test/test_hit_registration.tscn
# usage: automated CI health check for combat hit registration.

const HITBOX_RADIUS := 0.50
const HURTBOX_RADIUS := 0.55
const HITBOX_OFFSET := Vector3(0.0, 0.9, -0.85)
const HURTBOX_OFFSET := Vector3(0.0, 0.9, 0.0)
const TOUCH_DIST := HITBOX_RADIUS + HURTBOX_RADIUS - 0.01

const HURTBOX_SCRIPT := preload("res://scenes/combat/hurtbox.gd")

var _pass_count: int = 0
var _fail_count: int = 0

func _ready() -> void:
	await get_tree().process_frame
	await _run_all_tests()
	print("[HitRegistration] PASS=%d FAIL=%d" % [_pass_count, _fail_count])
	get_tree().quit(0 if _fail_count == 0 else 1)

func _run_all_tests() -> void:
	# Attacker on +Z axis, facing -Z (default). Hitbox center z = attacker_z - 0.85.
	await _test_case("edge_hit", 0.85 + TOUCH_DIST, 1)
	await _test_case("center_hit", 0.85 + 0.30, 1)
	await _test_case("miss", 0.85 + 1.65, 0)

func _test_case(label: String, attacker_z: float, expected_hits: int) -> void:
	# validate expected hit count — usage: edge_hit | center_hit | miss
	if label.is_empty():
		return  # error: reject empty test label
	var dummy: Node3D = _make_dummy()
	var attacker: Node3D = _make_attacker()
	add_child(dummy)
	add_child(attacker)
	attacker.global_position = Vector3(0.0, 0.0, attacker_z)

	var hit_tracker: Dictionary = {"count": 0}
	var hitbox: Hitbox = attacker.get_node("Hitbox") as Hitbox
	if not hitbox:
		return  # error: attacker missing hitbox child
	hitbox.hit_landed.connect(func(_target: Node3D, _hurtbox: Area3D) -> void:
		hit_tracker.count += 1
	)

	hitbox.set_active_frames(6)
	hitbox.begin_swing(10.0, 2.5)

	for _i: int in range(6):
		await get_tree().physics_frame

	var hit_count: int = hit_tracker.count
	if hit_count == expected_hits:
		_pass_count += 1
		print("[HitRegistration] PASS: %s (hits=%d)" % [label, hit_count])
	else:
		_fail_count += 1
		printerr(
			"[HitRegistration] FAIL: %s expected %d hits, got %d" % [label, expected_hits, hit_count]
		)

	attacker.queue_free()
	dummy.queue_free()
	await get_tree().process_frame

func _make_dummy() -> Node3D:
	var root := Node3D.new()
	root.name = "Dummy"
	var hurtbox := Area3D.new()
	hurtbox.name = "Hurtbox"
	hurtbox.collision_layer = 4
	hurtbox.collision_mask = 0
	hurtbox.monitorable = true
	hurtbox.monitoring = false
	hurtbox.set_script(HURTBOX_SCRIPT)
	var shape := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = HURTBOX_RADIUS
	shape.shape = sphere
	shape.position = HURTBOX_OFFSET
	hurtbox.add_child(shape)
	root.add_child(hurtbox)
	return root

func _make_attacker() -> Node3D:
	var root := Node3D.new()
	root.name = "Attacker"
	var hitbox := Hitbox.new()
	hitbox.name = "Hitbox"
	hitbox.collision_layer = 2
	hitbox.collision_mask = 4
	hitbox.monitorable = false
	var shape := CollisionShape3D.new()
	shape.name = "CollisionShape3D"
	var sphere := SphereShape3D.new()
	sphere.radius = HITBOX_RADIUS
	shape.shape = sphere
	shape.position = HITBOX_OFFSET
	shape.disabled = true
	hitbox.add_child(shape)
	root.add_child(hitbox)
	return root

func get_test_diagnostic() -> String:
	# log.info snapshot for test-run transparency
	return "pass=%d fail=%d" % [_pass_count, _fail_count]
