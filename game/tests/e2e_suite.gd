class_name E2ESuite
extends RefCounted

## Suite de extremo a extremo: un BOT conduce a Byte de verdad (solo
## entrada de jugador) desde el menÃº principal hasta la arena de la Reina Wi-Fi,
## pasando por el Router Furioso. No teletransporta a Byte ni toca
## posiciones/velocidades salvo para fijar el estado inicial de la partida.

const NetworkMap = preload("res://scripts/main/network_map.gd")

var tree: SceneTree
var pilot: BotPilot
var errors: PackedStringArray = []
var finished: bool = false
var save_path: String
var original_save_path: String
var phase_started_ms: int

# --- API del runner ------------------------------------------------------

func run(scene_tree: SceneTree) -> PackedStringArray:
	tree = scene_tree
	pilot = BotPilot.new(tree)
	errors = []
	finished = false
	phase_started_ms = Time.get_ticks_msec()
	_reset_state()
	await _boot_to_menu()
	_checkpoint("inicio y menú")
	if not await _menu_to_world1():
		_finish()
		return errors
	_checkpoint("menú y mapa al mundo 1")
	if not await _traverse_level1():
		_finish()
		return errors
	_checkpoint("nivel 1-1")
	if not await _fight_router():
		_finish()
		return errors
	_checkpoint("Router")
	if not await _router_victory_to_map():
		_finish()
		return errors
	_checkpoint("victoria Router y mapa")
	check(GameState.is_world_unlocked(GameState.data, 2), "derrotar al Router no desbloquea Wi-Fi")
	if not await _map_to_world2():
		_finish()
		return errors
	_checkpoint("mapa al mundo 2")
	if not await _traverse_level2():
		_finish()
		return errors
	_checkpoint("nivel 2-1")
	await _capture("07_reina_wifi")
	if not await _fight_queen():
		_checkpoint("Reina Wi-Fi (FAIL)")
		_finish()
		return errors
	await _capture("08_reina_vencida")
	await _queen_victory()
	_checkpoint("Reina y mapa")
	if not await _world3():
		_finish()
		return errors
	if not await _world4():
		_finish()
		return errors
	if not await _world5():
		_finish()
		return errors
	_finish()
	return errors

func _checkpoint(label: String) -> void:
	var now := Time.get_ticks_msec()
	print("Fase %s: %.3f s" % [label, float(now - phase_started_ms) / 1000.0])
	phase_started_ms = now

func _finish() -> void:
	pilot.release_all()
	GameState.playing = false
	tree.paused = false
	SaveManager.save_path = original_save_path
	if FileAccess.file_exists(save_path):
		DirAccess.remove_absolute(save_path)
	finished = true

# --- Utilidades ---------------------------------------------------------

func check(condition: bool, message: String) -> void:
	if not condition:
		errors.append(message)
		printerr("E2E: " + message)

func _reset_state() -> void:
	original_save_path = SaveManager.save_path
	save_path = "user://e2e_session_%d.json" % OS.get_process_id()
	SaveManager.save_path = save_path
	GameState.data = SaveManager.defaults()
	GameState.data["settings"]["reduce_flashes"] = OS.get_environment("E2E_REDUCE_FLASHES") == "1"
	print("Opciones e2e: assist_mode=%s reduce_flashes=%s" % [GameState.assist_mode, GameState.reduce_flashes])
	GameState.current_world = 1
	GameState.in_boss = false
	GameState.checkpoint = Vector2(48, 296)
	GameState.puzzle_complete = false
	GameState.playing = false
	GameState.boss_progress = 0.0
	tree.paused = false
	Engine.time_scale = 1.0

func _boot_to_menu() -> void:
	tree.change_scene_to_file("res://scenes/main/Main.tscn")
	await tree.scene_changed
	await tree.process_frame
	await _capture("01_menu")

func _capture(name: String) -> void:
	if OS.get_environment("E2E_CAPTURAS") != "1":
		return
	await RenderingServer.frame_post_draw
	var image: Image = tree.root.get_texture().get_image()
	var dir: String = ProjectSettings.globalize_path("res://../docs/capturas/e2e")
	DirAccess.make_dir_recursive_absolute(dir)
	var result: Error = image.save_png(dir.path_join(name + ".png"))
	check(result == OK, "no se pudo guardar captura %s: %s" % [name, result])
	await tree.process_frame

func _await_scene_change(initial: Node, max_frames: int = 240) -> bool:
	for _i: int in range(max_frames):
		await tree.process_frame
		if tree.current_scene != null and tree.current_scene != initial:
			return true
	return false

func _player() -> PacketPlayer:
	return tree.get_first_node_in_group(&"player") as PacketPlayer

# --- MenÃº â†’ mapa â†’ Mundo 1 ---------------------------------------------

func _menu_to_world1() -> bool:
	var initial: Node = tree.current_scene
	await pilot.confirm()
	if not await _await_scene_change(initial):
		check(false, "el menÃº no abre el mapa al pulsar Jugar")
		return false
	check(tree.current_scene is NetworkMap, "Jugar no lleva al mapa")
	var map: NetworkMap = tree.current_scene as NetworkMap
	if map == null:
		return false
	await _capture("02_mapa")
	await tree.process_frame
	# El botÃ³n Entrar tiene el foco; Enter entra en el mundo seleccionado (1).
	initial = tree.current_scene
	await pilot.confirm()
	if not await _await_scene_change(initial):
		check(false, "el mapa no abre el mundo 1 al pulsar Entrar")
		return false
	check(tree.current_scene is World1Level1, "Entrar no carga el nivel 1-1")
	return tree.current_scene is World1Level1

