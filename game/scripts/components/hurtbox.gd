class_name Hurtbox
extends Area2D

signal hit(amount: float, origin: Vector2)
@export var invulnerable: bool = false

func take_damage(amount: float, origin: Vector2) -> void:
	if not invulnerable:
		hit.emit(amount, origin)
