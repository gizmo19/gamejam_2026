extends Node

const ALL_MUSIC: Array[AudioStream] = [
	preload("res://assets/audio/music_night1.mp3"),
	preload("res://assets/audio/music_night2.mp3")
]

var _player: AudioStreamPlayer
var _music_index: int = 0

func _ready() -> void:
	_player = AudioStreamPlayer.new()
	add_child(_player)
	ScoreState.customers_all_done.connect(_on_customers_all_done)
	ScoreState.day_changed.connect(_on_day_changed)

func play(stream: AudioStream, loop: bool = false) -> void:
	if stream == null:
		return
	if stream is AudioStreamMP3:
		(stream as AudioStreamMP3).loop = loop
	_player.stream = stream
	_player.play()

func stop_all() -> void:
	if _player.playing:
		_player.stop()
	_player.stream = null

func _on_customers_all_done() -> void:
	play(ALL_MUSIC[_music_index])
	_music_index = (_music_index + 1) % ALL_MUSIC.size()


func _on_day_changed(_day: int) -> void:
	stop_all()