# --- TravesÃ­a del nivel 1-1 ---------------------------------------------

func _traverse_level1() -> bool:
	var world: World1Level1 = tree.current_scene as World1Level1
	if world == null:
		return false
	var player: PacketPlayer = world.player
	# Avanza disparando: los Pop-up caen y los gusanos (por encima) se ignoran.
	Input.action_press(&"shoot")
	Input.action_press(&"move_right")
	var reached_gap: bool = await pilot.wait_until(
		func() -> bool: return player.global_position.x >= 720.0, 1600)
	if not reached_gap:
		check(false, "el bot no llega al hueco de 96 px (x=%d)" % int(player.global_position.x))
		Input.action_release(&"shoot")
		Input.action_release(&"move_right")
		return false
	# Salto + dash sobre el hueco de 96 px con aterrizaje elevado.
	await _cross_world1_gap(player)
	# Sigue hasta la sala del puzle y lo resuelve por interact.
	var reached_puzzle: bool = await pilot.wait_until(
		func() -> bool: return player.global_position.x >= 2330.0 and player.is_on_floor(), 2400)
	Input.action_release(&"move_right")
	if not reached_puzzle:
		check(false, "el bot no llega al puzle de ruta (x=%d)" % int(player.global_position.x))
		Input.action_release(&"shoot")
		return false
	await _solve_route_puzzle(world, player)
	Input.action_release(&"shoot")
	if not world.puzzle.is_solved:
		check(false, "el puzle de ruta no se resuelve con interact")
		return false
	await _capture("03_puzle_red_local")
	# Camina hasta la compuerta abierta y entra al jefe.
	Input.action_press(&"move_right")
	var entered: bool = await pilot.wait_until(
		func() -> bool: return tree.current_scene is RouterBoss, 600)
	Input.action_release(&"move_right")
	check(entered, "la compuerta no lleva a la arena del Router")
	return entered

func _cross_world1_gap(player: PacketPlayer) -> void:
	Input.action_press(&"jump")
	await pilot.physics_frames(16)
	Input.action_press(&"dash")
	await pilot.physics_frames(2)
	Input.action_release(&"dash")
	await pilot.physics_frames(20)
	Input.action_release(&"jump")
	# Espera a aterrizar al otro lado; si cae al foso reaparece y reintenta.
	for _attempt: int in range(4):
		var landed: bool = await pilot.wait_until(
			func() -> bool: return player.is_on_floor() and player.global_position.x >= 860.0, 240)
		if landed:
			return
		# Reaparece en safe_position; se reengancha moviÃ©ndose a la derecha.
		Input.action_press(&"move_right")
		var back: bool = await pilot.wait_until(
			func() -> bool: return player.global_position.x >= 720.0 and player.is_on_floor(), 400)
		if not back:
			return
		Input.action_press(&"jump")
		await pilot.physics_frames(16)
		Input.action_press(&"dash")
		await pilot.physics_frames(2)
		Input.action_release(&"dash")
		await pilot.physics_frames(20)
		Input.action_release(&"jump")

func _solve_route_puzzle(world: World1Level1, player: PacketPlayer) -> void:
	var puzzle: RoutePuzzle = world.puzzle
	# N1 en el suelo, N2 en el suelo, N3 sobre la plataforma de un solo sentido.
	var targets: Array[Vector2] = [Vector2(2340, 296), Vector2(2468, 296), Vector2(2468, 248)]
	for index: int in range(puzzle.nodes.size()):
		var node: PuzzleNode = puzzle.nodes[index]
		var target: Vector2 = targets[index]
		await _move_to(player, target.x)
		if index == 2:
			# Sube a la plataforma para quedar a â‰¤ 24 px del nodo superior.
			Input.action_press(&"jump")
			await pilot.wait_until(func() -> bool: return player.is_on_floor() and player.global_position.y < 270.0, 90)
			Input.action_release(&"jump")
		var needed: int = (puzzle.solution[index] - node.direction + 4) % 4
		for _turn: int in range(needed):
			await pilot.tap(&"interact")
			await pilot.frames(2)
	check(puzzle.is_solved, "interact no conecta la ruta emisorâ†’receptor")

func _move_to(player: PacketPlayer, target_x: float) -> void:
	var direction: StringName = &"move_right" if target_x >= player.global_position.x else &"move_left"
	Input.action_press(direction)
	await pilot.wait_until(
		func() -> bool: return (direction == &"move_right" and player.global_position.x >= target_x - 6.0) or (direction == &"move_left" and player.global_position.x <= target_x + 6.0), 600)
	Input.action_release(direction)
	await pilot.physics_frames(8)

# --- Router Furioso -----------------------------------------------------

