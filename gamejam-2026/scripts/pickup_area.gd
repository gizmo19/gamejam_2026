@tool
class_name PickupArea
extends Node3D

const CUT_PUMPKIN_SFX: AudioStream = preload("res://assets/audio/cut_pumpkin_02.ogg")
const WATER_SFX: AudioStream = preload("res://assets/audio/water.wav")

@onready var _label: Label3D = $Label3D

@export var item_type: Item.Type = Item.Type.SOUP:
	set(value):
		item_type = value
		_apply_item_type()

var _cut_player: AudioStreamPlayer
var _water_player: AudioStreamPlayer
var _highlighted: bool = false
var _highlight_mat: StandardMaterial3D

func _ready() -> void:
	_highlight_mat = StandardMaterial3D.new()
	_highlight_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_highlight_mat.albedo_color = Color(1.0, 0.95, 0.4, 0.23)
	_highlight_mat.emission_enabled = true
	_highlight_mat.emission = Color(1.0, 0.9, 0.3)
	_highlight_mat.emission_energy_multiplier = 2.5
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
	for child in _item_nodes():
		child.item_type = item_type
	var label: Label3D = _label if _label else get_node_or_null("Label3D") as Label3D
	if label:
		label.text = Item.NAMES[item_type]
	_apply_highlight()

func set_focused(focused: bool) -> void:
	if _highlighted == focused:
		return
	_highlighted = focused
	_apply_highlight()

func _item_nodes() -> Array[Item]:
	var items: Array[Item] = []
	for child in find_children("*", "Item", true, false):
		items.append(child as Item)
	return items

func _apply_highlight() -> void:
	if not is_node_ready():
		return
	var overlay: Material = _highlight_mat if _highlighted else null
	for mesh in find_children("*", "MeshInstance3D", true, false):
		(mesh as MeshInstance3D).material_overlay = overlay
	var label: Label3D = _label if _label else get_node_or_null("Label3D") as Label3D
	if label:
		label.modulate = Color(1.4, 1.3, 0.6) if _highlighted else Color.WHITE
		label.outline_modulate = Color(0.2, 0.15, 0.0) if _highlighted else Color.BLACK

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
