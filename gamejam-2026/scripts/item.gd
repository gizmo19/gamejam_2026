@tool
class_name Item
extends Node3D

enum Type {CHICKEN = 0, SOUP = 1, BEER = 2}

const NAMES: Array[String] = ["Chicken", "Soup", "Beer"]
const COLORS: Array[Color] = [
	Color(0.85, 0.35, 0.1),
	Color(0.2, 0.8, 0.2),
	Color(1.0, 0.85, 0.1),
]

@export var item_type: Type = Type.SOUP:
	set(value):
		item_type = value
		_update_visual()

@onready var _item_type_mesh: Node3D = $Mesh
@onready var _label: Label3D = $Label3D


func _ready() -> void:
	_update_visual()


func _update_visual() -> void:
	if not is_node_ready():
		return
	var type_name := NAMES[item_type]
	for child in _item_type_mesh.get_children():
		child.visible = child.name == type_name
	_label.text = type_name
