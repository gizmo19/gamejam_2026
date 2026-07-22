extends Node3D

const NPC_SCENE: PackedScene = preload("res://scenes/npc.tscn")
const BAR_QUEUE_SPACING: float = 0.8

@onready var tables: Node3D = $Tables
@onready var bar: StaticBody3D = $Bar
@onready var npc_spawn_point: Marker3D = $NpcSpawnPoint

var _bar_queue: Array[Npc] = []

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey \
			and event.keycode == KEY_G \
			and event.pressed \
			and not event.echo:
		_spawn_npc()

func _spawn_npc() -> void:
	var npc: Npc = NPC_SCENE.instantiate()
	add_child(npc)
	npc.global_position = npc_spawn_point.global_position
	npc.needs_table.connect(_provide_table)
	npc.patience_expired.connect(_on_patience_expired)
	npc.order_given.connect(func(): print("Order collected!"))
	_bar_queue.append(npc)
	npc.setup(bar.global_position)
	_reposition_bar_queue()
	_print_bar_queue()

func _print_bar_queue() -> void:
	if _bar_queue.is_empty():
		print("Bar queue: (empty)")
		return
	var entries: PackedStringArray = []
	for i in _bar_queue.size():
		entries.append("[%d] %s" % [i, _bar_queue[i].order_label()])
	print("Bar queue: ", " | ".join(entries))

func _bar_queue_pos(idx: int) -> Vector3:
	var base := bar.global_position
	var offset_x := (idx - (_bar_queue.size() - 1) * 0.5) * BAR_QUEUE_SPACING
	return Vector3(base.x + offset_x, base.y, base.z)

func _reposition_bar_queue() -> void:
	for i in _bar_queue.size():
		_bar_queue[i].update_bar_position(_bar_queue_pos(i))
		_bar_queue[i].set_interactable(i == 0)

func _on_patience_expired(npc: Npc) -> void:
	if _bar_queue.has(npc):
		_bar_queue.erase(npc)
		_reposition_bar_queue()
		_print_bar_queue()
	var exit_pos := npc_spawn_point.global_position
	var waypoints: Array[Vector3] = []
	if npc.target_table:
		npc.target_table.is_occupied = false
		npc.target_table = null
		_print_matrix()
		var x_sign: float = sign(npc.global_position.x)
		waypoints.append(Vector3(x_sign * 0.8, exit_pos.y, npc.global_position.z))
		waypoints.append(exit_pos)
	else:
		waypoints.append(exit_pos)
	npc.leave(waypoints)

func _provide_table(npc: Npc) -> void:
	_bar_queue.erase(npc)
	_reposition_bar_queue()
	_print_bar_queue()
	for node in tables.get_children():
		var table := node as Table
		if table == null or table.is_occupied:
			continue
		table.is_occupied = true
		var notation := _node_to_notation(table.name)
		print("NPC sits: %s(%d,%d) [%s]" % [notation.side, notation.i, notation.j, npc.order_label()])
		var x_sign: float = sign(table.global_position.x)
		var seat: Vector3 = table.global_position + Vector3(x_sign * 0.5, 0, -1)
		var alley_x: float = x_sign * 0.8
		var y: float = seat.y
		npc.go_to_table(table, [
			Vector3(alley_x, y, -3.0),
			Vector3(alley_x, y, seat.z),
			seat,
		])
		_print_matrix()
		return

func _node_to_notation(node_name: String) -> Dictionary:
	var p := node_name.split("_")
	return {"side": p[0], "i": int(p[1]), "j": int(p[2])}

func _print_matrix() -> void:
	var state := {}
	for node in tables.get_children():
		var table := node as Table
		if table == null:
			continue
		var n := _node_to_notation(table.name)
		var key := "%s_%d_%d" % [n.side, n.i, n.j]
		state[key] = table.is_occupied

	print("=== Tables ===  (X = occupied)")
	for side in ["L", "R"]:
		var header := "%-6s" % side
		for i in [3, 2, 1]:
			header += "  I=%-2d" % i
		print(header)
		for j in [1, 2]:
			var row := "  J=%-2d" % j
			for i in [3, 2, 1]:
				var key := "%s_%d_%d" % [side, i, j]
				row += "  %-4s" % ("X" if state.get(key, false) else "_")
			print(row)
		print("")
