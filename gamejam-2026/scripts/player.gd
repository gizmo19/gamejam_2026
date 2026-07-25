extends CharacterBody3D
class_name Player

const SPEED: float = 4.0
const SPRINT_SPEED: float = 8.0
const GRAVITY: float = 9.8
const MOUSE_SENSITIVITY: float = 0.002
const LOOK_SENSITIVITY: float = 2.5
const MAX_STAMINA: float = 100.0
const STEP_WOOD_SFX: AudioStream = preload("res://assets/audio/stepwood_1.wav")
const STEP_INTERVAL_WALK: float = 0.65
const STEP_INTERVAL_SPRINT: float = 0.45
const STEP_INTERVAL_SLOW: float = 0.85
@onready var camera: Camera3D = $Camera3D
@onready var hud: CanvasLayer = $HUD
@onready var interact_ray: RayCast3D = $Camera3D/InteractRay
@onready var _held_item_container: Node3D = $PickedUpItem
@onready var _held_item_visual: Item = $PickedUpItem/Item

signal item_picked_up(type: int)

var pitch: float = 0.0
var held_item: int = -1
var stamina: float = 60.0
var controls_locked: bool = false

var _focused_pickup: PickupArea = null
var _focused_target: Node = null
var _focused_action: LookAction = null
var _action_progress: float = 0.0
var _footstep_player: AudioStreamPlayer
var _footstep_timer: float = 0.0

func _ready() -> void:
	add_to_group("player")
	lock_controls()
	_held_item_container.visible = false
	_sync_stamina_hud()
	ScoreState.day_changed.connect(_on_day_changed)
	_footstep_player = AudioStreamPlayer.new()
	_footstep_player.stream = STEP_WOOD_SFX
	_footstep_player.volume_db = linear_to_db(0.25)
	add_child(_footstep_player)

func lock_controls() -> void:
	controls_locked = true
	velocity.x = 0.0
	velocity.z = 0.0
	_reset_action_progress()
	if _focused_pickup:
		_focused_pickup.set_focused(false)
		_focused_pickup = null
	_focused_target = null
	_focused_action = null
	hud.set_interact_hover(false)
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func unlock_controls() -> void:
	controls_locked = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _on_day_changed(_day: int) -> void:
	stamina = MAX_STAMINA
	_sync_stamina_hud()

func pick_up(type: int) -> void:
	held_item = type
	_held_item_visual.item_type = type as Item.Type
	_held_item_container.visible = true
	item_picked_up.emit(type)

func clear_held_item() -> void:
	held_item = -1
	_held_item_container.visible = false

func _input(event: InputEvent) -> void:
	if controls_locked:
		return
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * MOUSE_SENSITIVITY)
		pitch -= event.relative.y * MOUSE_SENSITIVITY
		pitch = clamp(pitch, -1.4, 1.4)
		camera.rotation.x = pitch


func _physics_process(delta: float) -> void:
	_update_movement(delta)

	move_and_slide()

	_update_footsteps(delta)

	if controls_locked:
		return

	_update_item_interaction()
	_update_interact_focus()
	_update_action_progress(delta)

func _update_movement(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= GRAVITY * delta

	if controls_locked:
		velocity.x = 0.0
		velocity.z = 0.0
		return

	var look := Input.get_vector("LookLeft", "LookRight", "LookUp", "LookDown")
	if look != Vector2.ZERO:
		rotate_y(-look.x * LOOK_SENSITIVITY * delta)
		pitch -= look.y * LOOK_SENSITIVITY * delta
		pitch = clamp(pitch, -1.4, 1.4)
		camera.rotation.x = pitch

	var can_sprint := stamina > 5.0
	var speed: float
	if can_sprint and Input.is_action_pressed("Sprint"):
		speed = SPRINT_SPEED
	elif can_sprint:
		speed = SPEED
	else:
		speed = SPEED * 0.5

	var input_dir := Input.get_vector("Left", "Right", "Forward", "Back")
	var direction := (transform.basis * Vector3(input_dir.x, 0.0, input_dir.y)).normalized()

	velocity.x = direction.x * speed
	velocity.z = direction.z * speed

func _update_footsteps(delta: float) -> void:
	var horizontal_speed := Vector2(velocity.x, velocity.z).length()
	if not is_on_floor() or horizontal_speed < 0.1:
		_footstep_timer = 0.0
		return

	var interval: float
	if horizontal_speed >= SPRINT_SPEED * 0.8:
		interval = STEP_INTERVAL_SPRINT
	elif horizontal_speed >= SPEED * 0.8:
		interval = STEP_INTERVAL_WALK
	else:
		interval = STEP_INTERVAL_SLOW

	_footstep_timer += delta
	if _footstep_timer >= interval:
		_footstep_timer = 0.0
		_footstep_player.play()

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
			# Only focus pickups when they offer a real action (e.g. hands free).
			if candidate is PickupArea and new_action:
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

	var hovering := _focused_action != null or _focused_pickup != null
	var stamina_cost := _focused_action.stamina_cost if _focused_action else 0.0
	hud.set_interact_hover(hovering, stamina_cost)

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
