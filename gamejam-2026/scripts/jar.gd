extends Node3D

const CROWNS_MAX := 100.0
const CYLINDER1_MAX := 60.0
const TOP_Y_MIN := 0.15
const TOP_Y_MAX := 2.863
const CYL2_TOP_RADIUS_START := 0.865
const CYL2_TOP_RADIUS_END := 0.645
## Avoid scale.y = 0 (singular basis / det == 0 errors).
const SCALE_MIN := 0.001
const CROWN_LAND_Y := 0.5
const CROWN_DROP_DURATION := 0.6

@onready var _cylinder_origin: Node3D = $CylinderOrigin
@onready var _cylinder2_origin: Node3D = $Cylinder2Origin
@onready var _cylinder2_mesh: CylinderMesh = $Cylinder2Origin/Cylinder.mesh
@onready var _top: Node3D = $Top
@onready var _crown_anim: Node3D = $CrownAnim

var _crown_anim_start_pos: Vector3
var _crown_tween: Tween


func _ready() -> void:
	_crown_anim_start_pos = _crown_anim.position
	_crown_anim.visible = false
	ScoreState.changed.connect(_on_score_changed)
	ScoreState.crowns_changed.connect(_on_crowns_changed)
	_on_score_changed()


func _on_score_changed() -> void:
	var amount := clampf(float(ScoreState.total_crowns), 0.0, CROWNS_MAX)

	_set_scaled_fill(_cylinder_origin, amount / CYLINDER1_MAX)

	if amount < CYLINDER1_MAX:
		_cylinder2_origin.visible = false
		_cylinder2_origin.scale.y = 1.0
		_cylinder2_mesh.top_radius = CYL2_TOP_RADIUS_START
	else:
		var t2 := clampf(
			(amount - CYLINDER1_MAX) / (CROWNS_MAX - CYLINDER1_MAX),
			0.0,
			1.0
		)
		_set_scaled_fill(_cylinder2_origin, t2)
		_cylinder2_mesh.top_radius = lerpf(CYL2_TOP_RADIUS_START, CYL2_TOP_RADIUS_END, t2)

	_top.position.y = lerpf(TOP_Y_MIN, TOP_Y_MAX, amount / CROWNS_MAX)


func _on_crowns_changed(_total: int) -> void:
	if _crown_tween != null and _crown_tween.is_valid():
		_crown_tween.kill()

	_crown_anim.position = _crown_anim_start_pos
	_crown_anim.visible = true

	_crown_tween = create_tween()
	_crown_tween.set_ease(Tween.EASE_IN)
	_crown_tween.set_trans(Tween.TRANS_QUAD)
	_crown_tween.tween_property(
		_crown_anim,
		"position:y",
		CROWN_LAND_Y,
		CROWN_DROP_DURATION
	)
	_crown_tween.tween_callback(_reset_crown_anim)


func _reset_crown_anim() -> void:
	_crown_anim.position = _crown_anim_start_pos
	_crown_anim.visible = false


func _set_scaled_fill(node: Node3D, t: float) -> void:
	t = clampf(t, 0.0, 1.0)
	node.visible = t > 0.0
	node.scale.y = maxf(t, SCALE_MIN)