func _fight_router() -> bool:
	var boss: RouterBoss = tree.current_scene as RouterBoss
	if boss == null:
		return false
	var player: PacketPlayer = boss.player
	await _capture("04_router")
	# Apunta recto hacia arriba y dispÃ¡rame sin moverte: el cuerpo del Router
	# ocupa x 240â€“400, asÃ­ que disparar bajo x=248 lo alcanza de lleno.
	await _move_to(player, 300.0)
	Input.action_press(&"aim_up")
	Input.action_press(&"shoot")
	var jump_frames := 0
	var pending_jump := -1
	var prev_state: RouterBoss.State = boss.state
	var guard := 0
	while boss.state != RouterBoss.State.DEFEATED and player.health.current > 0.0:
		await tree.physics_frame
		guard += 1
		if guard > 6000:
			break
		if player.global_position.x < 275.0:
			Input.action_press(&"move_right")
		elif player.global_position.x >= 300.0:
			Input.action_release(&"move_right")
		if jump_frames > 0:
			jump_frames -= 1
			if jump_frames == 0:
				Input.action_release(&"jump")
		if pending_jump > 0:
			pending_jump -= 1
			if pending_jump == 0 and jump_frames == 0:
				Input.action_press(&"jump")
				jump_frames = 44
		# El ataque se dispara al entrar en ACTIVE.
		if boss.state == RouterBoss.State.ACTIVE and prev_state == RouterBoss.State.TELEGRAPH:
			match boss.attack:
				&"B":  # estampida de paquetes por el suelo: salta cuando lleguen.
					pending_jump = 58
				&"C":  # lÃ¡ser horizontal a la altura de Byte: cambia de altura.
					pending_jump = 1
		prev_state = boss.state
	var won: bool = boss.state == RouterBoss.State.DEFEATED
	if won:
		# Recoge el nÃºcleo que suelta el jefe (aparece a los 0,6 s en x=320).
		await pilot.wait_until(func() -> bool: return boss.core_spawned, 120)
		if not tree.paused:
			# El nÃºcleo puede quedar a cualquiera de los lados tras el retroceso.
			var direction: StringName = &"move_right" if player.global_position.x < 320.0 else &"move_left"
			Input.action_press(direction)
			await pilot.wait_until(func() -> bool: return tree.paused, 400)
			Input.action_release(direction)
		if not tree.paused:
			check(false, "Byte no recoge el nÃºcleo del Router (posiciÃ³n %s)" % player.global_position)
			won = false
	else:
		check(false, "el bot no derrota al Router (PV restantes %.0f, fase %d, frame %d, Byte %s, PV %.0f, estado %d)" % [boss.health.current, boss.phase, guard, player.global_position, player.health.current, player.state])
	pilot.release_all()
	return won

func _router_victory_to_map() -> bool:
	# La pantalla de victoria aparece en pausa; pulsa "Continuar al mapa".
	await pilot.frames(4)
	await pilot.confirm()
	var reached: bool = await pilot.wait_until(
		func() -> bool: return tree.current_scene is NetworkMap, 400)
	tree.paused = false
	check(reached, "la victoria no vuelve al mapa")
	if reached:
		await _capture("05_wifi_desbloqueado")
	return reached

# --- Mapa â†’ Mundo 2 -----------------------------------------------------

func _map_to_world2() -> bool:
	var map: NetworkMap = tree.current_scene as NetworkMap
	if map == null:
		return false
	await tree.process_frame
	await tree.process_frame
	# Con el Mundo 2 desbloqueado ya hay 2 mundos jugables: pulsa â†’ para elegir Wi-Fi.
	var selected2: bool = await pilot.wait_until(
		func() -> bool: return int(map.get(&"selected_world")) == 2, 120)
	if not selected2:
		# Intenta desplazar la selecciÃ³n con derecha (igual que el jugador).
		await pilot.menu_tap(&"ui_right")
		selected2 = await pilot.wait_until(
			func() -> bool: return int(map.get(&"selected_world")) == 2, 120)
	check(selected2, "el mapa no permite elegir Wi-Fi")
	if not selected2:
		return false
	var initial: Node = tree.current_scene
	await pilot.confirm()
	var entered: bool = await _await_scene_change(initial)
	check(entered and tree.current_scene is World2Level1, "Entrar no carga el nivel 2-1")
	return entered and tree.current_scene is World2Level1

# --- TravesÃ­a del nivel 2-1 ---------------------------------------------

func _traverse_level2() -> bool:
	var world: World2Level1 = tree.current_scene as World2Level1
	if world == null:
		return false
	var player: PacketPlayer = world.player
	# Cruza la zona de ondas (empuje) y el foso de cobertura sobre plataformas.
	Input.action_press(&"shoot")
	await _cross_waves_and_pit(world, player)
	if player.health.current <= 0.0:
		check(false, "el bot muere cruzando la zona de cobertura")
		return false
	# Avanza combatiendo Spyware y Pop-ups hasta el puzle de cables.
	await _cross_combat_section(player)
	if player.health.current <= 0.0:
		check(false, "el bot muere en la secciÃ³n de combate")
		return false
	Input.action_release(&"shoot")
	# Resuelve el puzle de cables disparando a las celdas.
	await _solve_cable_puzzle(world, player)
	if not world.puzzle.is_solved:
		check(false, "el puzle de cables no se resuelve a disparos")
		return false
	await _capture("06_puzle_wifi")
	# Camina hasta el borde y entra en la Reina.
	Input.action_press(&"move_right")
	var entered: bool = await pilot.wait_until(
		func() -> bool: return tree.current_scene is WifiQueenBoss, 900)
	Input.action_release(&"move_right")
	check(entered, "la compuerta no lleva a la arena de la Reina")
	return entered

