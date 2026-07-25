extends Node3D

const FIREPLACE_SFX: AudioStream = preload("res://assets/audio/fireplace.wav")

func _ready() -> void:
	var player := AudioStreamPlayer3D.new()
	player.stream = FIREPLACE_SFX
	player.max_distance = 30.0
	player.unit_size = 15.0
	player.volume_db = linear_to_db(0.4)
	player.finished.connect(player.play)
	add_child(player)
	player.play()
