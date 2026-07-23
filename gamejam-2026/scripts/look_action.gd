class_name LookAction
extends RefCounted

var duration: float
var stamina_cost: float
var on_complete: Callable

static func create(duration: float, on_complete: Callable, stamina_cost: float = 0.0) -> LookAction:
	var action := LookAction.new()
	action.duration = duration
	action.stamina_cost = stamina_cost
	action.on_complete = on_complete
	return action
