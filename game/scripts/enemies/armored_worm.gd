class_name ArmoredWorm
extends NetworkWorm

var facing: Vector2 = Vector2.RIGHT

func _init() -> void:
	max_health = 6.0

func advance(delta: float) -> void:
	var length: float = cable.curve.get_baked_length()
	var outbound: bool = fposmod(age * move_speed, length * 2.0) < length
	facing = Vector2.RIGHT if outbound == (move_speed >= 0.0) else Vector2.LEFT
	super.advance(delta)

func take_damage(amount: float, origin: Vector2) -> void:
	if state != State.DEAD and ArmorRule.blocks(origin, global_position, facing):
		flash = 0.05
		return
	super.take_damage(amount, origin)

func _draw() -> void:
	super._draw()
	if state != State.DEAD:
		EnemyArt.armor(self, facing * 12.0, 14.0, facing.x)
