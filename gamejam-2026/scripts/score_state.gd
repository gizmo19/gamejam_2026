extends Node

signal changed

var served: int = 0
var left_at_table: int = 0
var left_unserved: int = 0

func record_served() -> void:
	served += 1
	changed.emit()

func record_left_at_table() -> void:
	left_at_table += 1
	changed.emit()

func record_left_unserved() -> void:
	left_unserved += 1
	changed.emit()

func reset() -> void:
	served = 0
	left_at_table = 0
	left_unserved = 0
	changed.emit()
