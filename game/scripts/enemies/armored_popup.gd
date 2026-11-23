class_name ArmoredPopUp
extends PopUp

@export var facing: Vector2 = Vector2.LEFT

func _init() -> void:
	max_health = 4.0

func take_damage(amount: float, origin: Vector2) -> void:
	if state != State.DEAD and ArmorRule.blocks(origin, global_position, facing):
		flash = 0.05
		return
	super.take_damage(amount, origin)

func _draw() -> void:
	super._draw()
	if state != State.DEAD:
		EnemyArt.armor(self, facing * 10.0, 20.0, facing.x)
