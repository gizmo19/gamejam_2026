extends CharacterBody3D

const SPEED: float = 4.0
const SPRINT_SPEED: float = 8.0
const GRAVITY: float = 9.8
const MOUSE_SENSITIVITY: float = 0.002
const LOOK_SENSITIVITY: float = 2.5
const MAX_STAMINA: float = 100.0
@onready var camera: Camera3D = $Camera3D
@onready var hud: CanvasLayer = $HUD
@onready var interact_ray: RayCast3D = $Camera3D/InteractRay
@onready var _held_item_container: Node3D = $PickedUpItem
@onready var _held_item_visual: Item = $PickedUpItem/Item

var pitch: float = 0.0
var held_item: int = -1
var stamina: float = 60.0

var _focused_pickup: PickupArea = null
var _focused_target: Node = null
var _focused_action: LookAction = null
var _action_progress: float = 0.0

func _ready() -> void:
	add_to_group("player")
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	_held_item_container.visible = false
	_sync_stamina_hud()

func pick_up(type: int) -> void:
	held_item = type
	_held_item_visual.item_type = type as Item.Type
	_held_item_container.visible = true

func clear_held_item() -> void:
	held_item = -1
	_held_item_container.visible = false

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * MOUSE_SENSITIVITY)
		pitch -= event.relative.y * MOUSE_SENSITIVITY
		pitch = clamp(pitch, -1.4, 1.4)
		camera.rotation.x = pitch

	if event.is_action_pressed("Escape"):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			get_tree().quit()

func _physics_process(delta: float) -> void:
	_update_movement(delta)

	move_and_slide()

	_update_item_interaction()
	_update_interact_focus()
	_update_action_progress(delta)

func _update_movement(delta: float) -> void:
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

func _update_item_interaction() -> void:
	if held_item != -1:
		if Input.is_action_just_pressed("DropItem"):
			clear_held_item()

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
	var node := collider as Node
	while node:
		if node.has_method("get_look_action") or node is PickupArea:
			return node
		node = node.get_parent()
	return null

func _update_action_progress(delta: float) -> void:
	if _focused_action and Input.is_action_pressed("Interaction"):
		_action_progress = minf(_action_progress + delta / _focused_action.duration, 1.0)
		hud.set_action_progress(_action_progress)
		if _action_progress >= 1.0:
			var action := _focused_action
			_reset_action_progress()
			action.on_complete.call()
			spend_stamina(action.stamina_cost)
	elif _action_progress > 0.0:
		_reset_action_progress()

func spend_stamina(amount: float) -> void:
	stamina = clampf(stamina - amount, 0.0, MAX_STAMINA)
	_sync_stamina_hud()

func restore_stamina(amount: float) -> void:
	stamina = clampf(stamina + amount, 0.0, MAX_STAMINA)
	_sync_stamina_hud()

func _sync_stamina_hud() -> void:
	hud.set_stamina(stamina)

func _reset_action_progress() -> void:
	_action_progress = 0.0
	hud.set_action_progress(-1.0)
