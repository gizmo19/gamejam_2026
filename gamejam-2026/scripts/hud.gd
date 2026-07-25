extends CanvasLayer

enum MenuTab {GAME_INIT, MAIN_MENU, INTRO, START, GAME_END, LICENSES, CREDITS}

const STAMINA_BLUE_BG: StyleBox = preload("res://resources/ui/stamina_blue_bg.tres")
const STAMINA_BLUE_FILL: StyleBox = preload("res://resources/ui/stamina_blue_fill.tres")
const STAMINA_RED_BG: StyleBox = preload("res://resources/ui/stamina_red_bg.tres")
const STAMINA_RED_FILL: StyleBox = preload("res://resources/ui/stamina_red_fill.tres")

@onready var _progress_bar: ProgressBar = %ProgressBar
@onready var _day_label: RichTextLabel = %DayLabel
@onready var _crowns_label: RichTextLabel = %CrownsLabel
@onready var _stamina_bar: ProgressBar = %StaminaBar
@onready var _stamina_popup: NinePatchRect = %StaminaPopup
@onready var _pointer: AnimatedSprite2D = %Pointer
@onready var _interaction_hint: TextureRect = %InteractionHint
@onready var _stamina_cost_popup: NinePatchRect = %StaminaCostPopup
@onready var _stamina_cost_label: Label = %StaminaCostLabel
@onready var _notification_popup: NinePatchRect = %NotificationPopup
@onready var _notification_label: Label = %NotificationLabel
@onready var _menu_overlay: TextureRect = %MenuOverlay
@onready var _menu_tabs: TabContainer = %MenuTabs
@onready var _fullscreen_button: Button = %FullscreenButton
@onready var _dont_fullscreen_button: Button = %DontFullscreenButton
@onready var _start_game_button: Button = %StartGameButton
@onready var _credits_button: Button = %CreditsButton
@onready var _licenses_button: Button = %LicensesButton
@onready var _quit_button: Button = %QuitButton
@onready var _intro_next_button: Button = %IntroNextButton
@onready var _play_button: Button = %PlayButton
@onready var _end_to_credits_button: Button = %EndToCredits
@onready var _end_stats: RichTextLabel = %End
@onready var _credits_back_button: Button = %CreditsBack
@onready var _licenses_back_button: Button = %LicenseBack

var _fade_overlay: ColorRect
var _fade_tween: Tween
var _stamina_is_low: bool = false

func _ready() -> void:
	_progress_bar.value = 0.0
	_progress_bar.visible = false
	_stamina_popup.visible = false
	_stamina_cost_popup.visible = false
	_notification_popup.visible = false
	_interaction_hint.visible = false
	_pointer.play("pointer")
	_menu_overlay.visible = true

	_fade_overlay = ColorRect.new()
	_fade_overlay.color = Color.BLACK
	_fade_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_fade_overlay.modulate.a = 0.0
	add_child(_fade_overlay)

	_setup_menu()

	ScoreState.changed.connect(_refresh_scores)
	ScoreState.phase_changed.connect(_on_phase_changed)
	ScoreState.day_changed.connect(_on_day_changed)
	ScoreState.customers_all_arrived.connect(_on_customers_all_arrived)
	ScoreState.customers_all_done.connect(_on_customers_all_done)
	ScoreState.game_ended.connect(_on_game_ended)
	ScoreState.screen_fade_in.connect(_fade_to_black)
	ScoreState.screen_fade_out.connect(_fade_from_black)
	_refresh_scores()

func _setup_menu() -> void:
	var mode := DisplayServer.window_get_mode()
	var already_fullscreen := mode == DisplayServer.WINDOW_MODE_FULLSCREEN \
			or mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN
	_menu_tabs.current_tab = MenuTab.MAIN_MENU if already_fullscreen else MenuTab.GAME_INIT

	_fullscreen_button.pressed.connect(_on_fullscreen_pressed)
	_dont_fullscreen_button.pressed.connect(func(): _menu_tabs.current_tab = MenuTab.MAIN_MENU)
	_start_game_button.pressed.connect(func(): _menu_tabs.current_tab = MenuTab.INTRO)
	_credits_button.pressed.connect(func(): _menu_tabs.current_tab = MenuTab.CREDITS)
	_licenses_button.pressed.connect(func(): _menu_tabs.current_tab = MenuTab.LICENSES)
	_quit_button.pressed.connect(func(): get_tree().quit())
	_intro_next_button.pressed.connect(func(): _menu_tabs.current_tab = MenuTab.START)
	_play_button.pressed.connect(_on_play_pressed)
	_end_to_credits_button.pressed.connect(func(): _menu_tabs.current_tab = MenuTab.CREDITS)
	_credits_back_button.pressed.connect(func(): _menu_tabs.current_tab = MenuTab.MAIN_MENU)
	_licenses_back_button.pressed.connect(func(): _menu_tabs.current_tab = MenuTab.MAIN_MENU)

