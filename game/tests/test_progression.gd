extends RefCounted

var errors: PackedStringArray = []

func run(_tree: SceneTree) -> PackedStringArray:
	errors = []
	_test_catalog()
	return errors

func check(condition: bool, message: String) -> void:
	if not condition:
		errors.append(message)

func _test_catalog() -> void:
	check(Catalog.upgrades().size() == 7, "catálogo: 7 mejoras")
	var triple: WeaponData = Catalog.weapon(&"triple")
	check(triple != null, "catálogo: arma triple")
	if triple != null:
		check(is_equal_approx(triple.damage, 0.6) and is_equal_approx(triple.fire_rate, 5.0)
			and is_equal_approx(triple.bullet_speed, 420.0) and triple.spread_count == 3
			and is_equal_approx(triple.spread_angle_deg, 12.0), "catálogo: valores de triple")
	var ping: WeaponData = Catalog.weapon(&"ping")
	check(ping != null, "catálogo: arma ping")
	if ping != null:
		check(is_equal_approx(ping.damage, 1.3) and is_equal_approx(ping.fire_rate, 6.0)
			and is_equal_approx(ping.bullet_speed, 300.0) and is_equal_approx(ping.homing_turn_deg, 180.0),
			"catálogo: valores de ping")
	check(Catalog.weapon(&"packet") != null, "catálogo: arma packet")
	var slowdown: UpgradeData = Catalog.upgrade(&"slowdown")
	check(slowdown != null and slowdown.cost == 3, "catálogo: coste ralentizador")
	var health: UpgradeData = Catalog.upgrade(&"more_health")
	check(health != null and health.kind == UpgradeData.Kind.PERMANENT, "catálogo: más vida permanente")
	check(Catalog.upgrade(&"nope") == null, "catálogo: id inexistente")