func _cross_waves_and_pit(world: World2Level1, player: PacketPlayer) -> void:
	Input.action_press(&"move_right")
	var approached: bool = await pilot.wait_until(
		func() -> bool: return player.global_position.x >= 760.0 and player.is_on_floor(), 1200)
	Input.action_release(&"move_right")
	if not approached:
		check(false, "no llega al foso: %s" % player.global_position)
		return
	for landing: Vector2 in [Vector2(810, 267), Vector2(880, 241), Vector2(950, 217), Vector2(1020, 249)]:
		await pilot.physics_frames(3)
		Input.action_press(&"move_right")
		Input.action_press(&"jump")
		var landed := false
		for frame: int in range(65):
			await tree.physics_frame
			if player.global_position.x >= landing.x:
				Input.action_release(&"move_right")
			if player.is_on_floor() and player.global_position.distance_to(landing) < 25.0:
				landed = true
				break
		Input.action_release(&"move_right")
		Input.action_release(&"jump")
		if not landed:
			check(false, "no alcanza plataforma %s: Byte %s, PV %.0f" % [landing, player.global_position, player.health.current])
			return
	Input.action_press(&"move_right")
	await pilot.wait_until(func() -> bool: return player.global_position.x >= 1060.0 and player.is_on_floor(), 120)
	Input.action_release(&"move_right")

func _hop_coverage(player: PacketPlayer) -> void:
	# Salta repetidamente manteniendo derecha para cruzar el foso.
	Input.action_press(&"move_right")
	for _i: int in range(6):
		Input.action_press(&"jump")
		await pilot.physics_frames(2)
		Input.action_release(&"jump")
		await pilot.physics_frames(18)
	Input.action_release(&"move_right")

func _cross_combat_section(player: PacketPlayer) -> void:
	Input.action_press(&"move_right")
	await pilot.wait_until(
		func() -> bool: return player.global_position.x >= 2360.0 and player.is_on_floor(), 3600)
	Input.action_release(&"move_right")
	Input.action_press(&"move_right")
	# Llega al checkpoint del puzle (x=2400).
	await pilot.wait_until(
		func() -> bool: return player.global_position.x >= 2400.0, 600)
	Input.action_release(&"move_right")

func _solve_cable_puzzle(world: World2Level1, player: PacketPlayer) -> void:
	var puzzle: CablePuzzle = world.puzzle
	# Mismas siete rotaciones que la prueba unitaria del Mundo 2.
	var shots: Array[Vector2i] = [Vector2i(0, 1), Vector2i(1, 1), Vector2i(1, 1),
		Vector2i(1, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0)]
	for cell: Vector2i in shots:
		var piece: CableCell = puzzle.cells[cell.y * CableGrid.SIZE.x + cell.x]
		var before: int = piece.openings
		for attempt: int in range(3):
			await _shoot_cell(player, piece)
			if piece.openings != before:
				break
		if piece.openings == before:
			check(false, "disparo no alcanzÃ³ celda %s: Byte %s" % [cell, player.global_position])
			return

func _shoot_cell(player: PacketPlayer, piece: CableCell) -> void:
	# SitÃºa a Byte bajo la celda y dispara hacia arriba.
	await pilot.wait_until(func() -> bool: return player.is_on_floor(), 120)
	await _move_to(player, piece.global_position.x)
	await pilot.wait_until(func() -> bool: return player.shoot_wait <= 0.0, 60)
	if piece.cell.y < CableGrid.SIZE.y - 1:
		Input.action_press(&"jump")
		await pilot.wait_until(
			func() -> bool: return player.global_position.y < piece.global_position.y + CablePuzzle.CELL_SIZE, 90)
		Input.action_release(&"jump")
		await pilot.frames(2)
	Input.action_press(&"aim_up")
	await pilot.physics_frames(2)
	Input.action_press(&"shoot")
	await pilot.wait_until(func() -> bool: return player.shoot_wait > 0.0, 30)
	Input.action_release(&"shoot")
	Input.action_release(&"aim_up")
	await pilot.frames(8)

# --- Reina Wi-Fi --------------------------------------------------------

func _fight_queen() -> bool:
	var result: bool = await load("res://tests/bot/queen_pilot.gd").fight(tree, tree.current_scene)
	check(result, "el bot no derrota a la Reina")
	pilot.release_all()
	return result

func _queen_victory() -> void:
	# Al vencerla, GameState.open_map() devuelve al mapa (DEFEATED lo programa).
	await pilot.wait_until(func() -> bool: return tree.current_scene is NetworkMap, 600)
	tree.paused = false
	check(tree.current_scene is NetworkMap, "vencer a la Reina no vuelve al mapa")

