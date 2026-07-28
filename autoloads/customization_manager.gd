extends Node

const GANG_ASSETS_DIR: String = "res://assets/gangs/"
const PROPS_DIR: String = "res://assets/props/"

var current_appearance: Dictionary = {}

func load_character_appearance(character_data: Dictionary) -> void:
	if not character_data.has("appearance"):
		return
	current_appearance.clear()
	var appearance = character_data["appearance"]
	if appearance is Dictionary:
		current_appearance = appearance.duplicate()

func instance_item(item_path: String) -> Node3D:
	if item_path.is_empty() or not ResourceLoader.exists(item_path):
		return null
	var packed: PackedScene = load(item_path)
	if packed == null:
		return null
	return packed.instantiate() as Node3D

func apply_item_to_socket(socket_name: String, item_path: String) -> void:
	if socket_name.is_empty():
		return
	current_appearance[socket_name] = item_path

func save_appearance() -> void:
	pass
