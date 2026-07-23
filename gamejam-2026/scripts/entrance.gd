extends Node3D

const OPEN_DURATION: float = 1.0

@onready var _label_closed: Label3D = %LabelClosed
@onready var _label_opened: Label3D = %LabelOpened

func _ready() -> void:
	ScoreState.phase_changed.connect(_on_phase_changed)
	_refresh_sign()

func get_look_action(_player: Node) -> LookAction:
	if ScoreState.phase != ScoreState.Phase.MORNING:
		return null
	return LookAction.create(OPEN_DURATION, func() -> void:
		ScoreState.open_for_business()
	, 0.0)

func _on_phase_changed(_phase: ScoreState.Phase) -> void:
	_refresh_sign()

func _refresh_sign() -> void:
	var is_morning := ScoreState.phase == ScoreState.Phase.MORNING
	_label_opened.visible = is_morning
	_label_closed.visible = not is_morning
