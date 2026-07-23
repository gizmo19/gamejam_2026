class_name NpcInteraction
extends Area3D

signal interaction_requested

var enabled: bool = false
var _player_inside: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		_player_inside = true

func _on_body_exited(body: Node3D) -> void:
	if body.is_in_group("player"):
		_player_inside = false

func _unhandled_input(event: InputEvent) -> void:
	if enabled \
			and _player_inside \
			and event.is_action_pressed("Interaction"):
		interaction_requested.emit()
