@tool
class_name PickupArea
extends Node3D

@onready var item: Item = $Item

@export var item_type: Item.Type = Item.Type.SOUP:
	set(value):
		item_type = value
		_apply_item_type()

func _ready() -> void:
	_apply_item_type()

func _apply_item_type() -> void:
	var target: Item = item if item else get_node_or_null("Item") as Item
	if target:
		target.item_type = item_type

func set_focused(focused: bool) -> void:
	if item:
		item.set_highlighted(focused)

func try_pick_up(player: Node) -> bool:
	if player == null or player.held_item != -1:
		return false
	player.pick_up(item.item_type)
	return true
