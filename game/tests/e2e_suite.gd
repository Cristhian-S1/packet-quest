class_name E2ESuite
extends RefCounted

## Suite de extremo a extremo: un BOT conduce a Byte de verdad (solo
## Input.action_press/action_release) desde el menú principal hasta derrotar a la
## Reina Wi-Fi, pasando por el Router Furioso. No teletransporta a Byte ni toca
## posiciones/velocidades salvo para fijar el estado inicial de la partida.

const NetworkMap = preload("res://scripts/main/network_map.gd")

var tree: SceneTree
var pilot: BotPilot
var errors: PackedStringArray = []
var finished: bool = false
var save_path: String
var original_save_path: String

# --- API del runner ------------------------------------------------------

func run(scene_tree: SceneTree) -> PackedStringArray:
	tree = scene_tree
	pilot = BotPilot.new(tree)
	errors = []
	finished = false
	_reset_state()
	await _boot_to_menu()
	if not await _menu_to_world1():
		_finish()
		return errors
	if not await _traverse_level1():
		_finish()
		return errors
	if not await _fight_router():
		_finish()
		return errors
	if not await _router_victory_to_map():
		_finish()
		return errors
	check(GameState.is_world_unlocked(GameState.data, 2), "derrotar al Router no desbloquea Wi-Fi")
	if not await _map_to_world2():
		_finish()
		return errors
	if not await _traverse_level2():
		_finish()
		return errors
	if not await _fight_queen():
		_finish()
		return errors
	await _queen_victory()
	check(GameState.is_world_unlocked(GameState.data, 3), "derrotar a la Reina no desbloquea Firewall")
	_finish()
	return errors

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
	await tree.process_frame

func _await_scene_change(max_frames: int = 240) -> bool:
	var initial: Node = tree.current_scene
	for _i: int in range(max_frames):
		await tree.process_frame
		if tree.current_scene != null and tree.current_scene != initial:
			return true
	return false

func _player() -> PacketPlayer:
	return tree.get_first_node_in_group(&"player") as PacketPlayer

# --- Menú → mapa → Mundo 1 ---------------------------------------------

func _menu_to_world1() -> bool:
	# PENDIENTE: action_press actualiza el estado de Input, pero Godot no envía
	# un InputEvent al botón enfocado. La navegación GUI necesita otra vía.
	await pilot.confirm()
	if not await _await_scene_change():
		check(false, "el menú no abre el mapa al pulsar Jugar")
		return false
	check(tree.current_scene is NetworkMap, "Jugar no lleva al mapa")
	var map: NetworkMap = tree.current_scene as NetworkMap
	if map == null:
		return false
	await tree.process_frame
	# El botón Entrar tiene el foco; Enter entra en el mundo seleccionado (1).
	await pilot.confirm()
	if not await _await_scene_change():
		check(false, "el mapa no abre el mundo 1 al pulsar Entrar")
		return false
	check(tree.current_scene is World1Level1, "Entrar no carga el nivel 1-1")
	return tree.current_scene is World1Level1

# --- Travesía del nivel 1-1 ---------------------------------------------

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
		# Reaparece en safe_position; se reengancha moviéndose a la derecha.
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
			# Sube a la plataforma para quedar a ≤ 24 px del nodo superior.
			Input.action_press(&"jump")
			await pilot.wait_until(func() -> bool: return player.is_on_floor() and player.global_position.y < 270.0, 90)
			Input.action_release(&"jump")
		var needed: int = (puzzle.solution[index] - node.direction + 4) % 4
		for _turn: int in range(needed):
			await pilot.tap(&"interact")
			await pilot.frames(2)
	check(puzzle.is_solved, "interact no conecta la ruta emisor→receptor")

