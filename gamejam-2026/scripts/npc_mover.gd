class_name NpcMover
extends Node

signal navigation_finished

const SPEED: float = 2.5
const ARRIVE_DIST: float = 0.5
const STUCK_TIME_MAX: float = 0.3

var is_moving: bool = false

var _waypoints: Array[Vector3] = []
var _prev_pos: Vector3
var _stuck_time: float = 0.0

func move_to(pos: Vector3) -> void:
	_waypoints = [pos]
	is_moving = true
	_stuck_time = 0.0

func move_along(waypoints: Array[Vector3]) -> void:
	_waypoints = waypoints.duplicate()
	is_moving = not _waypoints.is_empty()
	_stuck_time = 0.0

func stop() -> void:
	is_moving = false
	_waypoints.clear()

func get_velocity(from: Vector3, delta: float) -> Vector3:
	if not is_moving or _waypoints.is_empty():
		return Vector3.ZERO

	var target := _waypoints[0]
	var dir := target - from
	dir.y = 0.0

	if dir.length() < ARRIVE_DIST:
		_waypoints.pop_front()
		_stuck_time = 0.0
		if _waypoints.is_empty():
			_arrive()
		return Vector3.ZERO

	if (from - _prev_pos).length() < 0.005:
		_stuck_time += delta
		if _stuck_time >= STUCK_TIME_MAX:
			_waypoints.pop_front()
			_stuck_time = 0.0
			if _waypoints.is_empty():
				_arrive()
			return Vector3.ZERO
	else:
		_stuck_time = 0.0

	_prev_pos = from
	return dir.normalized() * SPEED

func _arrive() -> void:
	is_moving = false
	navigation_finished.emit()