func _on_fullscreen_pressed() -> void:
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	_menu_tabs.current_tab = MenuTab.MAIN_MENU

func _on_play_pressed() -> void:
	_menu_overlay.visible = false
	var player := get_parent() as Player
	if player:
		player.unlock_controls()

func _on_game_ended() -> void:
	_end_stats.text = "[b]Money raised:[/b] %d\n[b]Days passed:[/b] %d\n[b]Customers served / left unserved:[/b] %d / %d\n[b]Tables cleaned / left dirty:[/b] %d / %d\n[b]Secret found:[/b] %s" % [
		ScoreState.total_crowns,
		ScoreState.day,
		ScoreState.served,
		ScoreState.left_unserved,
		ScoreState.tables_cleaned,
		ScoreState.tables_left_dirty,
		"YES" if ScoreState.secret_found else "no",
	]
	_menu_tabs.current_tab = MenuTab.GAME_END
	_menu_overlay.visible = true
	var player := get_parent() as Player
	if player:
		player.lock_controls()

func set_stamina(value: float) -> void:
	_stamina_bar.value = value
	var is_low := value < Player.STAMINA_LOW_THRESHOLD
	_stamina_popup.visible = is_low
	if is_low == _stamina_is_low:
		return
	_stamina_is_low = is_low
	if is_low:
		_stamina_bar.add_theme_stylebox_override("background", STAMINA_RED_BG)
		_stamina_bar.add_theme_stylebox_override("fill", STAMINA_RED_FILL)
	else:
		_stamina_bar.add_theme_stylebox_override("background", STAMINA_BLUE_BG)
		_stamina_bar.add_theme_stylebox_override("fill", STAMINA_BLUE_FILL)

func set_interact_hover(hovering: bool, stamina_cost: float = 0.0) -> void:
	var anim := &"interaction" if hovering else &"pointer"
	if _pointer.animation != anim:
		_pointer.play(anim)
	_interaction_hint.visible = hovering and ScoreState.day == 1
	var show_cost := hovering and not is_zero_approx(stamina_cost)
	_stamina_cost_popup.visible = show_cost
	if show_cost:
		var amount := int(absf(stamina_cost))
		_stamina_cost_label.text = ("+%d%%" if stamina_cost < 0.0 else "-%d%%") % amount

func set_action_progress(value: float) -> void:
	if value < 0.0:
		_progress_bar.visible = false
		_progress_bar.value = 0.0
		return
	_progress_bar.visible = true
	_progress_bar.value = value

func _on_phase_changed(phase: ScoreState.Phase) -> void:
	if phase == ScoreState.Phase.MORNING:
		_notification_popup.visible = false
	elif phase == ScoreState.Phase.NIGHT:
		_show_notification("Tavern's closed. Go to sleep upstairs to finish the day.\nOR cleanup after the customers.")
	_refresh_scores()

func _on_day_changed(_day: int) -> void:
	if ScoreState.day != 1:
		_interaction_hint.visible = false
	_refresh_scores()

func _on_customers_all_arrived() -> void:
	_show_notification("That's the last customer!")

func _on_customers_all_done() -> void:
	_show_notification("All customers left. Close the tavern.")

func _show_notification(message: String) -> void:
	_notification_label.text = message
	_notification_popup.visible = true

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
	_day_label.text = "[b]Day %d / %s[/b]" % [
		ScoreState.day,
		ScoreState.get_phase_name(),
	]
	_crowns_label.text = "Crowns: %d / %d" % [ScoreState.total_crowns, ScoreState.WIN_CROWN_THRESHOLD]
