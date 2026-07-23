extends CanvasLayer

@onready var _progress_bar: ProgressBar = $ProgressBar
@onready var _game_scores: RichTextLabel = %GameScores
@onready var _stamina_bar: ProgressBar = %StaminaBar

func _ready() -> void:
	_progress_bar.value = 0.0
	_progress_bar.visible = false
	ScoreState.changed.connect(_refresh_scores)
	ScoreState.phase_changed.connect(_on_phase_changed)
	ScoreState.day_changed.connect(_on_day_changed)
	_refresh_scores()

func _process(_delta: float) -> void:
	_refresh_scores()

func set_stamina(value: float) -> void:
	_stamina_bar.value = value

func set_action_progress(value: float) -> void:
	if value < 0.0:
		_progress_bar.visible = false
		_progress_bar.value = 0.0
		return
	_progress_bar.visible = true
	_progress_bar.value = value

func _on_phase_changed(_phase: ScoreState.Phase) -> void:
	_refresh_scores()

func _on_day_changed(_day: int) -> void:
	_refresh_scores()

func _refresh_scores() -> void:
	_game_scores.text = "[b]Day %d — %s[/b] (%s)\n[b]Served:[/b] %d\n[b]Left at table:[/b] %d\n[b]Left unserved:[/b] %d\n[b]Tables cleaned:[/b] %d\n[b]Tables left dirty:[/b] %d" % [
		ScoreState.day,
		ScoreState.get_phase_name(),
		ScoreState.format_phase_time(),
		ScoreState.served,
		ScoreState.left_at_table,
		ScoreState.left_unserved,
		ScoreState.tables_cleaned,
		ScoreState.tables_left_dirty,
	]
