extends RefCounted

var errors: PackedStringArray = []
var finished: bool = false

func run(_tree: SceneTree) -> PackedStringArray:
	errors = []
	finished = false
	_test_catalog()
	_test_buy_exact_and_insufficient()
	_test_no_double_buy()
	_test_weapon_autoequip()
	_test_cannot_unequip_last_weapon()
	_test_passive_rules()
	_test_buy_passive_autoequips()
	_test_equipped_filters_invalid()
	_test_workshop_status()
	_test_workshop_slots_full()
	_test_upgrades_returns_copy()
	finished = true
	return errors

func fresh(cores: int) -> Dictionary:
	var data: Dictionary = SaveManager.defaults()
	data["data_cores"] = cores
	return data

func _test_buy_exact_and_insufficient() -> void:
	var data: Dictionary = fresh(2)
	check(Progression.buy(data, &"marker"), "compra con núcleos justos")
	check(int(data["data_cores"]) == 0, "núcleos a 0 tras compra justa")
	check(not Progression.can_buy(data, &"long_dash"), "can_buy sin núcleos")
	check(not Progression.buy(data, &"long_dash"), "compra sin núcleos rechazada")
	check(data["owned_upgrades"] == ["marker"], "owned sin cambios tras rechazo")
	check(not Progression.buy(data, &"nope"), "compra de id inexistente")

func _test_no_double_buy() -> void:
	var data: Dictionary = fresh(5)
	Progression.buy(data, &"long_dash")
	check(not Progression.buy(data, &"long_dash"), "segunda compra rechazada")
	check(int(data["data_cores"]) == 4, "núcleos no bajan en doble compra")

func _test_weapon_autoequip() -> void:
	var data: Dictionary = fresh(4)
	Progression.buy(data, &"triple")
	check(Progression.equipped_weapons(data) == [&"packet", &"triple"], "triple se autoequipa")
	Progression.buy(data, &"ping")
	check(Progression.equipped_weapons(data).size() == 2, "máximo 2 armas equipadas")
	check(Progression.owns(data, &"ping"), "ping poseída")
	check(Progression.owns(data, &"packet"), "packet siempre poseída")

func _test_cannot_unequip_last_weapon() -> void:
	var data: Dictionary = fresh(2)
	Progression.buy(data, &"triple")
	check(Progression.toggle_weapon(data, &"triple"), "quitar triple")
	check(Progression.equipped_weapons(data) == [&"packet"], "queda packet")
	check(not Progression.toggle_weapon(data, &"packet"), "no se quita la última")
	check(Progression.equipped_weapons(data) == [&"packet"], "packet sigue equipada")
	check(Progression.toggle_weapon(data, &"triple"), "volver a equipar triple")
	check(not Progression.toggle_weapon(data, &"ping"), "no se equipa arma no poseída")

func _test_passive_rules() -> void:
	var data: Dictionary = fresh(4)
	check(not Progression.set_passive(data, &"marker"), "pasiva no poseída rechazada")
	Progression.buy(data, &"marker")
	check(Progression.set_passive(data, &"marker"), "equipar pasiva poseída")
	check(Progression.has_effect(data, &"marker"), "efecto de pasiva equipada")
	Progression.buy(data, &"more_health")
	check(not Progression.set_passive(data, &"more_health"), "permanente no va en ranura pasiva")
	check(Progression.has_effect(data, &"more_health"), "efecto de permanente poseída")
	check(Progression.set_passive(data, &""), "desequipar pasiva")
	check(not Progression.has_effect(data, &"marker"), "pasiva desequipada sin efecto")

func _test_buy_passive_autoequips() -> void:
	var data: Dictionary = fresh(6)
	check(Progression.buy(data, &"marker"), "compra pasiva marker")
	check(Progression.has_effect(data, &"marker"), "pasiva se autoequipa al comprar con ranura vacía")
	check(Progression.buy(data, &"slowdown"), "compra pasiva slowdown")
	check(Progression.has_effect(data, &"marker"), "nueva pasiva no desequipa la equipada")
	check(not Progression.has_effect(data, &"slowdown"), "segunda pasiva no se autoequipa sobre la primera")

func _test_workshop_status() -> void:
	var workshop: Script = load("res://scripts/ui/workshop.gd") as Script
	var data: Dictionary = fresh(2)
	check(workshop.call("status", data, Catalog.upgrade(&"slowdown")) == "Sin núcleos", "taller: sin núcleos")
	check(workshop.call("status", data, Catalog.upgrade(&"triple")) == "Comprar", "taller: comprar")
	Progression.buy(data, &"triple")
	check(workshop.call("status", data, Catalog.upgrade(&"triple")) == "Equipada", "taller: arma equipada")
	Progression.toggle_weapon(data, &"triple")
	check(workshop.call("status", data, Catalog.upgrade(&"triple")) == "Equipar", "taller: arma sin equipar")
	data["data_cores"] = 2
	Progression.buy(data, &"more_health")
	check(workshop.call("status", data, Catalog.upgrade(&"more_health")) == "Instalada", "taller: permanente")

func _test_workshop_slots_full() -> void:
	var workshop: Script = load("res://scripts/ui/workshop.gd") as Script
	var data: Dictionary = fresh(4)
	Progression.buy(data, &"triple")
	Progression.buy(data, &"ping")
	check(workshop.call("status", data, Catalog.upgrade(&"ping")) == "Ranuras llenas", "taller: ranuras llenas")
	check(workshop.call("status", data, Catalog.upgrade(&"triple")) == "Equipada", "taller: arma equipada")

func _test_upgrades_returns_copy() -> void:
	var copy: Array[UpgradeData] = Catalog.upgrades()
	copy.clear()
	check(copy.is_empty() and Catalog.upgrades().size() == 7, "catálogo: upgrades() devuelve una copia mutable")

func _test_equipped_filters_invalid() -> void:
	var data: Dictionary = fresh(0)
	data["equipped"]["weapons"] = ["laser", "ping"]
	check(Progression.equipped_weapons(data) == [&"packet"], "ids inválidos o no poseídos → packet")

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