func _move_to(player: PacketPlayer, target_x: float) -> void:
	var direction: StringName = &"move_right" if target_x >= player.global_position.x else &"move_left"
	Input.action_press(direction)
	await pilot.wait_until(
		func() -> bool: return (direction == &"move_right" and player.global_position.x >= target_x) or (direction == &"move_left" and player.global_position.x <= target_x), 600)
	Input.action_release(direction)
	await pilot.frames(2)

# --- Router Furioso -----------------------------------------------------

func _fight_router() -> bool:
	var boss: RouterBoss = tree.current_scene as RouterBoss
	if boss == null:
		return false
	var player: PacketPlayer = boss.player
	# Apunta recto hacia arriba y dispárame sin moverte: el cuerpo del Router
	# ocupa x 240–400, así que disparar bajo x=248 lo alcanza de lleno.
	Input.action_press(&"lock_aim")
	Input.action_press(&"aim_up")
	Input.action_press(&"shoot")
	await _move_to(player, 248.0)
	var jump_frames := 0
	var pending_jump := -1
	var prev_state: RouterBoss.State = boss.state
	var guard := 0
	while boss.state != RouterBoss.State.DEFEATED and player.health.current > 0.0:
		await tree.physics_frame
		guard += 1
		if guard > 6000:
			break
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
				&"C":  # láser horizontal a la altura de Byte: cambia de altura.
					pending_jump = 1
		prev_state = boss.state
	var won: bool = boss.state == RouterBoss.State.DEFEATED
	if won:
		# Recoge el núcleo que suelta el jefe (aparece a los 0,6 s en x=320).
		await pilot.wait_until(func() -> bool: return tree.paused, 600)
		if not tree.paused:
			# El núcleo aún no se ha recogido: camina hacia él.
			Input.action_press(&"move_right")
			await pilot.wait_until(func() -> bool: return tree.paused, 400)
			Input.action_release(&"move_right")
	else:
		check(false, "el bot no derrota al Router (PV restantes %.0f, fase %d)" % [boss.health.current, boss.phase])
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
	return reached

# --- Mapa → Mundo 2 -----------------------------------------------------

func _map_to_world2() -> bool:
	var map: NetworkMap = tree.current_scene as NetworkMap
	if map == null:
		return false
	await tree.process_frame
	await tree.process_frame
	# Con el Mundo 2 desbloqueado ya hay 2 mundos jugables: pulsa → para elegir Wi-Fi.
	var selected2: bool = await pilot.wait_until(
		func() -> bool: return int(map.get(&"selected_world")) == 2, 120)
	if not selected2:
		# Intenta desplazar la selección con derecha (igual que el jugador).
		await pilot.tap(&"move_right")
		selected2 = await pilot.wait_until(
			func() -> bool: return int(map.get(&"selected_world")) == 2, 120)
	check(selected2, "el mapa no permite elegir Wi-Fi")
	if not selected2:
		return false
	await pilot.confirm()
	var entered: bool = await _await_scene_change()
	check(entered and tree.current_scene is World2Level1, "Entrar no carga el nivel 2-1")
	return entered and tree.current_scene is World2Level1

# --- Travesía del nivel 2-1 ---------------------------------------------

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
		check(false, "el bot muere en la sección de combate")
		return false
	Input.action_release(&"shoot")
	# Resuelve el puzle de cables disparando a las celdas.
	await _solve_cable_puzzle(world, player)
	if not world.puzzle.is_solved:
		check(false, "el puzle de cables no se resuelve a disparos")
		return false
	# Camina hasta el borde y entra en la Reina.
	Input.action_press(&"move_right")
	var entered: bool = await pilot.wait_until(
		func() -> bool: return tree.current_scene is WifiQueenBoss, 900)
	Input.action_release(&"move_right")
	check(entered, "la compuerta no lleva a la arena de la Reina")
	return entered

