@tool
class_name Table
extends StaticBody3D

const CLEAN_DURATION: float = 1.5

var is_occupied: bool = false
@export var is_dirty: bool = false

@onready var dirt_marker: MeshInstance3D = $DebugMeshDirty

func _ready() -> void:
	dirt_marker.visible = false
	if is_dirty: set_dirty(true)

func set_dirty(value: bool) -> void:
	is_dirty = value
	dirt_marker.visible = value

func get_look_action(_player: Node) -> LookAction:
	if not is_dirty:
		return null
	return LookAction.create(CLEAN_DURATION, func() -> void:
		set_dirty(false)
	)
