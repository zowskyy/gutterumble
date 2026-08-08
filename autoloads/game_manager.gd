extends Node

signal scene_changed(scene_path: String)

const MAIN_MENU_SCENE: String = "res://scenes/main_menu/main_menu.tscn"
const CHARACTER_CREATOR_SCENE: String = "res://scenes/character_creator/character_creator.tscn"
const ARENA_SELECT_SCENE: String = "res://scenes/arena_select/arena_select.tscn"
const RUMBLE_ARENA_BACK_ALLEY_SCENE: String = "res://scenes/arenas/back_alley/rumble_arena_back_alley.tscn"
const RUMBLE_ARENA_ROOFTOP_SCENE: String = "res://scenes/arenas/rooftop/rumble_arena_rooftop.tscn"

var current_scene_path: String = MAIN_MENU_SCENE

func _ready() -> void:
	_assert_mobile_renderer()
	_boot_warmup()
	var tree: SceneTree = get_tree()
	if tree == null:
		return
	if tree.current_scene != null:
		current_scene_path = tree.current_scene.scene_file_path

func _assert_mobile_renderer() -> void:
	var renderer: String = str(
		ProjectSettings.get_setting("rendering/renderer/rendering_method", "")
	)
	if renderer != "mobile":
		push_error(
			"GUTTERUMBLE requires the mobile renderer; found '%s'. "
			% renderer
		)
		return
	print("GameManager: mobile renderer confirmed (%s)" % renderer)

func _boot_warmup() -> void:
	if not has_node("/root/ShaderWarmup"):
		return
	var warmup: Node = get_node("/root/ShaderWarmup")
	if warmup.has_method("warmup_all"):
		warmup.call_deferred("warmup_all")

func go_to_main_menu() -> void:
	change_scene(MAIN_MENU_SCENE)

func go_to_character_creator() -> void:
	change_scene(CHARACTER_CREATOR_SCENE)

func go_to_arena_select() -> void:
	change_scene(ARENA_SELECT_SCENE)

func go_to_rumble_arena_back_alley() -> void:
	change_scene(RUMBLE_ARENA_BACK_ALLEY_SCENE)

func go_to_rumble_arena_rooftop() -> void:
	change_scene(RUMBLE_ARENA_ROOFTOP_SCENE)

func change_scene(scene_path: String) -> void:
	if scene_path.is_empty():
		return
	if not ResourceLoader.exists(scene_path):
		return
	var tree: SceneTree = get_tree()
	if tree == null:
		return
	var error: Error = tree.change_scene_to_file(scene_path)
	if error != OK:
		return
	current_scene_path = scene_path
	scene_changed.emit(scene_path)

func quit_game() -> void:
	var tree: SceneTree = get_tree()
	if tree == null:
		return
	tree.quit()
