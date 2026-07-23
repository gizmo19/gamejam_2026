extends Node

enum Phase {MORNING, NOON, NIGHT}

const PHASE_DURATIONS: Dictionary = {
	Phase.MORNING: - 1.0,
	Phase.NOON: 60.0,
	Phase.NIGHT: - 1.0, # endless for now
}

const PHASE_NAMES: Dictionary = {
	Phase.MORNING: "Morning",
	Phase.NOON: "Noon",
	Phase.NIGHT: "Night",
}

signal changed
signal phase_changed(phase: Phase)
signal day_changed(day: int)

var served: int = 0
var left_at_table: int = 0
var left_unserved: int = 0
var tables_cleaned: int = 0
var tables_left_dirty: int = 0

var day: int = 1
var phase: Phase = Phase.MORNING
var phase_elapsed: float = 0.0

func _ready() -> void:
	_start_phase(Phase.MORNING, false)

func _process(delta: float) -> void:
	var duration: float = PHASE_DURATIONS[phase]
	if duration < 0.0:
		return
	phase_elapsed += delta
	if phase_elapsed >= duration:
		_advance_phase()

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

func reset() -> void:
	served = 0
	left_at_table = 0
	left_unserved = 0
	tables_cleaned = 0
	tables_left_dirty = 0
	day = 1
	_start_phase(Phase.MORNING, true)
	day_changed.emit(day)
	changed.emit()

func advance_day() -> void:
	day += 1
	_start_phase(Phase.MORNING, true)
	day_changed.emit(day)
	changed.emit()

func open_for_business() -> void:
	if phase != Phase.MORNING:
		return
	_start_phase(Phase.NOON, true)

func _advance_phase() -> void:
	match phase:
		Phase.MORNING:
			pass # endless; call open_for_business() to start noon
		Phase.NOON:
			_start_phase(Phase.NIGHT, true)
		Phase.NIGHT:
			pass # endless for now; call advance_day() when ready

func _start_phase(next_phase: Phase, emit_signal: bool) -> void:
	phase = next_phase
	phase_elapsed = 0.0
	if emit_signal:
		phase_changed.emit(phase)
