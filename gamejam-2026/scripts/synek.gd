class_name Synek
extends StaticBody3D

const FEED_DURATION: float = 1.0
const STAMINA_RESTORE_MULTIPLIER: float = 5.0

signal fed

@onready var _item_son: Item = %ItemSon
@onready var _item_player: Item = %ItemPlayer

func get_look_action(player: Node) -> LookAction:
	if player == null or player.held_item == -1:
		return null
	var food_type := player.held_item as Item.Type
	var restore := Item.prepare_stamina_cost(food_type) * STAMINA_RESTORE_MULTIPLIER

	return LookAction.create(FEED_DURATION, func() -> void:
		_feed(player, food_type)
	, -restore)

func _feed(player: Node, food_type: Item.Type) -> void:
	if player == null or player.held_item != int(food_type):
		return
	player.clear_held_item()
	_show_food(_item_son, food_type)
	_show_food(_item_player, food_type, true)
	fed.emit()

func _show_food(item: Item, food_type: Item.Type, empty = false) -> void:
	item.item_type = food_type
	item.empty = empty
