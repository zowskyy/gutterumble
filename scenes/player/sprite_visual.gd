extends AnimatedSprite3D
# 2D sprite visual for CharacterBody3D fighters (2.5D XZ-lane).
# Builds SpriteFrames from a horizontal sheet + fighter_anim_meta.json.
# Hitbox/Hurtbox remain separate Area3D children on the fighter root.

var _meta: Dictionary = {}
var _current_anim: String = ""

const META_PATH_DEFAULT := "res://assets/characters/sprite_fighter/fighter_anim_meta.json"
const PIXEL_SIZE_DEFAULT := 0.025  # 96 px * 0.025 ≈ 2.4 world units; visual height ~1.6–2.0m with centering

func _ready() -> void:
	pixel_size = PIXEL_SIZE_DEFAULT
	position = Vector3(0.0, 0.96, 0.0)
	centered = true
	# Godot 4 AnimatedSprite3D: fixed-Y billboard keeps feet on the XZ plane.
	billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST

func setup(sheet_path: String, meta_path: String = META_PATH_DEFAULT) -> void:
	var meta_file := FileAccess.open(meta_path, FileAccess.READ)
	if meta_file == null:
		push_error("sprite_visual: cannot open meta %s" % meta_path)
		return
	var parsed: Variant = JSON.parse_string(meta_file.get_as_text())
	meta_file.close()
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("sprite_visual: meta JSON is not an object")
		return
	_meta = parsed as Dictionary

	var tex := load(sheet_path) as Texture2D
	if tex == null:
		push_error("sprite_visual: cannot load sheet %s" % sheet_path)
		return

	var frame_size: Array = _meta.get("frame_size", [64, 96])
	var fw: int = int(frame_size[0])
	var fh: int = int(frame_size[1])
	var anims: Dictionary = _meta.get("animations", {})

	var frames := SpriteFrames.new()
	for anim_name in anims.keys():
		var spec: Dictionary = anims[anim_name]
		if frames.has_animation(anim_name):
			frames.remove_animation(anim_name)
		frames.add_animation(anim_name)
		frames.set_animation_loop(anim_name, bool(spec.get("loop", true)))
		var fps: float = float(spec.get("fps", 8))
		frames.set_animation_speed(anim_name, fps)
		var indices: Array = spec.get("frames", [])
		for idx_v in indices:
			var idx: int = int(idx_v)
			var atlas := AtlasTexture.new()
			atlas.atlas = tex
			atlas.region = Rect2(idx * fw, 0, fw, fh)
			frames.add_frame(anim_name, atlas)

	sprite_frames = frames
	pixel_size = PIXEL_SIZE_DEFAULT
	position = Vector3(0.0, 0.96, 0.0)
	if frames.has_animation("idle"):
		play_anim("idle")

func play_anim(anim_name: String) -> void:
	if sprite_frames == null or not sprite_frames.has_animation(anim_name):
		return
	if _current_anim == anim_name and is_playing():
		return
	_current_anim = anim_name
	play(anim_name)

func set_facing_right(right: bool) -> void:
	flip_h = not right

func get_hit_data(anim: String) -> Dictionary:
	var anims: Dictionary = _meta.get("animations", {})
	if not anims.has(anim):
		return {}
	var spec: Dictionary = anims[anim]
	var offset_arr: Array = spec.get("hit_offset", [0.55, 0.9, 0.0])
	var offset := Vector3(
		float(offset_arr[0]) if offset_arr.size() > 0 else 0.55,
		float(offset_arr[1]) if offset_arr.size() > 1 else 0.9,
		float(offset_arr[2]) if offset_arr.size() > 2 else 0.0,
	)
	return {
		"hit_offset": offset,
		"hit_radius": float(spec.get("hit_radius", 0.45)),
		"damaging": spec.get("damaging", []),
	}
