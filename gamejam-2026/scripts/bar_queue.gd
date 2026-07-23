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

func slot_position(idx: int) -> Vector3:
	# bar at z=-3, spawn at z=+5 → queue grows toward +Z
	return _bar.global_position + Vector3(0, 0, idx * BAR_QUEUE_SPACING)

func append(npc: Npc) -> void:
	_queue.append(npc)
	_reposition()

func erase(npc: Npc) -> void:
	if not _queue.has(npc):
		return
	_queue.erase(npc)
	_reposition()

func _reposition() -> void:
	for i in _queue.size():
		var npc: Npc = _queue[i]
		npc.update_bar_position(slot_position(i))
		npc.set_interactable(i == 0 and npc.state == Npc.State.WAITING_AT_BAR)
	_print_queue()

func _print_queue() -> void:
	if _queue.is_empty():
		print("Bar queue: (empty)")
		return
	var entries: PackedStringArray = []
	for i in _queue.size():
		entries.append("[%d] %s" % [i, _queue[i].order_label()])
	print("Bar queue: ", " | ".join(entries))
