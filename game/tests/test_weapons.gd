extends RefCounted

var errors: PackedStringArray = []
var finished: bool = false
var player_checked: bool = false

func run(tree: SceneTree) -> PackedStringArray:
	errors = []
	finished = false
	_test_spread_directions()
	_test_steer_without_target()
	_test_steer_limits_turn()
	_test_dead_enemy_leaves_homing(tree)
	await _test_player(tree)
	check(player_checked, "prueba del jugador abortada por un error de script")
	finished = true
	return errors

func _data(cores: int, buys: Array[StringName], passive: StringName = &"") -> Dictionary:
	var data: Dictionary = SaveManager.defaults()
	data["data_cores"] = cores
	for id: StringName in buys:
		Progression.buy(data, id)
	if passive != &"":
		Progression.set_passive(data, passive)
	return data

func _test_player(tree: SceneTree) -> void:
	var stage: Node2D = Node2D.new()
	var pool: ProjectilePool = ProjectilePool.new()
	stage.add_child(pool)
	var player: PacketPlayer = (load("res://scenes/player/Player.tscn") as PackedScene).instantiate() as PacketPlayer
	player.position = Vector2(100, 100)
	stage.add_child(player)
	tree.root.add_child(stage)
	await tree.process_frame
	# test_player_falls_back_to_packet
	var invalid: Dictionary = SaveManager.defaults()
	invalid["equipped"]["weapons"] = ["laser"]
	player.apply_progression(invalid)
	check(player.weapon_slots.size() == 1 and player.current_weapon().id == &"packet", "fallback a packet")
	# test_swap_with_single_weapon
	player.swap_weapon()
	check(player.weapon_index == 0, "swap con una sola arma no cambia")
	# test_swap_two_weapons
	player.apply_progression(_data(2, [&"triple"]))
	player.swap_weapon()
	check(player.current_weapon().id == &"triple", "swap a triple")
	player.swap_weapon()
	check(player.current_weapon().id == &"packet", "swap de vuelta a packet")
	# test_passives_apply (y que apply_progression es idempotente)
	var full: Dictionary = _data(9, [&"more_health", &"long_dash", &"strong_firewall"], &"strong_firewall")
	player.apply_progression(full)
	player.apply_progression(full)
	check(is_equal_approx(player.health.max_health, 4.0), "más vida: 4 PV (idempotente)")
	check(is_equal_approx(player.dash_distance, 96.0), "dash extendido: 96 px")
	check(is_equal_approx(player.shield_max, 150.0), "firewall reforzado: 150")
	check(is_equal_approx(player.shield_recharge, 12.0 * 1.3), "firewall reforzado: recarga ×1,3")
	player.apply_progression(SaveManager.defaults())
	check(is_equal_approx(player.health.max_health, 3.0) and is_equal_approx(player.dash_distance, 72.0), "sin mejoras vuelve a la base")
	# test_triple_fires_three
	player.apply_progression(_data(2, [&"triple"]))
	player.swap_weapon()
	for bullet: Projectile in pool.player_bullets:
		bullet.deactivate()
	player.shoot()
	var active: int = 0
	for bullet: Projectile in pool.player_bullets:
		if bullet.active:
			active += 1
	check(active == 3, "triple dispara 3 balas (hubo %d)" % active)
	# test_slowdown_counts_game_time: la duración avanza solo con el juego (no en pausa)
	player.apply_progression(_data(3, [&"slowdown"], &"slowdown"))
	player._check_slowdown(1.0, 3.0)
	check(is_equal_approx(Projectile.enemy_time_scale, 0.5), "ralentizador activa 50 %")
	player.tick_slowdown(2.9)
	check(is_equal_approx(Projectile.enemy_time_scale, 0.5), "ralentizador sigue a los 2,9 s")
	player.tick_slowdown(0.2)
	check(is_equal_approx(Projectile.enemy_time_scale, 1.0), "ralentizador termina a los 3 s")
	player._check_slowdown(1.0, 3.0)
	check(is_equal_approx(Projectile.enemy_time_scale, 1.0), "ralentizador solo 1 vez por nivel")
	stage.queue_free()
	await tree.process_frame
	player_checked = true

func check(condition: bool, message: String) -> void:
	if not condition:
		errors.append(message)

func _test_dead_enemy_leaves_homing(tree: SceneTree) -> void:
	var enemy: EnemyBase = EnemyBase.new()
	tree.root.add_child(enemy)
	check(enemy.is_in_group("homing_target"), "enemigo vivo está en homing_target")
	enemy._die()
	check(not enemy.is_in_group("homing_target"), "enemigo muerto sale de homing_target")
	enemy.queue_free()

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
