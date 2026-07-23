class_name BarQueue
extends Node

const BAR_QUEUE_SPACING: float = 0.8

var _queue: Array[Npc] = []
var _bar: Node3D

func setup(bar: Node3D) -> void:
	_bar = bar

func size() -> int:
	return _queue.size()

func is_empty() -> bool:
	return _queue.is_empty()

func has(npc: Npc) -> bool:
	return _queue.has(npc)

func get_npc(idx: int) -> Npc:
	return _queue[idx]

func append(npc: Npc) -> void:
	_queue.append(npc)
	_reposition()

func erase(npc: Npc) -> void:
	if not _queue.has(npc):
		return
	_queue.erase(npc)
	_reposition()

func _pos(idx: int) -> Vector3:
	var base := _bar.global_position
	var offset_x := (idx - (_queue.size() - 1) * 0.5) * BAR_QUEUE_SPACING
	return Vector3(base.x + offset_x, base.y, base.z)

func _reposition() -> void:
	for i in _queue.size():
		_queue[i].update_bar_position(_pos(i))
		_queue[i].set_interactable(i == 0)
	_print_queue()

func _print_queue() -> void:
	if _queue.is_empty():
		print("Bar queue: (empty)")
		return
	var entries: PackedStringArray = []
	for i in _queue.size():
		entries.append("[%d] %s" % [i, _queue[i].order_label()])
	print("Bar queue: ", " | ".join(entries))
