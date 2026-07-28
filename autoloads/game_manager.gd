extends Node

signal scene_changed(scene_path: String)

const MAIN_MENU_SCENE: String = "res://scenes/main_menu/main_menu.tscn"
const CHARACTER_CREATOR_SCENE: String = "res://scenes/character_creator/character_creator.tscn"
const RUMBLE_ARENA_BACK_ALLEY_SCENE: String = "res://scenes/arenas/back_alley/rumble_arena_back_alley.tscn"

var current_scene_path: String = MAIN_MENU_SCENE

func _ready() -> void:
	var tree: SceneTree = get_tree()
	if tree == null:
		return
	if tree.current_scene != null:
		current_scene_path = tree.current_scene.scene_file_path

func go_to_main_menu() -> void:
	change_scene(MAIN_MENU_SCENE)

func go_to_character_creator() -> void:
	change_scene(CHARACTER_CREATOR_SCENE)

func go_to_rumble_arena_back_alley() -> void:
	change_scene(RUMBLE_ARENA_BACK_ALLEY_SCENE)

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
