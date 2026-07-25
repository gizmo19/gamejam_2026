@tool
extends Node3D

const ENV_BY_PHASE: Dictionary = {
	ScoreState.Phase.MORNING: preload("res://resources/env/env_morning.tres"),
	ScoreState.Phase.NOON: preload("res://resources/env/env_noon.tres"),
	ScoreState.Phase.NIGHT: preload("res://resources/env/env_night.tres"),
}

@export var phase: ScoreState.Phase = ScoreState.Phase.MORNING:
	set(value):
		phase = value
		if is_inside_tree():
			_apply_phase(value)

func _ready() -> void:
	if Engine.is_editor_hint():
		_apply_phase(phase)
		return
	ScoreState.phase_changed.connect(func(next: ScoreState.Phase) -> void: phase = next)
	phase = ScoreState.phase

func _apply_phase(next_phase: ScoreState.Phase) -> void:
	$SunMorning.visible = next_phase == ScoreState.Phase.MORNING
	$SunNoon.visible = next_phase == ScoreState.Phase.NOON
	$SunNight.visible = next_phase == ScoreState.Phase.NIGHT
	$WorldEnvironment.environment = ENV_BY_PHASE[next_phase]
