extends StaticBody3D

const INTERACT_DURATION: float = 1.5

func get_look_action(_player: Node) -> LookAction:
	if ScoreState.phase != ScoreState.Phase.NIGHT:
		return null
	return LookAction.create(INTERACT_DURATION, func() -> void:
		ScoreState.start_day_transition()
	, 0.0)
