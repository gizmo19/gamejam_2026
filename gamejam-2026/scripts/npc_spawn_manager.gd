class_name NpcSpawnManager
extends Node

## Emits when an NPC should be created. Main handles instantiation and wiring.
signal spawn_requested
## Emits when all scheduled customers for today have been spawned.
signal all_customers_spawned

## Fixed number of customers per day. Index 0 = day 1.
# @export var customers_per_day: Array[int] = [3, 5, 7, 10, 12]
@export var customers_per_day: Array[int] = [3, 5, 7, 10, 12] # Debugging
## Index 0 = day 1. Days past the last entry reuse the final values.
@export var interval_min_by_day: Array[float] = [6.0, 6.0, 5.0, 4.0]
@export var interval_max_by_day: Array[float] = [16.0, 12.0, 10.0, 8.0]
## Cap how many NPCs may wait at the bar before new spawns are skipped.
@export var max_in_queue_by_day: Array[int] = [3, 3, 5, 10]
@export var initial_delay_seconds: float = 1.5

var _bar_queue: BarQueue
var _timer: float = 0.0
var _next_interval: float = 0.0
var _spawning: bool = false
var _spawned_today: int = 0

func setup(bar_queue: BarQueue) -> void:
	_bar_queue = bar_queue

func _ready() -> void:
	ScoreState.phase_changed.connect(_on_phase_changed)
	if ScoreState.phase == ScoreState.Phase.NOON:
		_start_spawning()

func _process(delta: float) -> void:
	if not _spawning:
		return
	_timer += delta
	if _timer < _next_interval:
		return
	_timer = 0.0
	_try_spawn()
	_roll_next_interval()

func _on_phase_changed(phase: ScoreState.Phase) -> void:
	if phase == ScoreState.Phase.NOON:
		_start_spawning()
	else:
		_stop_spawning()

func _start_spawning() -> void:
	_spawning = true
	_spawned_today = 0
	_timer = 0.0
	_next_interval = initial_delay_seconds

func _stop_spawning() -> void:
	_spawning = false
	_timer = 0.0
	_next_interval = 0.0

func _try_spawn() -> void:
	if _spawned_today >= _count_for_day():
		all_customers_spawned.emit()
		_stop_spawning()
		return
	if _bar_queue != null and _bar_queue.size() >= _int_for_day(max_in_queue_by_day, 4):
		return
	spawn_requested.emit()
	_spawned_today += 1
	if _spawned_today >= _count_for_day():
		all_customers_spawned.emit()
		_stop_spawning()

func _roll_next_interval() -> void:
	var min_i := _float_for_day(interval_min_by_day, 10.0)
	var max_i := _float_for_day(interval_max_by_day, 18.0)
	if max_i < min_i:
		max_i = min_i
	_next_interval = randf_range(min_i, max_i)

func _count_for_day() -> int:
	return _int_for_day(customers_per_day, 5)

func _float_for_day(values: Array[float], fallback: float) -> float:
	if values.is_empty():
		return fallback
	return values[clampi(ScoreState.day - 1, 0, values.size() - 1)]

func _int_for_day(values: Array[int], fallback: int) -> int:
	if values.is_empty():
		return fallback
	return values[clampi(ScoreState.day - 1, 0, values.size() - 1)]
