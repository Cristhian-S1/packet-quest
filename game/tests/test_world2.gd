extends RefCounted

var errors: PackedStringArray = []
var finished: bool = false

func run(tree: SceneTree) -> PackedStringArray:
	errors = []
	finished = false
	_test_world_progress()
	_test_wave()
	_test_coverage()
	await _test_spyware(tree)
	_test_cable_grid()
	await _test_queen(tree)
	await _test_route_to_queen(tree)
	finished = true
	return errors

func _test_world_progress() -> void:
	var state: Node = GameState
	var has_world_query: bool = state.has_method(&"is_world_playable")
	check(has_world_query, "falta la consulta de mundos jugables")
	if has_world_query:
		check(not bool(state.call(&"is_world_playable", GameState.data, 2)), "Wi-Fi comienza bloqueado")
	GameState.win()
	check("w1_boss" in GameState.data["completed_levels"], "victoria registra el jefe del mundo 1")
	check(2 in GameState.data["unlocked_worlds"], "victoria desbloquea Wi-Fi")
	var saved: Dictionary = SaveManager.load_game()
	GameState.data = saved
	GameState.win()
	check(GameState.data["unlocked_worlds"].size() == 2, "repetir victoria tras cargar no duplica mundos")
	check(GameState.data["completed_levels"].count("w1_boss") == 1, "repetir victoria no duplica el jefe")
	if has_world_query:
		check(bool(state.call(&"is_world_playable", saved, 2)), "Wi-Fi se puede jugar tras cargar el progreso")
		saved["unlocked_worlds"].append(3)
		check(not bool(state.call(&"is_world_playable", saved, 3)), "Firewall desbloqueado sigue sin escenas")

func _test_wave() -> void:
	var wave: Script = _require_script("res://scripts/objects/wave_zone.gd")
	if wave == null:
		return
	var times: Array[float] = [0.0, 1.9, 2.2, 2.6, 3.1]
	var expected: Array[StringName] = [&"active", &"active", &"inactive", &"warning", &"active"]
	for index: int in range(times.size()):
		check(wave.call(&"state_at", times[index]) == expected[index], "estado de onda a %.1f s" % times[index])

func _test_coverage() -> void:
	var platform: Script = _require_script("res://scripts/objects/coverage_platform.gd")
	if platform == null:
		return
	check(bool(platform.call(&"is_covered", Vector2(159, 0), Vector2.ZERO, 160.0)), "159 px tiene cobertura")
	check(bool(platform.call(&"is_covered", Vector2(160, 0), Vector2.ZERO, 160.0)), "160 px tiene cobertura")
	check(not bool(platform.call(&"is_covered", Vector2(161, 0), Vector2.ZERO, 160.0)), "161 px queda sin cobertura")

func _test_spyware(tree: SceneTree) -> void:
	var scene: PackedScene = _require_scene("res://scenes/enemies/Spyware.tscn")
	if scene == null:
		return
	var stage: Node2D = Node2D.new()
	tree.root.add_child(stage)
	StageBuilder.platform(stage, Vector2(0, 304), Vector2(640, 56))
	var player: PacketPlayer = StageBuilder.player(stage, Vector2(400, 296), 640)
	player.set_physics_process(false)
	var spy: EnemyBase = scene.instantiate() as EnemyBase
	spy.position = Vector2(200, 296)
	stage.add_child(spy)
	await tree.physics_frame
	check(int(spy.get("spy_state")) == 0, "Spyware disfrazado a 200 px")
	check(not spy.is_in_group(&"homing_target") and spy.collision_layer == 0, "el disfraz oculta la hurtbox")
	spy.take_damage(1.0, Vector2.ZERO)
	check(is_equal_approx(spy.health.current, 4.0), "el disfraz es inmune")
	player.position.x = 250.0
	await tree.physics_frame
	await tree.physics_frame
	check(int(spy.get("spy_state")) == 1 and spy.is_in_group(&"homing_target"), "Spyware se revela a 50 px")
	for frame: int in range(24):
		await tree.physics_frame
	var jump_velocity: Vector2 = spy.get("jump_velocity")
	check(int(spy.get("spy_state")) == 2 and jump_velocity.x > 0.0 and jump_velocity.y < 0.0,
		"tras el aviso Spyware salta hacia Byte")
	stage.queue_free()
	await tree.process_frame

