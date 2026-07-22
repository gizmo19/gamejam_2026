class_name NpcMover
extends Node

signal navigation_finished

const SPEED: float = 2.5
const ARRIVE_DIST: float = 0.5
const STUCK_TIME_MAX: float = 0.3

var target: Vector3
var is_moving: bool = false

var _prev_pos: Vector3
var _stuck_time: float = 0.0

func move_to(pos: Vector3) -> void:
	target = pos
	is_moving = true
	_stuck_time = 0.0

func stop() -> void:
	is_moving = false

func get_velocity(from: Vector3, delta: float) -> Vector3:
	if not is_moving:
		return Vector3.ZERO

	var dir := target - from
	dir.y = 0.0

	if dir.length() < ARRIVE_DIST:
		_arrive()
		return Vector3.ZERO

	if (from - _prev_pos).length() < 0.005:
		_stuck_time += delta
		if _stuck_time >= STUCK_TIME_MAX:
			_arrive()
			return Vector3.ZERO
	else:
		_stuck_time = 0.0

	_prev_pos = from
	return dir.normalized() * SPEED

func _arrive() -> void:
	is_moving = false
	navigation_finished.emit()
