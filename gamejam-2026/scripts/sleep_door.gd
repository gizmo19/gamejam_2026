extends Node3D

const SLEEP_DURATION: float = 1.0

@onready var _label: Label3D = %LabelSleep

var _used_this_night: bool = false

func _ready() -> void:
	ScoreState.phase_changed.connect(_on_phase_changed)
	_refresh_label()

func get_look_action(_player: Node) -> LookAction:
	if ScoreState.phase != ScoreState.Phase.NIGHT or _used_this_night:
		return null
	return LookAction.create(SLEEP_DURATION, func() -> void:
		_used_this_night = true
		_refresh_label()
		ScoreState.start_day_transition()
	, 0.0)

func _on_phase_changed(phase: ScoreState.Phase) -> void:
	if phase == ScoreState.Phase.NIGHT:
		_used_this_night = false
	_refresh_label()

func _refresh_label() -> void:
	_label.visible = ScoreState.phase == ScoreState.Phase.NIGHT and not _used_this_night