func _test_cable_grid() -> void:
	var cable: Script = _require_script("res://scripts/puzzles/cable_grid.gd")
	if cable == null:
		return
	var grid: RefCounted = cable.new() as RefCounted
	var entry: Vector2i = Vector2i(0, 1)
	var corner: Vector2i = Vector2i(1, 1)
	var mask: int = int(grid.call(&"openings", corner))
	for turn: int in range(4):
		grid.call(&"rotate_cell", corner)
	check(int(grid.call(&"openings", corner)) == mask, "cuatro giros restauran las aberturas")
	check(not bool(grid.call(&"is_solved")), "el cable comienza sin resolver")
	grid.call(&"rotate_cell", entry)
	check(grid.call(&"connected_cells") == [entry], "un conector sin abertura enfrentada corta la ruta")
	var solution: Array[Vector2i] = [corner, corner, Vector2i(1, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0)]
	for cell: Vector2i in solution:
		grid.call(&"rotate_cell", cell)
	check(bool(grid.call(&"is_solved")), "la ruta especificada conecta la antena al router")
	check(1 + solution.size() <= 10, "la solución se alcanza con diez disparos o menos")

func _test_queen(tree: SceneTree) -> void:
	var scene: PackedScene = _require_scene("res://scenes/bosses/WifiQueenBoss.tscn")
	if scene == null:
		return
	var boss: Node2D = scene.instantiate() as Node2D
	var script: Script = boss.get_script() as Script
	check(int(script.call(&"phase_for", 1.0)) == 1, "Reina: fase 1 con todos los PV")
	check(int(script.call(&"phase_for", 0.69)) == 2, "Reina: fase 2 bajo el 70 %")
	check(int(script.call(&"phase_for", 0.39)) == 3, "Reina: fase 3 bajo el 40 %")
	for seed_index: int in range(21):
		var lanes: Array[int] = script.call(&"interference_lanes", seed_index)
		check(lanes.size() == 2 and mini(lanes[0], lanes[1]) >= 0 and maxi(lanes[0], lanes[1]) <= 3
			and absi(lanes[1] - lanes[0]) > 1, "Reina: franjas válidas y separadas para %d" % seed_index)
	tree.root.add_child(boss)
	var player: PacketPlayer = boss.get("player") as PacketPlayer
	var pool: ProjectilePool = boss.get("pool") as ProjectilePool
	player.position = Vector2(88, 288)
	player.set_physics_process(false)
	await tree.physics_frame
	player.interact()
	await tree.physics_frame
	var bullet: Projectile = pool.fire(true, Vector2(180, 288), Vector2(-160, 0))
	for frame: int in range(8):
		await tree.physics_frame
	check(not bullet.active, "la cúpula activa intercepta la bala del pool")
	check(is_equal_approx(player.health.current, player.health.max_health), "la cúpula protege a Byte")
	boss.queue_free()
	await tree.process_frame

