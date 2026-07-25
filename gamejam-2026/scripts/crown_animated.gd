extends Node3D

var rotation_speed: float = 2.6

func _process(delta: float) -> void:
	self.global_rotate(Vector3.UP, rotation_speed * delta)
