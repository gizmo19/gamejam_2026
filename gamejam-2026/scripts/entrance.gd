extends Node3D

const OPEN_DURATION: float = 1.0
const CLOSE_DURATION: float = 3.0

signal opened

@onready var _label_closed: Label3D = %LabelClosed
@onready var _label_opened: Label3D = %LabelOpened

func _ready() -> void:
	ScoreState.phase_changed.connect(_on_phase_changed)
	ScoreState.customers_all_arrived.connect(_refresh_sign)
	ScoreState.customers_all_done.connect(_refresh_sign)
	_refresh_sign()

func get_look_action(_player: Node) -> LookAction:
	if ScoreState.phase == ScoreState.Phase.MORNING:
		return LookAction.create(OPEN_DURATION, func() -> void:
			ScoreState.open_for_business()
			opened.emit()
		, 0.0)
	if ScoreState.phase == ScoreState.Phase.NOON and ScoreState.all_customers_done:
		return LookAction.create(CLOSE_DURATION, func() -> void:
			ScoreState.close_tavern()
		, 0.0)
	return null

func _on_phase_changed(_phase: ScoreState.Phase) -> void:
	_refresh_sign()

func _refresh_sign() -> void:
	var can_close := ScoreState.phase == ScoreState.Phase.NOON and ScoreState.all_customers_done
	var is_open := ScoreState.phase == ScoreState.Phase.NOON and not ScoreState.all_customers_done

	_label_opened.visible = is_open
	_label_closed.visible = not is_open

	if can_close:
		_label_closed.text = "ZAMKNIJ"
	else:
		_label_closed.text = "ZAMKNIĘTE"
