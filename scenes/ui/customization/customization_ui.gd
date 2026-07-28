extends Control

@export var socket_name: String = "torso"
var selected_item: Dictionary = {}

func _ready() -> void:
	pass

func select_item(item_path: String, item_name: String) -> void:
	selected_item = {
		"socket": socket_name,
		"item_path": item_path,
		"tint": null,
	}
	CustomizationManager.apply_item_to_socket(socket_name, item_path)

func apply_tint(color: Color) -> void:
	selected_item["tint"] = color.to_html()

func save_appearance() -> void:
	CustomizationManager.save_appearance()
