class_name Hitbox
extends Area2D

@export var damage: float = 1.0

func _ready() -> void:
	body_entered.connect(_hit)
	area_entered.connect(_hit)

func _hit(target: Node2D) -> void:
	if target.has_method("take_damage"):
		target.call("take_damage", damage, global_position)
