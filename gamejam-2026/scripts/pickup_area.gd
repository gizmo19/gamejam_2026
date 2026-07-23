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

func get_look_action(player: Node) -> LookAction:
	if player == null or player.held_item != -1:
		return null
	return LookAction.create(Item.prepare_duration(item_type), func() -> void:
		try_pick_up(player)
	, Item.prepare_stamina_cost(item_type))

func try_pick_up(player: Node) -> bool:
	if player == null or player.held_item != -1:
		return false
	player.pick_up(item_type)
	return true
