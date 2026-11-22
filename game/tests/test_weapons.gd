extends RefCounted

var errors: PackedStringArray = []

func run(tree: SceneTree) -> PackedStringArray:
	errors = []
	_test_spread_directions()
	_test_steer_without_target()
	_test_steer_limits_turn()
	return errors

func check(condition: bool, message: String) -> void:
	if not condition:
		errors.append(message)

func _test_spread_directions() -> void:
	var dirs: Array[Vector2] = Projectile.spread_directions(Vector2.RIGHT, 3, 12.0)
	check(dirs.size() == 3, "abanico: 3 direcciones")
	if dirs.size() == 3:
		check(dirs[1].is_equal_approx(Vector2.RIGHT), "abanico: central recta")
		check(absf(absf(dirs[0].angle()) - deg_to_rad(12.0)) < 0.001, "abanico: extremo 0 a 12°")
		check(absf(absf(dirs[2].angle()) - deg_to_rad(12.0)) < 0.001, "abanico: extremo 2 a 12°")
		check(signf(dirs[0].angle()) != signf(dirs[2].angle()), "abanico: extremos opuestos")
	check(Projectile.spread_directions(Vector2.UP, 1, 12.0) == [Vector2.UP], "abanico: 1 bala")

func _test_steer_without_target() -> void:
	check(Projectile.steer(Vector2(300, 0), Vector2.ZERO, 0.05) == Vector2(300, 0), "steer sin objetivo")

func _test_steer_limits_turn() -> void:
	var result: Vector2 = Projectile.steer(Vector2(300, 0), Vector2(0, 1), deg_to_rad(3.0))
	check(absf(result.angle() - deg_to_rad(3.0)) < 0.001, "steer: gira 3°")
	check(absf(result.length() - 300.0) < 0.01, "steer: conserva módulo")
	var close: Vector2 = Projectile.steer(Vector2(300, 0), Vector2(1, 0.01), deg_to_rad(30.0))
	check(absf(close.angle() - Vector2(1, 0.01).angle()) < 0.001, "steer: no se pasa del objetivo")
