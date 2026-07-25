extends Node3D

const PICKUP_DURATION: float = 0.5

func get_look_action(player: Node) -> LookAction:
	if player == null or player.held_item != -1:
		return null
	return LookAction.create(PICKUP_DURATION, func() -> void:
		if player.held_item != -1:
			return
		player.pick_up(Item.Type.KREMOWKA)
		ScoreState.record_secret_found()
	, 0.0)
