extends Node3D

const NPC_SCENE: PackedScene = preload("res://scenes/npc.tscn")

@onready var tables: Node3D = $Tables
@onready var npc_spawn_point: Marker3D = $NpcSpawnPoint
@onready var _bar_queue: BarQueue = $Bar/BarQueue
@onready var _npc_spawn_manager: NpcSpawnManager = $NpcSpawnManager

@onready var _player: CharacterBody3D = $Player
@onready var _tutorial_table_clean: Node3D = $Tutorial/TableClean
@onready var _tutorial_prepare_dish: Node3D = $Tutorial/PrepareDish
@onready var _tutorial_eat: Node3D = $Tutorial/Eat
@onready var _tutorial_open_doors: Node3D = $Tutorial/OpenDoors

var _active_npc_count: int = 0
var _all_spawned: bool = false

func _ready() -> void:
	_npc_spawn_manager.setup(_bar_queue)
	_npc_spawn_manager.spawn_requested.connect(_spawn_npc)
	_npc_spawn_manager.all_customers_spawned.connect(_on_all_customers_spawned)
	ScoreState.tavern_closed.connect(_clear_all_npcs)

	_prepare_tutorial()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ToggleFullscreen"):
		var mode := DisplayServer.window_get_mode()
		if mode == DisplayServer.WINDOW_MODE_FULLSCREEN \
				or mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		else:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

	if event.is_action_pressed("Escape"):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			get_tree().quit()

func _prepare_tutorial() -> void:
	$Tables/L_3_2.cleaned.connect(_dismiss_tutorial_table_clean, CONNECT_ONE_SHOT)
	_player.item_picked_up.connect(_dismiss_tutorial_prepare_dish, CONNECT_ONE_SHOT)
	$Synek.fed.connect(_dismiss_tutorial_eat, CONNECT_ONE_SHOT)
	$Architecture/Entrance.opened.connect(_dismiss_tutorial_open_doors, CONNECT_ONE_SHOT)

func _dismiss_tutorial_table_clean() -> void:
	if is_instance_valid(_tutorial_table_clean):
		_tutorial_table_clean.queue_free()

func _dismiss_tutorial_prepare_dish(_type: int) -> void:
	if is_instance_valid(_tutorial_prepare_dish):
		_tutorial_prepare_dish.queue_free()

func _dismiss_tutorial_eat() -> void:
	if is_instance_valid(_tutorial_eat):
		_tutorial_eat.queue_free()

func _dismiss_tutorial_open_doors() -> void:
	if is_instance_valid(_tutorial_open_doors):
		_tutorial_open_doors.queue_free()

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
	_active_npc_count += 1
	npc.tree_exiting.connect(_on_npc_exiting)

func _on_all_customers_spawned() -> void:
	ScoreState.mark_all_customers_arrived()
	_all_spawned = true
	_check_all_done()

func _on_npc_exiting() -> void:
	if not _all_spawned:
		return
	_active_npc_count = maxi(0, _active_npc_count - 1)
	_check_all_done()

func _check_all_done() -> void:
	if _all_spawned and _active_npc_count <= 0:
		ScoreState.mark_all_customers_done()

func _clear_all_npcs() -> void:
	_all_spawned = false
	_active_npc_count = 0
	var npcs: Array = []
	for child in get_children():
		if child is Npc:
			npcs.append(child)
	while not _bar_queue.is_empty():
		_bar_queue.erase(_bar_queue.get_npc(0))
	for npc in npcs:
		if npc.target_table:
			# Kick mid-service: leave a mess for morning cleanup. Already-vacated
			# (paid) tables are already dirty and must stay that way.
			var table: Table = npc.target_table
			if table.is_occupied or table.customer != null or table.has_food:
				table.vacate()
			npc.target_table = null
		npc.queue_free()
	# Free any stuck occupancy flags; never wipe dirty tables for the next day.
	for table_node in tables.get_children():
		var table := table_node as Table
		if table == null:
			continue
		table.is_occupied = false
		if table.customer != null or table.has_food:
			table.vacate()

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
		var table: Table = npc.target_table
		# Paid customers already vacated on tip; impatient ones still hold the seat.
		if table.is_occupied or table.customer != null or table.has_food:
			table.vacate()
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
