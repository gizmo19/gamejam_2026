@tool
class_name PopupBubble
extends Node3D

const MAX_WIDTH := 280.0
const CONTENT_MARGIN := 20

@export_multiline var text: String = "Hello":
	set(value):
		text = value
		if is_node_ready():
			_apply_text()

@onready var _sprite: Sprite3D = $Sprite3D
@onready var _viewport: SubViewport = $SubViewport
@onready var _nine_patch: NinePatchRect = $SubViewport/NinePatchRect
@onready var _label: Label = $SubViewport/NinePatchRect/MarginContainer/Label

var _fit_queued: bool = false

func _ready() -> void:
	_sprite.texture = _viewport.get_texture()
	_apply_text()


func set_text(value: String) -> void:
	text = value

func _apply_text() -> void:
	_label.text = text
	_fit_to_content()

func _fit_to_content() -> void:
	if _fit_queued:
		return
	_fit_queued = true
	_fit_to_content_deferred.call_deferred()

func _fit_to_content_deferred() -> void:
	_fit_queued = false
	if not is_instance_valid(_label):
		return

	var inner_max := maxf(MAX_WIDTH - float(CONTENT_MARGIN) * 2.0, 8.0)

	# Measure natural (unwrapped) text size first.
	_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	_label.custom_minimum_size = Vector2.ZERO
	_label.reset_size()
	var natural := _label.get_minimum_size()

	var label_size: Vector2
	if natural.x <= inner_max:
		label_size = natural
	else:
		_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_label.custom_minimum_size = Vector2(inner_max, 0.0)
		_label.reset_size()
		label_size = _label.get_minimum_size()
		label_size.x = inner_max

	var bubble_size := Vector2(
		ceili(label_size.x + float(CONTENT_MARGIN) * 2.0),
		ceili(label_size.y + float(CONTENT_MARGIN) * 2.0),
	)

	_nine_patch.size = bubble_size
	_nine_patch.custom_minimum_size = bubble_size
	_viewport.size = Vector2i(bubble_size)
