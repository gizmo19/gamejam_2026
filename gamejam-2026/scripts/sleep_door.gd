extends Node3D

const SLEEP_DURATION: float = 1.0
const STAMINA_RESTORE: float = 35.0
const YAWN_SFX: AudioStream = preload("res://assets/audio/Yawn.wav")

@onready var _label: Label3D = %LabelSleep

var _used_this_night: bool = false
var _yawn_player: AudioStreamPlayer

func _ready() -> void:
	ScoreState.phase_changed.connect(_on_phase_changed)
	_refresh_label()
	_yawn_player = AudioStreamPlayer.new()
	_yawn_player.stream = YAWN_SFX
	add_child(_yawn_player)

func get_look_action(_player: Node) -> LookAction:
	if ScoreState.phase != ScoreState.Phase.NIGHT or _used_this_night:
		return null
	return LookAction.create(SLEEP_DURATION, func() -> void:
		_used_this_night = true
		_refresh_label()
		ScoreState.start_day_transition()
	, -STAMINA_RESTORE)

func _on_phase_changed(phase: ScoreState.Phase) -> void:
	if phase == ScoreState.Phase.NIGHT:
		_used_this_night = false
		_yawn_player.play()
	_refresh_label()

func _refresh_label() -> void:
	_label.visible = ScoreState.phase == ScoreState.Phase.NIGHT and not _used_this_night
