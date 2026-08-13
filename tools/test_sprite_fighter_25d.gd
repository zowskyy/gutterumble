extends SceneTree
# Headless smoke: sprite fighter + enemy load, lane API, anim meta, stick contract.
# Usage: godot --headless --path . -s res://tools/test_sprite_fighter_25d.gd

var _fails: int = 0

func _init() -> void:
	call_deferred("_run")

func _fail(msg: String) -> void:
	_fails += 1
	push_error("FAIL: " + msg)
	print("FAIL: ", msg)

func _pass(msg: String) -> void:
	print("PASS: ", msg)

func _run() -> void:
	var meta_path := "res://assets/characters/sprite_fighter/fighter_anim_meta.json"
	var f := FileAccess.open(meta_path, FileAccess.READ)
	if f == null:
		_fail("meta missing")
	else:
		var meta: Variant = JSON.parse_string(f.get_as_text())
		f.close()
		if typeof(meta) != TYPE_DICTIONARY:
			_fail("meta not dict")
		else:
			var anims: Dictionary = (meta as Dictionary).get("animations", {})
			for need in ["idle", "walk", "punch_light", "kick", "hit", "ko"]:
				if not anims.has(need):
					_fail("meta missing anim " + need)
			_pass("anim meta keys")

	for sheet in [
		"res://assets/characters/sprite_fighter/player_sheet.png",
		"res://assets/characters/sprite_fighter/enemy_sheet.png",
	]:
		if load(sheet) == null:
			_fail("sheet load " + sheet)
		else:
			_pass("sheet " + sheet.get_file())

	var player_ps: PackedScene = load("res://scenes/player/sprite_fighter.tscn")
	var enemy_ps: PackedScene = load("res://scenes/enemies/sprite_enemy.tscn")
	if player_ps == null:
		_fail("sprite_fighter.tscn")
	if enemy_ps == null:
		_fail("sprite_enemy.tscn")

	var holder := Node3D.new()
	holder.name = "TestRoot"
	root.add_child(holder)

	var player: Node = null
	var enemy: Node = null
	if player_ps:
		player = player_ps.instantiate()
		holder.add_child(player)
	if enemy_ps:
		enemy = enemy_ps.instantiate()
		holder.add_child(enemy)

	await process_frame
	await process_frame

	if player == null or enemy == null:
		_fail("instantiate fighters")
		_finish()
		return

	if player.get_node_or_null("SpriteVisual") == null:
		_fail("player SpriteVisual")
	else:
		_pass("player SpriteVisual")
	if enemy.get_node_or_null("SpriteVisual") == null:
		_fail("enemy SpriteVisual")
	else:
		_pass("enemy SpriteVisual")
	if player.get_node_or_null("MouseModel") != null:
		_fail("player still has MouseModel")
	else:
		_pass("player no MouseModel")

	if not player.has_method("set_lane"):
		_fail("player set_lane")
	else:
		player.set_lane(2.5, enemy)
		if absf(player.global_position.z - 2.5) > 0.01:
			_fail("player lane_z lock")
		else:
			_pass("player set_lane")
	if not enemy.has_method("set_lane"):
		_fail("enemy set_lane")
	else:
		enemy.set_lane(2.5, player)
		_pass("enemy set_lane")

	var src := FileAccess.get_file_as_string("res://scenes/ui/touch_controls.gd")
	if "move.y = -move.y" in src:
		_fail("touch stick still inverts Y")
	else:
		_pass("touch stick Y not inverted")

	_finish()

func _finish() -> void:
	print("RESULT fails=", _fails)
	quit(1 if _fails > 0 else 0)
