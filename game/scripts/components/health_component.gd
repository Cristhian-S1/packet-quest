class_name HealthComponent
extends Node

signal changed(current: float, maximum: float)
signal depleted
@export var max_health: float = 3.0
var current: float = 3.0

func _ready() -> void:
	reset()

func reset() -> void:
	current = max_health
	changed.emit(current, max_health)

func damage(amount: float) -> void:
	if amount <= 0.0 or current <= 0.0:
		return
	current = maxf(0.0, current - amount)
	changed.emit(current, max_health)
	if current == 0.0:
		depleted.emit()

func heal(amount: float) -> void:
	if amount <= 0.0:
		return
	current = minf(max_health, current + amount)
	changed.emit(current, max_health)
