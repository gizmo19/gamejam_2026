extends Node

enum Phase {MORNING, NOON, NIGHT}

const PHASE_DURATIONS: Dictionary = {
	Phase.MORNING: - 1.0,
	Phase.NOON: - 1.0,
	Phase.NIGHT: - 1.0,
}

const PHASE_NAMES: Dictionary = {
	Phase.MORNING: "Morning",
	Phase.NOON: "Noon",
	Phase.NIGHT: "Night",
}

signal changed
signal phase_changed(phase: Phase)
signal day_changed(day: int)
signal crowns_changed(total: int)
signal customer_rush_requested(count: int)
signal customers_all_arrived
signal customers_all_done
signal tavern_closed
signal game_ended
signal screen_fade_in
signal screen_fade_out

var served: int = 0
var left_at_table: int = 0
var left_unserved: int = 0
var tables_cleaned: int = 0
var tables_left_dirty: int = 0
var secret_found: bool = false

const INIT_CROWNS: int = 53
const RUSH_CROWN_THRESHOLD: int = 90
const WIN_CROWN_THRESHOLD: int = 100
const RUSH_CUSTOMER_COUNT: int = 7
var total_crowns: int = INIT_CROWNS
var game_over: bool = false
var all_customers_arrived: bool = false
var all_customers_done: bool = false
var _customer_rush_triggered: bool = false
var _customer_rush_pending: bool = false

var day: int = 1
var phase: Phase = Phase.MORNING
var phase_elapsed: float = 0.0

var _transition_timer: float = -1.0

func _ready() -> void:
	_start_phase(Phase.MORNING, false)

func _process(delta: float) -> void:
	var duration: float = PHASE_DURATIONS[phase]
	if duration >= 0.0:
		phase_elapsed += delta
		if phase_elapsed >= duration:
			_advance_phase()

	if _transition_timer > 0.0:
		_transition_timer -= delta
		if _transition_timer <= 0.0:
			_transition_timer = -1.0
			advance_day()
			screen_fade_out.emit()

func get_phase_name() -> String:
	return PHASE_NAMES[phase]

func get_phase_duration() -> float:
	return PHASE_DURATIONS[phase]

func get_phase_time_remaining() -> float:
	var duration: float = PHASE_DURATIONS[phase]
	if duration < 0.0:
		return -1.0
	return maxf(0.0, duration - phase_elapsed)

func format_phase_time() -> String:
	var remaining := get_phase_time_remaining()
	if remaining < 0.0:
		return "--:--"
	var total_seconds := int(ceil(remaining))
	var minutes := total_seconds / 60
	var seconds := total_seconds % 60
	return "%d:%02d" % [minutes, seconds]

func record_served() -> void:
	served += 1
	changed.emit()

func record_left_at_table() -> void:
	left_at_table += 1
	changed.emit()

func record_left_unserved() -> void:
	left_unserved += 1
	changed.emit()

func record_table_cleaned() -> void:
	tables_cleaned += 1
	changed.emit()

func record_table_left_dirty() -> void:
	tables_left_dirty += 1
	changed.emit()

func record_secret_found() -> void:
	if secret_found:
		return
	secret_found = true
	changed.emit()

func record_crowns(amount: int) -> void:
	var previous := total_crowns
	total_crowns += amount
	crowns_changed.emit(total_crowns)
	changed.emit()
	if not _customer_rush_triggered \
			and previous <= RUSH_CROWN_THRESHOLD \
			and total_crowns > RUSH_CROWN_THRESHOLD:
		_customer_rush_triggered = true
		# Too late today once the last scheduled customer has arrived — do it first thing tomorrow.
		if all_customers_arrived or phase != Phase.NOON:
			_customer_rush_pending = true
		else:
			customer_rush_requested.emit(RUSH_CUSTOMER_COUNT)

func mark_all_customers_arrived() -> void:
	all_customers_arrived = true
	customers_all_arrived.emit()
	changed.emit()

func mark_all_customers_done() -> void:
	all_customers_done = true
	customers_all_done.emit()
	changed.emit()

func close_tavern() -> void:
	tavern_closed.emit()
	_start_phase(Phase.NIGHT, true)

func start_day_transition() -> void:
	if phase != Phase.NIGHT:
		return
	screen_fade_in.emit()
	_transition_timer = 1.5

func reset() -> void:
	served = 0
	left_at_table = 0
	left_unserved = 0
	tables_cleaned = 0
	tables_left_dirty = 0
	secret_found = false
	total_crowns = INIT_CROWNS
	all_customers_arrived = false
	all_customers_done = false
	_customer_rush_triggered = false
	_customer_rush_pending = false
	game_over = false
	_transition_timer = -1.0
	day = 1
	_start_phase(Phase.MORNING, true)
	day_changed.emit(day)
	changed.emit()

func advance_day() -> void:
	all_customers_arrived = false
	all_customers_done = false
	day += 1
	_start_phase(Phase.MORNING, true)
	day_changed.emit(day)
	changed.emit()

func open_for_business() -> void:
	if phase != Phase.MORNING or game_over:
		return
	_start_phase(Phase.NOON, true)
	_flush_pending_customer_rush()

func end_game() -> void:
	if game_over:
		return
	game_over = true
	game_ended.emit()
	reset()

func _flush_pending_customer_rush() -> void:
	if not _customer_rush_pending:
		return
	_customer_rush_pending = false
	customer_rush_requested.emit(RUSH_CUSTOMER_COUNT)

func _advance_phase() -> void:
	match phase:
		Phase.MORNING:
			pass
		Phase.NOON:
			_start_phase(Phase.NIGHT, true)
		Phase.NIGHT:
			pass

func _start_phase(next_phase: Phase, _emit_signal: bool) -> void:
	phase = next_phase
	phase_elapsed = 0.0
	if _emit_signal:
		phase_changed.emit(phase)
