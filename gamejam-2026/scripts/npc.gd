class_name Npc
extends CharacterBody3D

enum State { WALKING_TO_BAR, WAITING_AT_BAR, WALKING_TO_TABLE, SEATED }
enum Order { CHICKEN, SOUP, BEER }

const GRAVITY: float = 9.8

@onready var mover: NpcMover = $Mover
@onready var interaction: NpcInteraction = $Interaction
@onready var state_timer: Timer = $StateTimer

signal order_given
signal needs_table(npc: Npc)

var state: State
var order: Order
var target_table: Table

func order_label() -> String:
	match order:
		Order.CHICKEN: return "Chicken"
		Order.SOUP: return "Soup"
		Order.BEER: return "Beer"
	return "?"

func setup(bar_pos: Vector3) -> void:
	state = State.WALKING_TO_BAR
	mover.move_to(bar_pos)

func update_bar_position(new_pos: Vector3) -> void:
	if state == State.WALKING_TO_BAR or state == State.WAITING_AT_BAR:
		if state == State.WAITING_AT_BAR:
			state = State.WALKING_TO_BAR
		mover.move_to(new_pos)

func go_to_table(table: Table, waypoints: Array[Vector3]) -> void:
	target_table = table
	state = State.WALKING_TO_TABLE
	collision_layer = 2
	collision_mask = 1
	mover.move_along(waypoints)

func _ready() -> void:
	order = [Order.CHICKEN, Order.SOUP, Order.BEER].pick_random()
	mover.navigation_finished.connect(_on_arrived)
	interaction.interaction_requested.connect(_on_order_taken)
	state_timer.timeout.connect(_on_timer_timeout)

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	else:
		velocity.y = 0.0

	var v := Vector3.ZERO
	if state == State.WALKING_TO_BAR or state == State.WALKING_TO_TABLE:
		v = mover.get_velocity(global_position, delta)

	if v.length() > 0.1:
		look_at(global_position + v, Vector3.UP)

	velocity.x = v.x
	velocity.z = v.z
	move_and_slide()

func _on_arrived() -> void:
	if state == State.WALKING_TO_BAR:
		state = State.WAITING_AT_BAR
	elif state == State.WALKING_TO_TABLE:
		state = State.SEATED
		if target_table:
			target_table.is_occupied = true

func _on_order_taken() -> void:
	if state == State.WAITING_AT_BAR:
		order_given.emit()
		state_timer.start(1.0)

func _on_timer_timeout() -> void:
	if state == State.WAITING_AT_BAR:
		needs_table.emit(self)
