class_name ItemBubble
extends Node3D

@onready var item: Item = %Item
@onready var item_origin: Node3D = $ItemOrigin

var rotation_speed: float = 1.2

func _ready() -> void:
	item.get_node("Label3D").visible = false

func _process(delta: float) -> void:
	item_origin.global_rotate(Vector3.UP, rotation_speed * delta)

func show_item(type: Item.Type) -> void:
	item.item_type = type
	item.empty = false
	visible = true

func hide_item() -> void:
	visible = false
