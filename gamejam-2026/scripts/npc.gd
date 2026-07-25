class_name Npc
extends CharacterBody3D

enum State {WALKING_TO_BAR, WAITING_IN_QUEUE, WAITING_AT_BAR, WALKING_TO_TABLE, SEATED, LEAVING}
enum Order {CHICKEN, SOUP, BEER}

const GRAVITY: float = 9.8
const BAR_WAIT_TIME: float = 20.0
const TABLE_WAIT_TIME: float = 45.0
const TAKE_ORDER_TIME: float = 0.5

const WALK_SPEED: float = 1.5
const WALK_TO_BAR_SPEED: float = 1.0

const COIN_DROP_SFX: AudioStream = preload("res://assets/audio/hjm-coindrop_v1.wav")

const SPRITE_MATERIALS: Array[Material] = [
	preload("res://assets/sprites/npc/noblesse.tres"),
	preload("res://assets/sprites/npc/noble.tres"),
	preload("res://assets/sprites/npc/knight.tres"),
	preload("res://assets/sprites/npc/knight_gal.tres"),
	preload("res://assets/sprites/npc/rogue.tres"),
]

@onready var mover: NpcMover = $Mover
@onready var interaction: NpcInteraction = $Interaction
@onready var state_timer: Timer = $StateTimer
@onready var countdown_label: Label3D = $CountdownLabel
@onready var state_label: Label3D = $StateLabel
@onready var sprite: MeshInstance3D = $Sprite
var _coin_player: AudioStreamPlayer
@onready var item_bubble: ItemBubble = %ItemBubble

var _time_left: float = 0.0
var _order_taken: bool = false
var _pending_ducats: int = 0
var _eating_finished: bool = false
var _last_countdown: int = -1

signal order_given
signal needs_table(npc: Npc)
signal patience_expired(npc: Npc)
signal queue_slot_reached(npc: Npc)
signal left_tavern

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
	match new_state:
		State.WALKING_TO_BAR, State.WAITING_IN_QUEUE, State.WAITING_AT_BAR:
			collision_mask = 5
		_:
			collision_mask = 1

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
	_last_countdown = -1

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
	_set_countdown_visible(false)
	item_bubble.show_item(order as Item.Type)
	state_timer.start(3.0)

func _ready() -> void:
	order = [Order.CHICKEN, Order.SOUP, Order.BEER].pick_random()
	sprite.material_override = SPRITE_MATERIALS.pick_random()
	mover.navigation_finished.connect(_on_arrived)
	interaction.interaction_requested.connect(_on_order_taken)
	state_timer.timeout.connect(_on_timer_timeout)
	_coin_player = AudioStreamPlayer.new()
	_coin_player.stream = COIN_DROP_SFX
	add_child(_coin_player)

func _process(delta: float) -> void:
	match state:
		State.WAITING_AT_BAR:
			if _order_taken:
				# Leave the post-order reveal from _take_order() alone until state_timer fires.
				pass
			elif _time_left > 0.0:
				_time_left = maxf(_time_left - delta, 0.0)
				if _time_left == 0.0:
					patience_expired.emit(self)
				_set_countdown_visible(true)
				item_bubble.hide_item()
				var n := ceili(_time_left)
				if n != _last_countdown:
					_last_countdown = n
					countdown_label.text = "%d" % n
			else:
				_set_countdown_visible(false)
				item_bubble.hide_item()
		State.SEATED:
			if was_served:
				if not _eating_finished:
					_set_countdown_visible(false)
					item_bubble.hide_item()
			elif _time_left > 0.0:
				_time_left = maxf(_time_left - delta, 0.0)
				if _time_left == 0.0:
					patience_expired.emit(self)
				_set_countdown_visible(true)
				item_bubble.show_item(order as Item.Type)
				var n := ceili(_time_left)
				if n != _last_countdown:
					_last_countdown = n
					countdown_label.text = "%d" % n
			else:
				_set_countdown_visible(false)
				item_bubble.hide_item()
		_:
			_set_countdown_visible(false)
			item_bubble.hide_item()

func _set_countdown_visible(_visible: bool) -> void:
	if countdown_label.visible != _visible:
		countdown_label.visible = _visible

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

	var speed := WALK_TO_BAR_SPEED if state == State.WALKING_TO_BAR else WALK_SPEED
	velocity.x = v.x * speed
	velocity.z = v.z * speed
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
		left_tavern.emit()
		queue_free()

func accept_delivery() -> void:
	var wait_time := TABLE_WAIT_TIME - _time_left
	_pending_ducats = 3 if wait_time < 15.0 else (2 if wait_time < 30.0 else 1)
	_set_countdown_visible(false)
	item_bubble.hide_item()
	was_served = true
	_time_left = -1.0
	state_timer.start(_eating_duration())

func _eating_duration() -> float:
	var duration: float
	match order:
		Order.SOUP: duration = 12.0
		Order.BEER: duration = 8.0
		Order.CHICKEN: duration = 18.0
		_: duration = 10.0
	if _is_last_customer_of_day():
		duration *= 0.2
	return duration

func _is_last_customer_of_day() -> bool:
	if not ScoreState.all_customers_arrived:
		return false
	var count := 0
	for sibling in get_parent().get_children():
		if sibling is Npc:
			count += 1
			if count > 1:
				return false
	return true

func _on_order_taken() -> void:
	if state == State.WAITING_AT_BAR and not _order_taken:
		_take_order()

func _on_timer_timeout() -> void:
	if state == State.WAITING_AT_BAR:
		needs_table.emit(self)
	elif state == State.SEATED:
		if was_served and not _eating_finished:
			_eating_finished = true
			_coin_player.play()
			ScoreState.record_ducats(_pending_ducats)
			countdown_label.text = "+%d dukatów" % _pending_ducats
			countdown_label.visible = true
			# Free the seat immediately on pay; NPC still walks out after the tip display.
			if target_table:
				target_table.vacate()
			state_timer.start(2.0)
		else:
			patience_expired.emit(self)
