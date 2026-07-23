extends CharacterBody3D

const SPEED: float = 4.0
const SPRINT_SPEED: float = 8.0
const GRAVITY: float = 9.8
const MOUSE_SENSITIVITY: float = 0.002
const LOOK_SENSITIVITY: float = 2.5

@onready var camera: Camera3D = $Camera3D
@onready var _held_label: Label = $HUD/HeldLabel
@onready var interact_ray: RayCast3D = $Camera3D/InteractRay

var pitch: float = 0.0
var held_item: int = -1

var _focused_pickup: PickupArea = null

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

func _update_interact_focus() -> void:
	var new_focus: PickupArea = null
	if interact_ray.is_colliding():
		var collider := interact_ray.get_collider()
		if collider:
			var parent: Node = collider.get_parent()
			if parent is PickupArea:
				new_focus = parent as PickupArea
	if new_focus == _focused_pickup:
		return
	if _focused_pickup:
		_focused_pickup.set_focused(false)
	_focused_pickup = new_focus
	if _focused_pickup:
		_focused_pickup.set_focused(true)
