class_name Table
extends StaticBody3D

const CLEAN_COLOR := Color(0.55, 0.35, 0.15, 1)
const DIRTY_COLOR := Color.RED

var is_occupied: bool = false
var is_dirty: bool = false

@onready var table_mesh: MeshInstance3D = $TableMesh

func _ready() -> void:
	var mat := table_mesh.get_surface_override_material(0)
	if mat:
		table_mesh.set_surface_override_material(0, mat.duplicate())

func dirty() -> void:
	is_dirty = true
	_set_table_color(DIRTY_COLOR)

func clean() -> void:
	is_dirty = false
	_set_table_color(CLEAN_COLOR)

func _set_table_color(color: Color) -> void:
	var mat := table_mesh.get_surface_override_material(0) as StandardMaterial3D
	if mat == null:
		mat = StandardMaterial3D.new()
		table_mesh.set_surface_override_material(0, mat)
	mat.albedo_color = color
