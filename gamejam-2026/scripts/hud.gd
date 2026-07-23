extends CanvasLayer

@onready var _progress_bar: ProgressBar = $ProgressBar

func _ready() -> void:
	_progress_bar.value = 0.0
	_progress_bar.visible = false

func set_action_progress(value: float) -> void:
	if value < 0.0:
		_progress_bar.visible = false
		_progress_bar.value = 0.0
		return
	_progress_bar.visible = true
	_progress_bar.value = value