func _world3() -> bool:
	if not GameState.is_world_unlocked(GameState.data, 3):
		check(false, "la Reina no desbloquea Firewall")
		return false
	var map: NetworkMap = tree.current_scene as NetworkMap
	while map.selected_world != 3:
		await pilot.menu_tap(&"ui_right")
	await pilot.confirm()
	if not await pilot.wait_until(func() -> bool: return tree.current_scene is World3Level1, 240):
		check(false, "no se abre el mundo 3")
		return false
	_checkpoint("mapa al mundo 3")
	var world: World3Level1 = tree.current_scene as World3Level1
	var player: PacketPlayer = world.player
	player.health.changed.connect(func(current: float, _maximum: float) -> void: print("Mundo 3: PV %.0f Byte %s" % [current, player.position]))
	Input.action_press(&"move_right")
	for approach: float in [210.0, 375.0]:
		await pilot.wait_until(func() -> bool: return player.position.x >= approach or player.health.current <= 0.0, 300)
		Input.action_press(&"jump")
		await pilot.physics_frames(35)
		Input.action_release(&"jump")
		await pilot.wait_until(func() -> bool: return player.is_on_floor() or player.health.current <= 0.0, 100)
		Input.action_release(&"move_right")
		Input.action_press(&"move_left")
		Input.action_press(&"lock_aim")
		Input.action_press(&"shoot")
		await pilot.physics_frames(65)
		Input.action_release(&"shoot")
		Input.action_release(&"lock_aim")
		Input.action_release(&"move_left")
		Input.action_press(&"move_right")
		await pilot.physics_frames(2)
	Input.action_release(&"move_right")
	for laser_x: float in [664.0, 880.0]:
		if not await _cross_port(world, player, laser_x):
			return false
	Input.action_press(&"move_right")
	await pilot.wait_until(func() -> bool: return player.position.x >= 950.0 or player.health.current <= 0.0, 1200)
	if player.health.current <= 0.0 or player.position.x < 950.0:
		check(false, "mundo 3: no llega al foso: Byte %s PV %.0f" % [player.position, player.health.current])
		return false
	await _cross_world1_gap(player)
	Input.action_release(&"move_right")
	if not await _cross_port(world, player, 1160.0):
		return false
	Input.action_press(&"move_right")
	await pilot.wait_until(func() -> bool: return player.position.x >= 1250.0 or player.health.current <= 0.0, 180)
	Input.action_press(&"jump")
	await pilot.physics_frames(16)
	Input.action_press(&"dash")
	await pilot.physics_frames(2)
	Input.action_release(&"dash")
	await pilot.physics_frames(20)
	Input.action_release(&"jump")
	await pilot.wait_until(func() -> bool: return player.is_on_floor() or player.health.current <= 0.0, 120)
	await pilot.physics_frames(2)
	Input.action_press(&"jump")
	await pilot.physics_frames(32)
	Input.action_release(&"jump")
	await pilot.wait_until(func() -> bool: return player.is_on_floor() or player.health.current <= 0.0, 120)
	Input.action_release(&"move_right")
	# El Pop-up blindado queda detrás: eliminarlo evita sus disparos mientras
	# esperamos a que se abra el puerto siguiente.
	Input.action_press(&"move_left")
	Input.action_press(&"lock_aim")
	Input.action_press(&"shoot")
	await pilot.wait_until(func() -> bool:
		for enemy: Node in tree.get_nodes_in_group(&"enemies"):
			if enemy is ArmoredPopUp and absf(enemy.position.x - 1440.0) < 1.0 and enemy.state != EnemyBase.State.DEAD:
				return false
		return true, 180)
	Input.action_release(&"shoot")
	Input.action_release(&"lock_aim")
	Input.action_release(&"move_left")
	# Dejar que los disparos ya emitidos se alejen antes de avanzar tras ellos.
	Input.action_press(&"shield")
	await pilot.wait_until(func() -> bool:
		for bullet: Projectile in player.pool.enemy_bullets:
			if bullet.active and bullet.velocity.x > 0.0 and absf(bullet.position.x - player.position.x) < 250.0:
				return false
		return true, 180)
	Input.action_release(&"shield")
	await pilot.wait_until(func() -> bool: return player.shield_meter > 90.0 or player.health.current <= 0.0, 300)
	Input.action_press(&"shield")
	if not await _cross_port(world, player, 1608.0):
		Input.action_release(&"shield")
		return false
	Input.action_release(&"shield")
	Input.action_press(&"move_right")
	for approach: float in [1640.0, 1760.0]:
		await pilot.wait_until(func() -> bool: return player.position.x >= approach or player.health.current <= 0.0, 200)
		Input.action_press(&"jump")
		await pilot.physics_frames(35)
		Input.action_release(&"jump")
		await pilot.wait_until(func() -> bool: return player.is_on_floor() or player.health.current <= 0.0, 100)
		await pilot.physics_frames(2)
	await pilot.wait_until(func() -> bool: return player.position.x >= 2380.0 or player.health.current <= 0.0, 1800)
	Input.action_release(&"move_right")
	Input.action_release(&"shoot")
	if player.health.current <= 0.0 or player.position.x < 2380.0:
		check(false, "mundo 3: no llega al puzle: Byte %s PV %.0f" % [player.position, player.health.current])
		return false
	var puzzle: FirewallPuzzle = world.puzzle
	while puzzle.packet_index < puzzle.get(&"_packets").size():
		var packet: Dictionary = puzzle.get(&"_packets")[puzzle.packet_index]
		var allowed: bool = FirewallFilter.is_allowed(packet["shape"], packet["color"], FirewallFilter.TRIANGLE, FirewallFilter.RED)
		var node: NetworkNode = puzzle.pass_node if allowed else puzzle.block_node
		await _move_to(player, node.global_position.x)
		var before: int = puzzle.packet_index
		await pilot.tap(&"interact")
		await pilot.frames(2)
		if puzzle.packet_index == before:
			check(false, "mundo 3: terminal no responde en %s" % player.position)
			return false
	if not puzzle.is_solved:
		check(false, "mundo 3: filtro no resuelto")
		return false
	Input.action_press(&"move_right")
	var entered: bool = await pilot.wait_until(func() -> bool: return tree.current_scene is FirewallBoss, 800)
	Input.action_release(&"move_right")
	check(entered, "mundo 3: no se abre arena Firewall")
	_checkpoint("nivel 3-1")
	if not entered:
		return false
	var won: bool = await load("res://tests/bot/firewall_pilot.gd").fight(tree, tree.current_scene)
	pilot.release_all()
	check(won, "mundo 3: Firewall Corrupto no vencido")
	if not won:
		return false
	await _capture("09_firewall_vencido")
	var map_reached: bool = await pilot.wait_until(func() -> bool: return tree.current_scene is NetworkMap, 600)
	check(map_reached and GameState.is_world_unlocked(GameState.data, 4), "Firewall no vuelve al mapa o no desbloquea Servidor")
	_checkpoint("Firewall y mapa")
	return map_reached and GameState.is_world_unlocked(GameState.data, 4)

