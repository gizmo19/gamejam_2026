extends Node3D

const NPC_SCENE: PackedScene = preload("res://scenes/npc.tscn")

@onready var tables: Node3D = $Tables
@onready var bar: StaticBody3D = $Bar
@onready var npc_spawn_point: Marker3D = $NpcSpawnPoint
@onready var _bar_queue: BarQueue = $BarQueue
@onready var _npc_spawn_manager: NpcSpawnManager = $NpcSpawnManager

func _ready() -> void:
	_bar_queue.setup(bar)
	_npc_spawn_manager.setup(_bar_queue)
	_npc_spawn_manager.spawn_requested.connect(_spawn_npc)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("SpawnNpc"):
		_spawn_npc()

func _spawn_npc() -> void:
	var npc: Npc = NPC_SCENE.instantiate()
	add_child(npc)
	npc.global_position = npc_spawn_point.global_position
	npc.needs_table.connect(_provide_table)
	npc.patience_expired.connect(_on_patience_expired)
	npc.order_given.connect(func(): print("Order collected!"))
	npc.queue_slot_reached.connect(_on_queue_slot_reached)
	npc.setup(_bar_queue.slot_position(_bar_queue.size()))
	_bar_queue.append(npc)

func _on_queue_slot_reached(npc: Npc) -> void:
	if _bar_queue.is_empty() or not _bar_queue.has(npc):
		return
	if _bar_queue.get_npc(0) == npc:
		npc.begin_ordering()
	else:
		npc.wait_in_queue()

func _on_patience_expired(npc: Npc) -> void:
	if not npc.was_served:
		if npc.target_table:
			ScoreState.record_left_at_table()
		else:
			ScoreState.record_left_unserved()

	_bar_queue.erase(npc)
	var exit_pos := npc_spawn_point.global_position
	var waypoints: Array[Vector3] = []

	if npc.target_table:
		npc.target_table.is_occupied = false
		npc.target_table.clear_customer()
		npc.target_table.set_dirty(true)
		ScoreState.record_table_left_dirty()
		npc.target_table = null
		_print_matrix()
		var x_sign: float = sign(npc.global_position.x)
		waypoints.append(Vector3(x_sign * 1.5, exit_pos.y, npc.global_position.z))
		waypoints.append(exit_pos)
	else:
		waypoints.append(exit_pos)

	npc.leave(waypoints)

func _provide_table(npc: Npc) -> void:
	_bar_queue.erase(npc)

	var available: Array[Table] = []
	for node in tables.get_children():
		var table := node as Table
		if table == null or table.is_occupied or table.is_dirty:
			continue
		available.append(table)

	if available.is_empty():
		return

	var table: Table = available.pick_random()
	table.is_occupied = true
	var notation := _node_to_notation(table.name)
	print("NPC sits: %s(%d,%d) [%s]" % [notation.side, notation.i, notation.j, npc.order_label()])
	var x_sign: float = sign(table.global_position.x)
	var seat: Vector3 = table.global_position + Vector3(x_sign * 0.5, 0, -1)
	var alley_x: float = x_sign * 1.5
	var y: float = seat.y

	npc.go_to_table(table, [
		Vector3(alley_x, y, -3.0),
		Vector3(alley_x, y, seat.z),
		seat,
	])
	_print_matrix()

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
