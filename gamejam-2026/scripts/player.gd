extends CharacterBody3D

const SPEED: float = 4.0
const SPRINT_SPEED: float = 8.0
const GRAVITY: float = 9.8
const MOUSE_SENSITIVITY: float = 0.002
const LOOK_SENSITIVITY: float = 2.5

@onready var camera: Camera3D = $Camera3D
@onready var hud: CanvasLayer = $HUD
@onready var _held_label: Label = $HUD/HeldLabel
@onready var interact_ray: RayCast3D = $Camera3D/InteractRay

var pitch: float = 0.0
var held_item: int = -1

var _focused_pickup: PickupArea = null
var _focused_target: Node = null
var _focused_action: LookAction = null
var _action_progress: float = 0.0

func _ready() -> void:
	add_to_group("player")
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func pick_up(type: int) -> void:
	held_item = type
	_held_label.text = "Holding: " + Item.NAMES[type]

func clear_held_item() -> void:
	held_item = -1
	_held_label.text = ""

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * MOUSE_SENSITIVITY)
		pitch -= event.relative.y * MOUSE_SENSITIVITY
		pitch = clamp(pitch, -1.4, 1.4)
		camera.rotation.x = pitch

	if Input.is_action_pressed("Escape"):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			get_tree().quit()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("Interaction") and _focused_pickup:
		if _focused_pickup.try_pick_up(self):
			get_viewport().set_input_as_handled()

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= GRAVITY * delta

	var look := Input.get_vector("LookLeft", "LookRight", "LookUp", "LookDown")
	if look != Vector2.ZERO:
		rotate_y(-look.x * LOOK_SENSITIVITY * delta)
		pitch -= look.y * LOOK_SENSITIVITY * delta
		pitch = clamp(pitch, -1.4, 1.4)
		camera.rotation.x = pitch

	var speed: float = SPRINT_SPEED if Input.is_action_pressed("Sprint") else SPEED

	var input_dir := Input.get_vector("Left", "Right", "Forward", "Back")
	var direction := (transform.basis * Vector3(input_dir.x, 0.0, input_dir.y)).normalized()

	velocity.x = direction.x * speed
	velocity.z = direction.z * speed

	move_and_slide()
	_update_interact_focus()
	_update_action_progress(delta)

func _update_interact_focus() -> void:
	var new_pickup: PickupArea = null
	var new_target: Node = null
	var new_action: LookAction = null

	if interact_ray.is_colliding():
		var collider: Object = interact_ray.get_collider()
		var candidate: Node = _resolve_interact_candidate(collider)
		if candidate:
			if candidate.has_method("get_look_action"):
				new_action = candidate.get_look_action(self)
				if new_action:
					new_target = candidate
			if candidate is PickupArea:
				new_pickup = candidate as PickupArea

	if new_pickup != _focused_pickup:
		if _focused_pickup:
			_focused_pickup.set_focused(false)
		_focused_pickup = new_pickup
		if _focused_pickup:
			_focused_pickup.set_focused(true)

	var target_changed := new_target != _focused_target
	var action_availability_changed := (new_action == null) != (_focused_action == null)
	_focused_target = new_target
	_focused_action = new_action
	if target_changed or action_availability_changed:
		_reset_action_progress()

func _resolve_interact_candidate(collider: Object) -> Node:
	if collider is Node and (collider as Node).has_method("get_look_action"):
		return collider as Node
	if collider is Node:
		var parent: Node = (collider as Node).get_parent()
		if parent:
			if parent.has_method("get_look_action") or parent is PickupArea:
				return parent
	return null

func _update_action_progress(delta: float) -> void:
	if _focused_action and Input.is_action_pressed("Interaction"):
		_action_progress = minf(_action_progress + delta / _focused_action.duration, 1.0)
		hud.set_action_progress(_action_progress)
		if _action_progress >= 1.0:
			var action := _focused_action
			_reset_action_progress()
			action.on_complete.call()
	elif _action_progress > 0.0:
		_reset_action_progress()

func _reset_action_progress() -> void:
	_action_progress = 0.0
	hud.set_action_progress(-1.0)
