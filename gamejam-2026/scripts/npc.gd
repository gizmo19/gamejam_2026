class_name Npc
extends CharacterBody3D

enum State {WALKING_TO_BAR, WAITING_IN_QUEUE, WAITING_AT_BAR, WALKING_TO_TABLE, SEATED, LEAVING}
enum Order {CHICKEN, SOUP, BEER}

const GRAVITY: float = 9.8
const BAR_WAIT_TIME: float = 20.0
const TABLE_WAIT_TIME: float = 45.0
const TAKE_ORDER_TIME: float = 0.5

const WALK_SPEED: float = 1.5

@onready var mover: NpcMover = $Mover
@onready var interaction: NpcInteraction = $Interaction
@onready var state_timer: Timer = $StateTimer
@onready var countdown_label: Label3D = $CountdownLabel
@onready var state_label: Label3D = $StateLabel

var _time_left: float = 0.0
var _order_taken: bool = false
var _pending_ducats: int = 0
var _eating_finished: bool = false

signal order_given
signal needs_table(npc: Npc)
signal patience_expired(npc: Npc)
signal queue_slot_reached(npc: Npc)

var state: State
var order: Order
var target_table: Table
var was_served: bool = false

func order_label() -> String:
	match order:
		Order.CHICKEN: return "Kurczak"
		Order.SOUP: return "Zupa"
		Order.BEER: return "Piwo"
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
	_order_taken = false

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
	set_interactable(false)
	set_state(State.WALKING_TO_TABLE)
	mover.move_along(waypoints)

func get_look_action(_player: Node) -> LookAction:
	if state == State.WAITING_AT_BAR and not _order_taken:
		return LookAction.create(TAKE_ORDER_TIME, func() -> void:
			_take_order()
		, 0.0)
	return null

func _take_order() -> void:
	_order_taken = true
	_time_left = -1.0
	order_given.emit()
	countdown_label.text = order_label()
	countdown_label.visible = true
	state_timer.start(3.0)

func _ready() -> void:
	order = [Order.CHICKEN, Order.SOUP, Order.BEER].pick_random()
	mover.navigation_finished.connect(_on_arrived)
	interaction.interaction_requested.connect(_on_order_taken)
	state_timer.timeout.connect(_on_timer_timeout)

func _process(delta: float) -> void:
	match state:
		State.WAITING_AT_BAR:
			if _order_taken:
				pass
			elif _time_left > 0.0:
				_time_left = maxf(_time_left - delta, 0.0)
				if _time_left == 0.0:
					patience_expired.emit(self)
				countdown_label.text = "%d" % ceili(_time_left)
				countdown_label.visible = true
			else:
				countdown_label.visible = false
		State.SEATED:
			if was_served:
				pass
			elif _time_left > 0.0:
				_time_left = maxf(_time_left - delta, 0.0)
				if _time_left == 0.0:
					patience_expired.emit(self)
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

	velocity.x = v.x * WALK_SPEED
	velocity.z = v.z * WALK_SPEED
	move_and_slide()

func _on_arrived() -> void:
	if state == State.WALKING_TO_BAR:
		queue_slot_reached.emit(self)
	elif state == State.WALKING_TO_TABLE:
		set_state(State.SEATED)
		_time_left = TABLE_WAIT_TIME
		if target_table:
			target_table.is_occupied = true
			target_table.assign_customer(self)
	elif state == State.LEAVING:
		queue_free()

func accept_delivery() -> void:
	var wait_time := TABLE_WAIT_TIME - _time_left
	_pending_ducats = 3 if wait_time < 15.0 else (2 if wait_time < 30.0 else 1)
	countdown_label.visible = false
	was_served = true
	_time_left = -1.0
	state_timer.start(_eating_duration())

func _eating_duration() -> float:
	match order:
		Order.SOUP: return 12.0
		Order.BEER: return 8.0
		Order.CHICKEN: return 18.0
	return 10.0

func _on_order_taken() -> void:
	if state == State.WAITING_AT_BAR and not _order_taken:
		_take_order()

func _on_timer_timeout() -> void:
	if state == State.WAITING_AT_BAR:
		needs_table.emit(self)
	elif state == State.SEATED:
		if was_served and not _eating_finished:
			_eating_finished = true
			ScoreState.record_ducats(_pending_ducats)
			countdown_label.text = "+%d dukatów" % _pending_ducats
			countdown_label.visible = true
			# Free the seat immediately on pay; NPC still walks out after the tip display.
			if target_table:
				target_table.vacate()
			state_timer.start(2.0)
		else:
			patience_expired.emit(self)
