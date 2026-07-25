extends Node3D

const ENV_BY_PHASE: Dictionary = {
	ScoreState.Phase.MORNING: preload("res://resources/env/env_morning.tres"),
	ScoreState.Phase.NOON: preload("res://resources/env/env_noon.tres"),
	ScoreState.Phase.NIGHT: preload("res://resources/env/env_night.tres"),
}

@onready var _world_environment: WorldEnvironment = $WorldEnvironment
@onready var _sun_morning: DirectionalLight3D = $SunMorning
@onready var _sun_noon: DirectionalLight3D = $SunNoon
@onready var _sun_night: DirectionalLight3D = $SunNight

func _ready() -> void:
	ScoreState.phase_changed.connect(_apply_phase)
	_apply_phase(ScoreState.phase)

func _apply_phase(phase: ScoreState.Phase) -> void:
	_sun_morning.visible = phase == ScoreState.Phase.MORNING
	_sun_noon.visible = phase == ScoreState.Phase.NOON
	_sun_night.visible = phase == ScoreState.Phase.NIGHT
	_world_environment.environment = ENV_BY_PHASE[phase]
