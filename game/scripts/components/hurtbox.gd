class_name Hurtbox
extends Area2D

signal hit(amount: float, origin: Vector2)
@export var invulnerable: bool = false
## true para los Hurtbox de enemigos/jefes: los busca el arma Ping.
@export var homing_target: bool = false
var marked: bool = false

func _ready() -> void:
	if homing_target:
		add_to_group("homing_target")

func take_damage(amount: float, origin: Vector2) -> void:
	if not invulnerable:
		hit.emit(amount, origin)
