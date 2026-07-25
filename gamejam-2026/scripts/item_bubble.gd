class_name ItemBubble
extends Node3D

@onready var item: Item = %Item
@onready var item_origin: Node3D = $ItemOrigin

func _ready() -> void:
	_make_unshaded(item)

func _process(_delta: float) -> void:
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return
	var target := camera.global_position
	target.y = global_position.y
	if global_position.distance_squared_to(target) > 0.0001:
		look_at(target, Vector3.UP)

func _make_unshaded(node: Node) -> void:
	if node is MeshInstance3D:
		var mesh_instance := node as MeshInstance3D
		mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mesh_instance.gi_mode = GeometryInstance3D.GI_MODE_DISABLED
		if mesh_instance.mesh:
			for i in mesh_instance.mesh.get_surface_count():
				var mat := mesh_instance.get_active_material(i)
				if mat is BaseMaterial3D:
					var dup := mat.duplicate() as BaseMaterial3D
					dup.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
					mesh_instance.set_surface_override_material(i, dup)
	for child in node.get_children():
		_make_unshaded(child)

func show_item(type: Item.Type) -> void:
	item.item_type = type
	item.empty = false
	visible = true

func hide_item() -> void:
	visible = false
