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

var _highlighted: bool = false
var _highlight_mat: StandardMaterial3D


func _ready() -> void:
	_highlight_mat = StandardMaterial3D.new()
	_highlight_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_highlight_mat.albedo_color = Color(1.0, 0.95, 0.4, 0.35)
	_highlight_mat.emission_enabled = true
	_highlight_mat.emission = Color(1.0, 0.9, 0.3)
	_highlight_mat.emission_energy_multiplier = 2.5
	_update_visual()


func set_highlighted(highlighted: bool) -> void:
	if _highlighted == highlighted:
		return
	_highlighted = highlighted
	_apply_highlight()


func _apply_highlight() -> void:
	if not is_node_ready():
		return
	var overlay: Material = _highlight_mat if _highlighted else null
	for mesh in _item_type_mesh.find_children("*", "MeshInstance3D", true, false):
		(mesh as MeshInstance3D).material_overlay = overlay
	_label.modulate = Color(1.4, 1.3, 0.6) if _highlighted else Color.WHITE
	_label.outline_modulate = Color(0.2, 0.15, 0.0) if _highlighted else Color.BLACK


func _update_visual() -> void:
	if not is_node_ready():
		return
	var type_name := NAMES[item_type]
	for child in _item_type_mesh.get_children():
		child.visible = child.name == type_name
	_label.text = type_name
	_apply_highlight()
