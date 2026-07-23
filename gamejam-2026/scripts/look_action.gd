class_name LookAction
extends RefCounted

var duration: float
var on_complete: Callable

static func create(duration: float, on_complete: Callable) -> LookAction:
	var action := LookAction.new()
	action.duration = duration
	action.on_complete = on_complete
	return action
