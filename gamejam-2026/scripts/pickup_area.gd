@tool
class_name PickupArea
extends Node3D

@onready var _area: Area3D = $Area
@onready var item: Item = $Item

@export var item_type: Item.Type = Item.Type.SOUP:
	set(value):
		item_type = value
		_apply_item_type()

var _player_inside: bool = false

func _ready() -> void:
	_apply_item_type()
	_area.body_entered.connect(func(b: Node3D) -> void:
		if b.name == "Player": _player_inside = true)
	_area.body_exited.connect(func(b: Node3D) -> void:
		if b.name == "Player": _player_inside = false)

func _apply_item_type() -> void:
	var target: Item = item if item else get_node_or_null("Item") as Item
	if target:
		target.item_type = item_type

func _unhandled_input(event: InputEvent) -> void:
	if not (_player_inside
			and event is InputEventKey
			and event.keycode == KEY_E
			and event.pressed
			and not event.echo):
		return
	var player: Node = get_tree().get_first_node_in_group("player")
	if player and player.held_item == -1:
		player.pick_up(item.item_type)
		get_viewport().set_input_as_handled()
