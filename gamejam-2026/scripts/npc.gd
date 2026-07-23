class_name Npc
extends CharacterBody3D

enum State {WALKING_TO_BAR, WAITING_IN_QUEUE, WAITING_AT_BAR, WALKING_TO_TABLE, SEATED, LEAVING}
enum Order {CHICKEN, SOUP, BEER}

const GRAVITY: float = 9.8
const BAR_WAIT_TIME: float = 20.0
const TABLE_WAIT_TIME: float = 45.0

@onready var mover: NpcMover = $Mover
@onready var interaction: NpcInteraction = $Interaction
@onready var state_timer: Timer = $StateTimer
@onready var countdown_label: Label3D = $CountdownLabel
@onready var state_label: Label3D = $StateLabel

var _time_left: float = 0.0

signal order_given
signal needs_table(npc: Npc)
signal timer_expired(npc: Npc)
signal queue_slot_reached(npc: Npc)
signal serve_requested(npc: Npc)

var state: State
var order: Order
var target_table: Table

func order_label() -> String:
	match order:
		Order.CHICKEN: return "Chicken"
		Order.SOUP: return "Soup"
		Order.BEER: return "Beer"
	return "?"

func set_state(new_state: State) -> void:
	state = new_state
	state_label.text = State.find_key(new_state)

func setup(bar_pos: Vector3) -> void:
	set_state(State.WALKING_TO_BAR)
	mover.move_to(bar_pos)

func update_bar_position(new_pos: Vector3) -> void:
	if state != State.WALKING_TO_BAR and state != State.WAITING_IN_QUEUE:
		return
	var offset := new_pos - global_position
	offset.y = 0.0
	if state == State.WAITING_IN_QUEUE and offset.length() < NpcMover.ARRIVE_DIST:
		return
	set_state(State.WALKING_TO_BAR)
	mover.move_to(new_pos)

func begin_ordering() -> void:
	set_state(State.WAITING_AT_BAR)
	_time_left = BAR_WAIT_TIME
	set_interactable(true)

func wait_in_queue() -> void:
	set_state(State.WAITING_IN_QUEUE)
	_time_left = 0.0
	set_interactable(false)

func set_interactable(value: bool) -> void:
	interaction.enabled = value

func leave(waypoints: Array[Vector3]) -> void:
	set_state(State.LEAVING)
	mover.move_along(waypoints)

func go_to_table(table: Table, waypoints: Array[Vector3]) -> void:
	target_table = table
	set_state(State.WALKING_TO_TABLE)
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
					timer_expired.emit(self)
			if interaction.enabled:
				countdown_label.text = "%s\n%d" % [order_label(), ceili(_time_left)]
			else:
				countdown_label.text = "%d" % ceili(_time_left)
			countdown_label.visible = true
		State.SEATED:
			if _time_left > 0.0:
				_time_left = maxf(_time_left - delta, 0.0)
				if _time_left == 0.0:
					timer_expired.emit(self)
				countdown_label.text = "%s\n%d" % [order_label(), ceili(_time_left)]
				countdown_label.visible = true
			else:
				countdown_label.visible = false
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
		queue_slot_reached.emit(self)
	elif state == State.WALKING_TO_TABLE:
		set_state(State.SEATED)
		_time_left = TABLE_WAIT_TIME
		if target_table:
			target_table.is_occupied = true
	elif state == State.LEAVING:
		queue_free()

func accept_delivery() -> void:
	_time_left = -1.0
	state_timer.start(2.0)

func _on_order_taken() -> void:
	if state == State.WAITING_AT_BAR:
		order_given.emit()
		state_timer.start(1.0)
	elif state == State.SEATED:
		serve_requested.emit(self)

func _on_timer_timeout() -> void:
	if state == State.WAITING_AT_BAR:
		needs_table.emit(self)
	elif state == State.SEATED:
		timer_expired.emit(self)
