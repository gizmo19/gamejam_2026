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
	return LookAction.create(_prepare_duration(), func() -> void:
		try_pick_up(player)
	, _prepare_stamina_cost())

func try_pick_up(player: Node) -> bool:
	if player == null or player.held_item != -1:
		return false
	player.pick_up(item_type)
	return true

func _prepare_duration() -> float:
	match item_type:
		Item.Type.BEER:
			return 0.5
		Item.Type.SOUP:
			return 1.0
		Item.Type.CHICKEN:
			return 2.0
	return 1.0

func _prepare_stamina_cost() -> float:
	match item_type:
		Item.Type.BEER:
			return 1.0
		Item.Type.SOUP:
			return 3.0
		Item.Type.CHICKEN:
			return 5.0
	return 0.0