func _cross_waves_and_pit(world: World2Level1, player: PacketPlayer) -> void:
	Input.action_press(&"move_right")
	# Las ondas empujan; la zona de cobertura exige estar cerca del router.
	var crossed: bool = await pilot.wait_until(
		func() -> bool: return player.global_position.x >= 1040.0 and player.is_on_floor(), 2400)
	Input.action_release(&"move_right")
	if not crossed:
		# Reintenta saltando entre plataformas de cobertura.
		for _attempt: int in range(3):
			await _hop_coverage(player)
			if player.global_position.x >= 1040.0:
				return

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
		await _shoot_cell(player, piece)

func _shoot_cell(player: PacketPlayer, piece: CableCell) -> void:
	# Sitúa a Byte bajo la celda y dispara hacia arriba.
	await _move_to(player, piece.global_position.x)
	if piece.cell.y < CableGrid.SIZE.y - 1:
		Input.action_press(&"jump")
		await pilot.wait_until(
			func() -> bool: return player.global_position.y < piece.global_position.y + CablePuzzle.CELL_SIZE, 90)
		Input.action_release(&"jump")
		await pilot.frames(2)
	Input.action_press(&"aim_up")
	await pilot.physics_frames(2)
	Input.action_press(&"shoot")
	await pilot.physics_frames(2)
	Input.action_release(&"shoot")
	Input.action_release(&"aim_up")
	await pilot.frames(8)

# --- Reina Wi-Fi --------------------------------------------------------

func _fight_queen() -> bool:
	var queen: WifiQueenBoss = tree.current_scene as WifiQueenBoss
	if queen == null:
		return false
	var player: PacketPlayer = queen.player
	Input.action_press(&"aim_up")
	Input.action_press(&"shoot")
	var jump_frames := 0
	var pending_jump := -1
	var dash_left_frames := 0
	var prev_state: WifiQueenBoss.State = queen.state
	var prev_phase: int = queen.phase
	var guard := 0
	while queen.state != WifiQueenBoss.State.DEFEATED and player.health.current > 0.0:
		await tree.physics_frame
		guard += 1
		if guard > 12000:
			break
		if jump_frames > 0:
			jump_frames -= 1
			if jump_frames == 0:
				Input.action_release(&"jump")
		if pending_jump > 0:
			pending_jump -= 1
			if pending_jump == 0 and jump_frames == 0:
				Input.action_press(&"jump")
				jump_frames = 40
		# Mantente bajo la antena actual para disparar recto hacia arriba.
		var target_x: float = queen.body.global_position.x
		var dx: float = target_x - player.global_position.x
		if absf(dx) > 5.0:
			if dx > 0.0:
				Input.action_press(&"move_right")
				Input.action_release(&"move_left")
			else:
				Input.action_press(&"move_left")
				Input.action_release(&"move_right")
		else:
			Input.action_release(&"move_right")
			Input.action_release(&"move_left")
		# Esquiva según el aviso.
		if queen.state == WifiQueenBoss.State.TELEGRAPH and prev_state != WifiQueenBoss.State.TELEGRAPH:
			match queen.attack:
				WifiQueenBoss.Attack.WAVES:
					pending_jump = 40
				WifiQueenBoss.Attack.PING:
					# Aléjate de la columna que marca el aviso.
					if player.global_position.x <= queen.get(&"_ping_x"):
						Input.action_press(&"move_left")
					else:
						Input.action_press(&"move_right")
				WifiQueenBoss.Attack.SPIRAL:
					pending_jump = 1
		prev_state = queen.state
		prev_phase = queen.phase
	var won: bool = queen.state == WifiQueenBoss.State.DEFEATED
	if not won:
		check(false, "el bot no derrota a la Reina (PV %.0f, fase %d)" % [queen.health.current, queen.phase])
	pilot.release_all()
	return won

func _queen_victory() -> void:
	# Al vencerla, GameState.open_map() devuelve al mapa (DEFEATED lo programa).
	await pilot.wait_until(func() -> bool: return tree.current_scene is NetworkMap, 600)
	tree.paused = false
	check(tree.current_scene is NetworkMap, "vencer a la Reina no vuelve al mapa")
