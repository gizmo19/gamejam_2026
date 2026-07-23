@tool
class_name Table
extends StaticBody3D

const CLEAN_DURATION: float = 1.5
const SERVE_DURATION: float = 0.5

var is_occupied: bool = false
@export var is_dirty: bool = false

var customer: Npc = null
var has_food: bool = false

@onready var dirt_marker: MeshInstance3D = $DebugMeshDirty
@onready var placed_item: Item = $PlacedItem

func _ready() -> void:
	dirt_marker.visible = false
	if placed_item:
		placed_item.visible = false
	if is_dirty:
		set_dirty(true)

func set_dirty(value: bool) -> void:
	is_dirty = value
	dirt_marker.visible = value

func assign_customer(npc: Npc) -> void:
	customer = npc

func place_food(item_type: Item.Type) -> void:
	has_food = true
	placed_item.item_type = item_type
	placed_item.visible = true

func clear_customer() -> void:
	customer = null
	has_food = false
	if placed_item:
		placed_item.visible = false

func get_look_action(player: Node) -> LookAction:
	if is_dirty:
		return LookAction.create(CLEAN_DURATION, func() -> void:
			set_dirty(false)
			ScoreState.record_table_cleaned()
		, 6.0)

	if customer \
			and not has_food \
			and not customer.was_served \
			and player != null \
			and player.held_item == int(customer.order):
		return LookAction.create(SERVE_DURATION, func() -> void:
			_serve(player)
		, 1.0)

	return null

func _serve(player: Node) -> void:
	if customer == null or has_food or customer.was_served:
		return
	if player == null or player.held_item != int(customer.order):
		return
	var food_type := player.held_item as Item.Type
	player.clear_held_item()
	place_food(food_type)
	ScoreState.record_served()
	customer.accept_delivery()
