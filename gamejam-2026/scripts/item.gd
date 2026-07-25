@tool
class_name Item
extends Node3D

enum Type {CHICKEN = 0, SOUP = 1, BEER = 2}

const NAMES: Array[String] = ["Chicken", "Soup", "Beer"]

@export var item_type: Type = Type.SOUP:
	set(value):
		item_type = value
		_update_visual()

@export var empty: bool = false:
	set(value):
		empty = value
		_update_visual()

@onready var _item_type_mesh: Node3D = $Mesh


func _ready() -> void:
	_update_visual()


static func prepare_duration(type: Type) -> float:
	match type:
		Type.BEER:
			return 0.5
		Type.SOUP:
			return 1.0
		Type.CHICKEN:
			return 2.0
	return 1.0


static func prepare_stamina_cost(type: Type) -> float:
	match type:
		Type.BEER:
			return 1.0
		Type.SOUP:
			return 3.0
		Type.CHICKEN:
			return 5.0
	return 0.0


func _update_visual() -> void:
	if not is_node_ready():
		return
	var type_name := NAMES[item_type]
	var visible_name := type_name + "Empty" if empty else type_name
	for child in _item_type_mesh.get_children():
		child.visible = child.name == visible_name