func _cross_port(world: Node2D, player: PacketPlayer, x: float) -> bool:
	Input.action_press(&"move_right")
	await pilot.wait_until(func() -> bool: return player.position.x >= x - 30.0 or player.health.current <= 0.0, 1200)
	Input.action_release(&"move_right")
	var laser: PortLaser
	for node: Node in world.get_children():
		if node is PortLaser and is_equal_approx((node as PortLaser).position.x, x):
			laser = node as PortLaser
			break
	if laser == null:
		check(false, "puerto %.0f no encontrado" % x)
		return false
	await pilot.wait_until(func() -> bool: return (laser.get(&"_state") == &"open" and fposmod(float(laser.get(&"_age")), 3.0) < 1.95) or player.health.current <= 0.0, 240)
	Input.action_press(&"move_right")
	await pilot.wait_until(func() -> bool: return player.position.x >= x + 20.0 or player.health.current <= 0.0, 120)
	Input.action_release(&"move_right")
	if player.health.current <= 0.0 or player.position.x < x + 20.0:
		check(false, "mundo 3: puerto %.0f Byte %s PV %.0f" % [x, player.position, player.health.current])
		return false
	return true

func _world4() -> bool:
	var map: NetworkMap = tree.current_scene as NetworkMap
	for _i: int in range(5):
		if map.selected_world == 4:
			break
		await pilot.menu_tap(&"ui_right")
	await pilot.confirm()
	if not await pilot.wait_until(func() -> bool: return tree.current_scene is World4Level1, 240):
		check(false, "mundo 4: no se abre Servidor")
		return false
	_checkpoint("mapa al mundo 4")
	var world: World4Level1 = tree.current_scene as World4Level1
	var player: PacketPlayer = world.player
	player.health.changed.connect(func(current: float, _maximum: float) -> void: print("Mundo 4: PV %.0f Byte %s" % [current, player.position]))
	Input.action_press(&"shoot")
	await _move_to(player, 760.0)
	var elevator: DataElevator = world.get_node("ElevatorS2") as DataElevator
	var riding := false
	for _i: int in range(360):
		await tree.physics_frame
		if player.is_on_floor() and player.position.y <= 215.0 and elevator.position.y <= 221.0:
			riding = true
			break
		if player.is_on_floor() and player.position.y > 290.0 and elevator.position.y >= 263.0:
			Input.action_press(&"jump")
			await pilot.physics_frames(34)
			Input.action_release(&"jump")
	if not riding:
		check(false, "mundo 4: ascensor no alcanzado Byte %s PV %.0f" % [player.position, player.health.current])
		return false
	Input.action_press(&"jump")
	await _move_to(player, 858.0)
	Input.action_release(&"jump")
	await pilot.physics_frames(24)
	Input.action_press(&"move_right")
	await pilot.wait_until(func() -> bool: return player.position.x >= 1170.0 or player.health.current <= 0.0, 600)
	Input.action_release(&"move_right")
	await _clear_trojan(world, player, 1400.0)
	Input.action_press(&"move_right")
	await pilot.wait_until(func() -> bool: return player.position.x >= 1300.0 or player.health.current <= 0.0, 600)
	Input.action_press(&"jump")
	await pilot.physics_frames(15)
	Input.action_press(&"dash")
	await pilot.physics_frames(2)
	Input.action_release(&"dash")
	await pilot.physics_frames(36)
	Input.action_release(&"jump")
	await pilot.wait_until(func() -> bool: return player.position.x >= 1534.0 or player.health.current <= 0.0, 900)
	if player.health.current <= 0.0:
		check(false, "mundo 4: Byte muere antes del foso en %s" % player.position)
		return false
	Input.action_release(&"move_right")
	await pilot.wait_until(func() -> bool: return player.is_on_floor() and player.cooldown <= 0.0 or player.health.current <= 0.0, 90)
	Input.action_press(&"move_right")
	Input.action_press(&"jump")
	await pilot.physics_frames(15)
	Input.action_press(&"dash")
	await pilot.physics_frames(2)
	Input.action_release(&"dash")
	await pilot.physics_frames(36)
	Input.action_release(&"jump")
	Input.action_release(&"move_right")
	await pilot.wait_until(func() -> bool: return player.is_on_floor() and player.cooldown <= 0.0 or player.health.current <= 0.0, 90)
	await _clear_trojan(world, player, 1800.0)
	Input.action_press(&"move_right")
	Input.action_press(&"jump")
	await pilot.physics_frames(15)
	Input.action_press(&"dash")
	await pilot.physics_frames(2)
	Input.action_release(&"dash")
	await pilot.physics_frames(36)
	Input.action_release(&"jump")
	await pilot.wait_until(func() -> bool: return player.position.x >= 2560.0 or player.health.current <= 0.0, 1200)
	Input.action_release(&"move_right")
	Input.action_release(&"shoot")
	if player.health.current <= 0.0 or player.position.x < 2560.0:
		check(false, "mundo 4: no llega al puzle Byte %s PV %.0f" % [player.position, player.health.current])
		return false
	var puzzle: PasswordPuzzle = world.puzzle
	for slot: PasswordSlot in puzzle.slots:
		await _move_to(player, slot.global_position.x)
		for _turn: int in range(3):
			await pilot.tap(&"interact")
			await pilot.frames(2)
	if not puzzle.is_solved:
		check(false, "mundo 4: contraseña no resuelta")
		return false
	Input.action_press(&"move_right")
	var entered: bool = await pilot.wait_until(func() -> bool: return tree.current_scene is TrojanBoss, 600)
	Input.action_release(&"move_right")
	check(entered, "mundo 4: no entra en Troyano Real")
	if not entered:
		return false
	_checkpoint("nivel 4-1")
	var won: bool = await load("res://tests/bot/trojan_pilot.gd").fight(tree, tree.current_scene)
	pilot.release_all()
	check(won, "mundo 4: Troyano Real no vencido")
	if not won:
		return false
	await _capture("10_troyano_vencido")
	var map_reached: bool = await pilot.wait_until(func() -> bool: return tree.current_scene is NetworkMap, 600)
	check(map_reached and GameState.is_world_unlocked(GameState.data, 5), "Troyano no vuelve al mapa o no desbloquea Centro de datos")
	_checkpoint("Troyano y mapa")
	return map_reached and GameState.is_world_unlocked(GameState.data, 5)

