class_name Npc
extends CharacterBody3D

enum State { WALKING_TO_BAR, WAITING_AT_BAR, WALKING_TO_TABLE, SEATED, LEAVING }
enum Order { CHICKEN, SOUP, BEER }

const GRAVITY: float = 9.8
const BAR_WAIT_TIME: float = 20.0
const TABLE_WAIT_TIME: float = 45.0

@onready var mover: NpcMover = $Mover
@onready var interaction: NpcInteraction = $Interaction
@onready var state_timer: Timer = $StateTimer
@onready var countdown_label: Label3D = $CountdownLabel

var _time_left: float = 0.0

signal order_given
signal needs_table(npc: Npc)
signal patience_expired(npc: Npc)

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
	if state == State.WALKING_TO_BAR:
		mover.move_to(new_pos)

func set_interactable(value: bool) -> void:
	interaction.enabled = value

func leave(waypoints: Array[Vector3]) -> void:
	state = State.LEAVING
	mover.move_along(waypoints)

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

func _process(delta: float) -> void:
	match state:
		State.WAITING_AT_BAR:
			if _time_left > 0.0:
				_time_left = maxf(_time_left - delta, 0.0)
				if _time_left == 0.0:
					patience_expired.emit(self)
			if interaction.enabled:
				countdown_label.text = "%s\n%d" % [order_label(), ceili(_time_left)]
			else:
				countdown_label.text = "%d" % ceili(_time_left)
			countdown_label.visible = true
		State.SEATED:
			if _time_left > 0.0:
				_time_left = maxf(_time_left - delta, 0.0)
				if _time_left == 0.0:
					patience_expired.emit(self)
			countdown_label.text = "%s\n%d" % [order_label(), ceili(_time_left)]
			countdown_label.visible = true
		_:
			countdown_label.visible = false

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	else:
		velocity.y = 0.0

	var v := Vector3.ZERO
	if state == State.WALKING_TO_BAR or state == State.WALKING_TO_TABLE or state == State.LEAVING:
		v = mover.get_velocity(global_position, delta)

	if v.length() > 0.1:
		look_at(global_position + v, Vector3.UP)

	velocity.x = v.x
	velocity.z = v.z
	move_and_slide()

func _on_arrived() -> void:
	if state == State.WALKING_TO_BAR:
		state = State.WAITING_AT_BAR
		_time_left = BAR_WAIT_TIME
	elif state == State.WALKING_TO_TABLE:
		state = State.SEATED
		_time_left = TABLE_WAIT_TIME
		if target_table:
			target_table.is_occupied = true
	elif state == State.LEAVING:
		queue_free()

func _on_order_taken() -> void:
	if state == State.WAITING_AT_BAR:
		order_given.emit()
		state_timer.start(1.0)

func _on_timer_timeout() -> void:
	if state == State.WAITING_AT_BAR:
		needs_table.emit(self)
