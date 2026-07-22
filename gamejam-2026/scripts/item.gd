class_name Item
extends Node3D

enum Type { CHICKEN = 0, SOUP = 1, BEER = 2 }

const NAMES: Array[String] = ["Chicken", "Soup", "Beer"]
const COLORS: Array[Color] = [
	Color(0.85, 0.35, 0.1),
	Color(0.2, 0.8, 0.2),
	Color(1.0, 0.85, 0.1),
]

@export var item_type: Type = Type.SOUP

@onready var _mesh: MeshInstance3D = $MeshInstance3D
@onready var _label: Label3D = $Label3D
@onready var _area: Area3D = $PickupArea

var _player_inside: bool = false

func _ready() -> void:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = COLORS[item_type]
	_mesh.set_surface_override_material(0, mat)
	_label.text = NAMES[item_type]
	_area.body_entered.connect(func(b: Node3D) -> void:
		if b.name == "Player": _player_inside = true)
	_area.body_exited.connect(func(b: Node3D) -> void:
		if b.name == "Player": _player_inside = false)

func _unhandled_input(event: InputEvent) -> void:
	if not (_player_inside
			and event is InputEventKey
			and event.keycode == KEY_E
			and event.pressed
			and not event.echo):
		return
	var player: Node = get_tree().get_first_node_in_group("player")
	if player and player.held_item == -1:
		player.pick_up(item_type)
		get_viewport().set_input_as_handled()