func _clear_trojan(world: World4Level1, player: PacketPlayer, center: float) -> void:
	var target: Trojan
	for node: Node in tree.get_nodes_in_group(&"enemies"):
		if node is Trojan and absf(float(node.get(&"_patrol_center")) - center) < 5.0:
			target = node as Trojan
			break
	if target == null:
		return
	var jump_left := 0
	for _i: int in range(600):
		await tree.physics_frame
		if not is_instance_valid(target) or target.state == EnemyBase.State.DEAD or player.health.current <= 0.0:
			break
		if jump_left > 0:
			jump_left -= 1
			if jump_left == 0:
				Input.action_release(&"jump")
		var danger := false
		for bullet: Projectile in player.pool.enemy_bullets:
			if bullet.active:
				for tick: int in range(1, 13):
					var future: Vector2 = bullet.position + bullet.velocity * (tick / 60.0) + bullet.acceleration * (0.5 * pow(tick / 60.0, 2))
					if absf(future.x - player.position.x) < 9.0 and absf(future.y - player.position.y) < 10.0:
						danger = true
						break
		if danger and player.is_on_floor() and jump_left == 0:
			Input.action_press(&"jump")
			jump_left = 35
	Input.action_release(&"jump")

func _world5() -> bool:
	var map: NetworkMap = tree.current_scene as NetworkMap
	for _i: int in range(5):
		if map.selected_world == 5:
			break
		await pilot.menu_tap(&"ui_right")
	await pilot.confirm()
	if not await pilot.wait_until(func() -> bool: return tree.current_scene is World5Level1, 240):
		check(false, "mundo 5: no se abre Centro de datos")
		return false
	_checkpoint("mapa al mundo 5")
	var world: World5Level1 = tree.current_scene as World5Level1
	var player: PacketPlayer = world.player
	player.health.changed.connect(func(current: float, _maximum: float) -> void: print("Mundo 5: PV %.0f Byte %s" % [current, player.position]))
	Input.action_press(&"shoot")
	await _move_to(player, 168.0)
	await pilot.wait_until(func() -> bool: return player.is_on_floor() and player.position.y < 184.0, 180)
	await _move_to(player, 779.0)
	await _jump_to_x(player, 827.0)
	await _move_to(player, 1065.0)
	if player.health.current <= 0.0 or player.position.x < 1040.0:
		check(false, "mundo 5: foso de cobertura Byte %s PV %.0f" % [player.position, player.health.current])
		return false
	for port_x: float in [1376.0, 1512.0]:
		if not await _cross_port(world, player, port_x):
			return false
	await _move_to(player, 1587.0)
	Input.action_press(&"move_right")
	Input.action_press(&"jump")
	await pilot.physics_frames(16)
	Input.action_press(&"dash")
	await pilot.physics_frames(2)
	Input.action_release(&"dash")
	await pilot.physics_frames(40)
	Input.action_release(&"jump")
	Input.action_release(&"move_right")
	if not await _cross_port(world, player, 1848.0):
		return false
	for _attempt: int in range(3):
		await _move_to(player, 2629.0)
		if player.position.x >= 2600.0 or player.health.current <= 0.0:
			break
	if player.health.current <= 0.0 or player.position.x < 2600.0:
		check(false, "mundo 5: no llega a las nubes Byte %s PV %.0f" % [player.position, player.health.current])
		return false
	var crossed := false
	for attempt: int in range(5):
		var first: CloudPlatform = world.clouds[0]
		await pilot.wait_until(func() -> bool: return fposmod(float(first.get(&"_age")), 4.0) < 0.12, 240)
		for cloud: CloudPlatform in world.clouds:
			await _jump_to_x(player, cloud.position.x)
			print("Nube %.0f: Byte %s suelo %s estado %s edad %.2f PV %.0f" % [cloud.position.x, player.position, player.is_on_floor(), cloud.get(&"_state"), cloud.get(&"_age"), player.health.current])
			if player.health.current <= 0.0 or not player.is_on_floor() or absf(player.position.x - cloud.position.x) > 50.0:
				break
		if player.health.current > 0.0:
			Input.action_press(&"move_right")
			Input.action_press(&"jump")
			await pilot.physics_frames(3)
			Input.action_press(&"dash")
			await pilot.physics_frames(2)
			Input.action_release(&"dash")
			await pilot.wait_until(func() -> bool: return player.position.x >= 2938.0 or player.health.current <= 0.0, 120)
			Input.action_release(&"move_right")
			Input.action_release(&"jump")
		if player.health.current > 0.0 and player.position.x >= 2920.0:
			await _move_to(player, 2942.0)
			var final_port: PortLaser
			for node: Node in world.get_children():
				if node is PortLaser and is_equal_approx((node as PortLaser).position.x, 2976.0):
					final_port = node as PortLaser
					break
			if final_port != null:
				Input.action_press(&"shield")
				await pilot.wait_until(func() -> bool: return (final_port.get(&"_state") == &"open" and fposmod(float(final_port.get(&"_age")), 3.0) < 1.95) or player.health.current <= 0.0, 240)
				Input.action_release(&"shield")
			await _move_to(player, 3070.0)
		crossed = player.health.current > 0.0 and player.position.x >= 3040.0
		if crossed:
			break
		print("Mundo 5: intento de nubes %d fallido en %s" % [attempt + 1, player.position])
		if player.health.current > 0.0:
			await pilot.wait_until(func() -> bool: return player.health.current <= 0.0, 120)
		if player.health.current > 0.0:
			break
		pilot.release_all()
		var previous: Node = tree.current_scene
		await pilot.confirm()
		if not await _await_scene_change(previous, 240):
			break
		world = tree.current_scene as World5Level1
		player = world.player
		Input.action_press(&"shoot")
		await _move_to(player, 2629.0)
	if not crossed:
		check(false, "mundo 5: nubes no cruzadas Byte %s PV %.0f" % [player.position, player.health.current])
		return false
	Input.action_release(&"shoot")
	if player.health.current <= 0.0 or player.position.x < 3040.0:
		check(false, "mundo 5: no llega al QoS Byte %s PV %.0f" % [player.position, player.health.current])
		return false
	var puzzle: QosRoom = world.puzzle
	for id: StringName in QosPuzzle.PRIORITY:
		for node: QosNode in puzzle.nodes:
			if StringName(node.traffic_id) == id:
				await _move_to(player, node.global_position.x)
				await pilot.tap(&"interact")
				await pilot.frames(2)
				break
	if not puzzle.is_solved:
		check(false, "mundo 5: QoS no resuelto")
		return false
	Input.action_press(&"move_right")
	var entered: bool = await pilot.wait_until(func() -> bool: return tree.current_scene is MalwarexBoss, 600)
	Input.action_release(&"move_right")
	check(entered, "mundo 5: no entra en Malwarex")
	if not entered:
		return false
	_checkpoint("nivel 5-1")
	var won: bool = await load("res://tests/bot/malwarex_pilot.gd").fight(tree, tree.current_scene)
	pilot.release_all()
	check(won, "mundo 5: Malwarex no vencido")
	if not won:
		return false
	await _capture("11_malwarex_vencido")
	var reached: bool = await pilot.wait_until(func() -> bool: return tree.current_scene is CreditsScreen, 600)
	check(reached, "Malwarex no muestra los créditos")
	if not reached:
		return false
	var credits: CreditsScreen = tree.current_scene as CreditsScreen
	var expected: String = CreditsScreen.cores_line(GameState.data)
	var found := false
	for child: Node in credits.panel.get_children():
		if child is Label and (child as Label).text == expected:
			found = true
	check(found and expected.ends_with("/12"), "créditos no muestran el recuento %s" % expected)
	print("Créditos: %s" % expected)
	await _capture("12_creditos")
	_checkpoint("Malwarex y créditos")
	return found and expected.ends_with("/12")

func _jump_to_x(player: PacketPlayer, x: float) -> void:
	Input.action_press(&"jump")
	if is_equal_approx(x, 2780.0):
		# La nube central está más alta; el dash aporta alcance durante el salto.
		Input.action_press(&"move_right")
		await pilot.physics_frames(8)
		Input.action_press(&"dash")
		await pilot.physics_frames(2)
		Input.action_release(&"dash")
	await _move_to(player, x - 30.0 if is_equal_approx(x, 2780.0) else x)
	await pilot.wait_until(func() -> bool: return player.is_on_floor() or player.health.current <= 0.0, 100)
	Input.action_release(&"jump")
	await pilot.frames(3)
