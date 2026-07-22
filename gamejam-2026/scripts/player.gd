extends CharacterBody3D

const SPEED: float = 4.0
const SPRINT_SPEED: float = 8.0
const GRAVITY: float = 9.8
const MOUSE_SENSITIVITY: float = 0.002

@onready var camera: Camera3D = $Camera3D

var pitch: float = 0.0
var held_item: int = -1

var _held_label: Label

func _ready() -> void:
	add_to_group("player")
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	_setup_hud()

func _setup_hud() -> void:
	var canvas := CanvasLayer.new()
	add_child(canvas)
	_held_label = Label.new()
	_held_label.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_held_label.offset_top = -60
	_held_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_held_label.add_theme_font_size_override("font_size", 24)
	canvas.add_child(_held_label)

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

	if event.is_action_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= GRAVITY * delta

	var speed: float = SPRINT_SPEED if Input.is_key_pressed(KEY_SHIFT) else SPEED

	var direction := Vector3.ZERO
	if Input.is_key_pressed(KEY_W):
		direction -= transform.basis.z
	if Input.is_key_pressed(KEY_S):
		direction += transform.basis.z
	if Input.is_key_pressed(KEY_A):
		direction -= transform.basis.x
	if Input.is_key_pressed(KEY_D):
		direction += transform.basis.x

	direction.y = 0.0
	if direction.length() > 0:
		direction = direction.normalized()

	velocity.x = direction.x * speed
	velocity.z = direction.z * speed

	move_and_slide()
