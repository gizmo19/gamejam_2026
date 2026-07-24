class_name Synek
extends StaticBody3D

const FEED_DURATION: float = 1.0
const STAMINA_RESTORE_MULTIPLIER: float = 5.0
const ANIM_RESET_DURATION: float = 10.0

signal fed

@onready var _item_son: Item = %ItemSon
@onready var _item_player: Item = %ItemPlayer
@onready var _sprite: Sprite3D = $Sprite3D
@onready var _animated_sprite: AnimatedSprite2D = %Sprite
@onready var _viewport: SubViewport = $SubViewport

var _showing_fed_son: int = 0

func _ready() -> void:
	# ViewportTexture path refs can fail when the scene is instanced; bind at runtime.
	_sprite.texture = _viewport.get_texture()

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
	_show_food(_item_son, food_type, true)
	_show_food(_item_player, food_type, true)
	_animated_sprite.play(Item.NAMES[food_type])
	_start_anim_reset_timer()
	fed.emit()

func _start_anim_reset_timer() -> void:
	_showing_fed_son += 1
	var token := _showing_fed_son
	await get_tree().create_timer(ANIM_RESET_DURATION).timeout
	if token == _showing_fed_son:
		_animated_sprite.play("default")

func _show_food(item: Item, food_type: Item.Type, empty = false) -> void:
	item.item_type = food_type
	item.empty = empty
