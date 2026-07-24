extends Node3D

const SLEEP_DURATION: float = 2.0

@onready var _label: Label3D = %LabelSleep

func _ready() -> void:
	ScoreState.phase_changed.connect(_on_phase_changed)
	_refresh_label()

func get_look_action(_player: Node) -> LookAction:
	if ScoreState.phase != ScoreState.Phase.NIGHT:
		return null
	return LookAction.create(SLEEP_DURATION, func() -> void:
		ScoreState.start_day_transition()
	, 0.0)

func _on_phase_changed(_phase: ScoreState.Phase) -> void:
	_refresh_label()

func _refresh_label() -> void:
	_label.visible = ScoreState.phase == ScoreState.Phase.NIGHT
