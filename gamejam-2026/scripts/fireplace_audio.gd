extends Node3D

const FIREPLACE_SFX: AudioStream = preload("res://assets/audio/fireplace.wav")
const FIRE1_SFX: AudioStream = preload("res://assets/audio/fire1.ogg")

func _ready() -> void:
	_make_looping_player(FIREPLACE_SFX)
	_make_looping_player(FIRE1_SFX)

func _make_looping_player(sfx: AudioStream) -> AudioStreamPlayer3D:
	var player := AudioStreamPlayer3D.new()
	player.stream = sfx
	player.max_distance = 30.0
	player.unit_size = 15.0
	player.finished.connect(player.play)
	add_child(player)
	player.play()
	return player
