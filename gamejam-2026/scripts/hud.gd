extends CanvasLayer

@onready var _progress_bar: ProgressBar = $ProgressBar
@onready var _game_scores: RichTextLabel = %GameScores
@onready var _stamina_bar: ProgressBar = %StaminaBar
@onready var _pointer: AnimatedSprite2D = %Pointer

var _notification_label: RichTextLabel
var _fade_overlay: ColorRect
var _fade_tween: Tween

func _ready() -> void:
	_progress_bar.value = 0.0
	_progress_bar.visible = false
	_pointer.play("pointer")

	_notification_label = RichTextLabel.new()
	_notification_label.bbcode_enabled = true
	_notification_label.fit_content = true
	_notification_label.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	_notification_label.offset_top = -100
	_notification_label.add_theme_font_size_override("normal_font_size", 22)
	_notification_label.add_theme_font_size_override("bold_font_size", 22)
	_notification_label.visible = false
	add_child(_notification_label)

	_fade_overlay = ColorRect.new()
	_fade_overlay.color = Color.BLACK
	_fade_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_fade_overlay.modulate.a = 0.0
	add_child(_fade_overlay)

	ScoreState.changed.connect(_refresh_scores)
	ScoreState.phase_changed.connect(_on_phase_changed)
	ScoreState.day_changed.connect(_on_day_changed)
	ScoreState.customers_all_arrived.connect(_on_customers_all_arrived)
	ScoreState.customers_all_done.connect(_on_customers_all_done)
	ScoreState.screen_fade_in.connect(_fade_to_black)
	ScoreState.screen_fade_out.connect(_fade_from_black)
	_refresh_scores()

func _process(_delta: float) -> void:
	_refresh_scores()

func set_stamina(value: float) -> void:
	_stamina_bar.value = value

func set_interact_hover(hovering: bool) -> void:
	var anim := &"interaction" if hovering else &"pointer"
	if _pointer.animation != anim:
		_pointer.play(anim)

func set_action_progress(value: float) -> void:
	if value < 0.0:
		_progress_bar.visible = false
		_progress_bar.value = 0.0
		return
	_progress_bar.visible = true
	_progress_bar.value = value

func _on_phase_changed(phase: ScoreState.Phase) -> void:
	if phase == ScoreState.Phase.MORNING:
		_notification_label.visible = false
	elif phase == ScoreState.Phase.NIGHT:
		_notification_label.text = "[center][b]Tawerna zamknięta.[/b]\nPodejdź do schodów na półpiętro, żeby zakończyć dzień.[/center]"
		_notification_label.visible = true
	_refresh_scores()

func _on_day_changed(_day: int) -> void:
	_refresh_scores()

func _on_customers_all_arrived() -> void:
	_notification_label.text = "[center][b]Nie przyjdą już dziś żadni goście![/b]\nObsłuż pozostałych i poczekaj aż wyjdą.[/center]"
	_notification_label.visible = true

func _on_customers_all_done() -> void:
	_notification_label.text = "[center][b]Wszyscy goście wyszli![/b]\nPodejdź do drzwi i przytrzymaj E, żeby zamknąć tawernę.[/center]"
	_notification_label.visible = true

func _fade_to_black() -> void:
	if _fade_tween:
		_fade_tween.kill()
	_fade_tween = create_tween()
	_fade_tween.tween_property(_fade_overlay, "modulate:a", 1.0, 0.8)

func _fade_from_black() -> void:
	if _fade_tween:
		_fade_tween.kill()
	_fade_tween = create_tween()
	_fade_tween.tween_interval(0.3)
	_fade_tween.tween_property(_fade_overlay, "modulate:a", 0.0, 0.8)

func _refresh_scores() -> void:
	_game_scores.text = "[b]Dzień %d[/b]   Dukaty: %d / 1000\n[b]Obsłużono:[/b] %d\n[b]Wyszło ze stołu:[/b] %d\n[b]Wyszło bez obsługi:[/b] %d\n[b]Posprzątane stoły:[/b] %d\n[b]Brudne stoły:[/b] %d" % [
		ScoreState.day,
		ScoreState.total_ducats,
		ScoreState.served,
		ScoreState.left_at_table,
		ScoreState.left_unserved,
		ScoreState.tables_cleaned,
		ScoreState.tables_left_dirty,
	]