func _test_route_to_queen(tree: SceneTree) -> void:
	GameState.data = SaveManager.defaults()
	GameState.current_world = 1
	GameState.win()
	GameState.open_map()
	await tree.scene_changed
	var map: Node = tree.current_scene
	var select: InputEventAction = InputEventAction.new()
	select.action = &"ui_right"
	select.pressed = true
	Input.parse_input_event(select)
	await tree.process_frame
	select = InputEventAction.new()
	select.action = &"ui_right"
	Input.parse_input_event(select)
	var entry: Button = map.get("enter_button") as Button
	check(int(map.get("selected_world")) == 2 and "Wi-Fi" in entry.text, "el mapa permite elegir Wi-Fi")
	if int(map.get("selected_world")) != 2:
		return
	entry.pressed.emit()
	await tree.scene_changed
	var level: World2Level1 = tree.current_scene as World2Level1
	check(level != null, "Entrar abre el nivel 2-1")
	if level == null:
		return

	var player: PacketPlayer = level.player
	player.position = Vector2(240, 296)
	for frame: int in range(12):
		await tree.physics_frame
	check(player.position.x > 250.0 and player.position.x < 260.0, "el empuje real mueve a Byte sin acumular velocidad")
	player.position = Vector2(2400, 296)
	player.velocity = Vector2.ZERO
	for frame: int in range(3):
		await tree.physics_frame
	check(GameState.checkpoint == Vector2(2400, 296), "la sala del cable fija el checkpoint")
	player.position = Vector2(920, 392)
	await tree.physics_frame
	await tree.physics_frame
	check(player.state == PacketPlayer.State.DEAD, "caer al foso mata a Byte")
	GameState.retry()
	await tree.scene_changed
	level = tree.current_scene as World2Level1
	check(level != null, "reintentar conserva el mundo")
	if level == null:
		return
	player = level.player
	check(player.position == GameState.checkpoint, "reintentar restaura el checkpoint del cable")

	var puzzle: CablePuzzle = level.puzzle
	var shots: Array[Vector2i] = [Vector2i(0, 1), Vector2i(1, 1), Vector2i(1, 1),
		Vector2i(1, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0)]
	for cell: Vector2i in shots:
		var piece: CableCell = puzzle.cells[cell.y * CableGrid.SIZE.x + cell.x]
		var previous: int = piece.openings
		await _shoot_cable_cell(tree, player, piece)
		check(piece.openings == ((previous << 1) | (previous >> 3)) & 15,
			"el disparo gira la celda %s (máscara %d → %d)" % [cell, previous, piece.openings])
	check(puzzle.is_solved and puzzle.door.opened and GameState.puzzle_complete, "siete disparos reales abren la compuerta")
	if not puzzle.is_solved:
		return
	player.position = Vector2(World2Level1.WIDTH, 296)
	await tree.scene_changed
	var queen: WifiQueenBoss = tree.current_scene as WifiQueenBoss
	check(queen != null and GameState.current_world == 2 and GameState.in_boss, "la compuerta abre la arena de la Reina")
	if queen == null:
		return
	queen.set_physics_process(false)
	queen.player.set_physics_process(false)
	queen._physics_process(1.2)
	var projectile: Projectile = queen.pool.fire(true, Vector2(600, 200), Vector2.RIGHT * 160.0)
	queen.take_damage(27.0, Vector2.ZERO)
	check(queen.phase == 2 and queen.body.invulnerable and queen.card.visible
		and is_equal_approx(queen.timer, 2.4) and not projectile.active, "el 70 % muestra la fase 2 y limpia las balas")
	queen.take_damage(27.0, Vector2.ZERO)
	queen._physics_process(2.39)
	check(is_equal_approx(queen.health.current, 63.0) and queen.body.invulnerable, "la transición conserva la invulnerabilidad")
	queen._physics_process(0.01)
	queen.take_damage(27.0, Vector2.ZERO)
	check(queen.phase == 3 and queen.body.invulnerable, "el 40 % inicia la fase 3")
	queen._physics_process(2.4)
	queen.player.position = Vector2(120, 288)
	queen.player.interact()
	queen._physics_process(1.1)
	check(is_equal_approx(queen.player.health.current, 3.0), "la cúpula protege de una franja activa")
	queen.player.position = Vector2(50, 288)
	queen._physics_process(0.1)
	check(is_equal_approx(queen.player.health.current, 2.0), "la interferencia fuera de la cúpula quita un PV")
	queen.player.invulnerability = 0.0
	queen._physics_process(0.1)
	check(is_equal_approx(queen.player.health.current, 2.0), "la franja golpea una vez por activación")
	queen.take_damage(36.0, Vector2.ZERO)
	queen._physics_process(0.8)
	await tree.scene_changed
	var saved: Dictionary = SaveManager.load_game()
	check(tree.current_scene.scene_file_path == GameState.MAP, "la victoria vuelve al mapa")
	check("w2_boss" in saved["completed_levels"] and GameState.is_world_unlocked(saved, 3)
		and not GameState.is_world_playable(saved, 3), "la victoria guardada desbloquea Firewall como próximo mundo")

func _shoot_cable_cell(tree: SceneTree, player: PacketPlayer, piece: CableCell) -> void:
	player.position = Vector2(piece.global_position.x, 296)
	player.velocity = Vector2.ZERO
	for frame: int in range(3):
		await tree.physics_frame
	Input.action_press(&"aim_up")
	if piece.cell.y < CableGrid.SIZE.y - 1:
		# El cañón debe pasar por delante de la fila inferior antes de disparar.
		Input.action_press(&"jump")
		for frame: int in range(30):
			await tree.physics_frame
			if player.position.y < piece.global_position.y + CablePuzzle.CELL_SIZE:
				break
	else:
		# physics_frame precede la actualización de mira de Byte.
		await tree.physics_frame
		await tree.physics_frame
	player.shoot()
	Input.action_release(&"aim_up")
	Input.action_release(&"jump")
	for frame: int in range(9):
		await tree.physics_frame

func _require_scene(path: String) -> PackedScene:
	if not ResourceLoader.exists(path):
		errors.append("falta " + path.get_file())
		return null
	return load(path) as PackedScene

func _require_script(path: String) -> Script:
	if not ResourceLoader.exists(path):
		errors.append("falta " + path.get_file())
		return null
	return load(path) as Script

func check(condition: bool, message: String) -> void:
	if not condition:
		errors.append(message)
