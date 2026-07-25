@tool
class_name PickupArea
extends Node3D

const CUT_PUMPKIN_SFX: AudioStream = preload("res://assets/audio/cut_pumpkin_02.ogg")
const WATER_SFX: AudioStream = preload("res://assets/audio/water.wav")

@onready var item: Item = $Item

@export var item_type: Item.Type = Item.Type.SOUP:
	set(value):
		item_type = value
		_apply_item_type()

var _cut_player: AudioStreamPlayer
var _water_player: AudioStreamPlayer

func _ready() -> void:
	_apply_item_type()
	if not Engine.is_editor_hint():
		_cut_player = AudioStreamPlayer.new()
		_cut_player.stream = CUT_PUMPKIN_SFX
		_cut_player.volume_db = linear_to_db(0.25)
		add_child(_cut_player)
		_water_player = AudioStreamPlayer.new()
		_water_player.stream = WATER_SFX
		add_child(_water_player)

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
	if item_type == Item.Type.CHICKEN and _cut_player:
		_cut_player.play()
	elif item_type in [Item.Type.BEER, Item.Type.SOUP] and _water_player:
		_water_player.play()
	player.pick_up(item_type)
	return true
