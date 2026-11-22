extends RefCounted

var errors: PackedStringArray = []
var finished: bool = false

func run(tree: SceneTree) -> PackedStringArray:
	_test_world_progress()
	await _test_hazards(tree)
	await _test_armor(tree)
	await _test_filter(tree)
	await _test_boss(tree)
	await _test_level_route(tree)
	finished = true
	return errors

func _test_world_progress() -> void:
	GameState.current_world = 2
	check(not GameState.is_world_playable(GameState.data, 3), "Firewall comienza bloqueado")
	GameState.win()
	var saved: Dictionary = SaveManager.load_game()
	check(GameState.is_world_unlocked(saved, 3), "la victoria del mundo 2 desbloquea Firewall")
	check(GameState.WORLDS.has({
		"level": "res://scenes/levels/World3Level1.tscn", "boss": "res://scenes/bosses/FirewallBoss.tscn"
	}), "Mundo 3 registrado con el nivel y la arena")
	saved["unlocked_worlds"].append(5)
	check(not GameState.is_world_playable(saved, 5), "Centro de datos desbloqueado sigue sin escenas")


func _test_hazards(tree: SceneTree) -> void:
	var laser: Script = _require_script("res://scripts/objects/port_laser.gd")
	var bar: Script = _require_script("res://scripts/objects/rule_bar.gd")
	if laser == null or bar == null:
		return
	var times: Array[float] = [0.0, 1.5, 1.7, 2.4, 2.6, 3.1]
	var states: Array[StringName] = [&"blocked", &"blocked", &"open", &"open", &"warning", &"blocked"]
	for index: int in range(times.size()):
		check(laser.call(&"state_at", times[index]) == states[index], "láser a %.1f s" % times[index])
	var samples: Array[float] = [0.0, 1.6, 3.1]
	for cycle: int in range(7):
		for lane: int in range(samples.size()):
			check(int(bar.call(&"gap_lane", samples[lane] + cycle * 4.5)) == lane, "carril %d en ciclo %d" % [lane, cycle])

	var stage: Node2D = Node2D.new()
	tree.root.add_child(stage)
	var player: PacketPlayer = StageBuilder.player(stage, Vector2(160, 296), 640)
	player.set_physics_process(false)
	var port: Area2D = laser.new() as Area2D
	port.position = Vector2(160, 304)
	port.set(&"phase_offset", 2.6)
	stage.add_child(port)
	await tree.physics_frame
	await tree.physics_frame
	check(player.health.current == player.health.max_health, "el aviso del láser es inocuo")
	for _frame: int in range(31):
		await tree.physics_frame
	check(player.health.current == player.health.max_health - 1, "cerrar el puerto con Byte dentro quita un PV")
	port.queue_free()
	await tree.process_frame

	player.invulnerability = 0.0
	var rule: Area2D = bar.new() as Area2D
	rule.position.x = player.position.x
	stage.add_child(rule)
	await tree.physics_frame
	await tree.physics_frame
	check(player.health.current == player.health.max_health - 1, "el hueco inferior deja pasar a Byte")
	for _frame: int in range(94):
		await tree.physics_frame
	check(player.health.current == player.health.max_health - 2, "al cambiar de carril la parte sólida quita un PV")
	stage.queue_free()
	await tree.process_frame

func _require_script(path: String) -> Script:
	if not ResourceLoader.exists(path):
		errors.append("falta " + path.get_file())
		return null
	return load(path) as Script


func _test_armor(tree: SceneTree) -> void:
	var armor: Script = _require_script("res://scripts/enemies/armor_rule.gd")
	var popup_scene: PackedScene = _require_scene("res://scenes/enemies/ArmoredPopUp.tscn")
	var worm_scene: PackedScene = _require_scene("res://scenes/enemies/ArmoredWorm.tscn")
	if armor == null or popup_scene == null or worm_scene == null:
		return
	check(bool(armor.call(&"blocks", Vector2.LEFT, Vector2.ZERO, Vector2.LEFT)), "blindaje frontal")
	check(not bool(armor.call(&"blocks", Vector2.RIGHT, Vector2.ZERO, Vector2.LEFT)), "la espalda está expuesta")
	check(not bool(armor.call(&"blocks", Vector2.UP, Vector2.ZERO, Vector2.LEFT)), "el producto nulo no bloquea")

	var stage: Node2D = Node2D.new()
	tree.root.add_child(stage)
	var pool: ProjectilePool = ProjectilePool.new()
	stage.add_child(pool)
	var player: PacketPlayer = StageBuilder.player(stage, Vector2(100, 296), 640)
	player.set_physics_process(false)
	var popup: EnemyBase = popup_scene.instantiate() as EnemyBase
	popup.position = Vector2(160, 296)
	stage.add_child(popup)
	await tree.physics_frame
	pool.fire(false, player.global_position, Vector2.RIGHT * 480.0)
	for _frame: int in range(10):
		await tree.physics_frame
	check(popup.health.current == 4.0, "una bala frontal del pool deja intacto al Pop-up")
	pool.fire(false, Vector2(220, 296), Vector2.LEFT * 480.0)
	for _frame: int in range(10):
		await tree.physics_frame
	check(popup.health.current == 3.0, "una bala trasera le quita un PV al Pop-up")

	var worm: NetworkWorm = worm_scene.instantiate() as NetworkWorm
	worm.position = Vector2(300, 288)
	stage.add_child(worm)
	await tree.physics_frame
	await tree.physics_frame
	var facing: Vector2 = worm.get(&"facing")
	worm.take_damage(1.0, worm.global_position + facing)
	check(worm.health.current == 6.0 and not worm.pending_attack, "el Gusano bloquea delante y conserva sus paquetes")
	worm.take_damage(1.0, worm.global_position - facing)
	check(worm.health.current == 5.0 and worm.pending_attack, "la espalda del Gusano activa la división")
	for _frame: int in range(120):
		await tree.physics_frame
	check(worm.get(&"facing") == -facing, "el blindaje del Gusano sigue el sentido de su cable")
	stage.queue_free()
	await tree.process_frame

func _require_scene(path: String) -> PackedScene:
	if not ResourceLoader.exists(path, "PackedScene"):
		errors.append("falta " + path.get_file())
		return null
	return load(path) as PackedScene


func _test_filter(tree: SceneTree) -> void:
	var filter: Script = _require_script("res://scripts/puzzles/firewall_filter.gd")
	var scene: PackedScene = _require_scene("res://scenes/puzzles/FirewallPuzzle.tscn")
	if filter == null or scene == null:
		return
	var enums: Dictionary = filter.get_script_constant_map()
	var circle: int = enums["CIRCLE"]
	var triangle: int = enums["TRIANGLE"]
	var square: int = enums["SQUARE"]
	var red: int = enums["RED"]
	var green: int = enums["GREEN"]
	var blue: int = enums["BLUE"]
	for shape: int in [circle, triangle, square]:
		for color: int in [red, green, blue]:
			check(bool(filter.call(&"is_allowed", shape, color, triangle, red)) == (shape == triangle and color != red),
				"filtro para forma %d y color %d" % [shape, color])
	var sequence: Array[Dictionary] = filter.call(&"generate_sequence", 0)
	var expected: Array[Vector2i] = [Vector2i(circle, red), Vector2i(triangle, green), Vector2i(square, red),
		Vector2i(triangle, red), Vector2i(triangle, blue), Vector2i(circle, green),
		Vector2i(triangle, green), Vector2i(square, blue), Vector2i(circle, blue), Vector2i(triangle, green)]
	check(sequence.size() == 10, "la cinta prepara diez paquetes")
	var allowed: int = 0
	for index: int in range(mini(sequence.size(), expected.size())):
		var packet: Dictionary = sequence[index]
		check(Vector2i(packet["shape"], packet["color"]) == expected[index], "paquete %d de la secuencia canónica" % [index + 1])
		allowed += int(filter.call(&"is_allowed", packet["shape"], packet["color"], triangle, red))
	check(allowed == 4 and sequence.size() - allowed == 6, "cuatro permitidos y seis bloqueados")
	check(sequence == filter.call(&"generate_sequence", 0) and sequence != filter.call(&"generate_sequence", 1), "la semilla determina el orden")

	var puzzle: Node2D = scene.instantiate() as Node2D
	tree.root.add_child(puzzle)
	var pass_node: NetworkNode = puzzle.get(&"pass_node") as NetworkNode
	var block_node: NetworkNode = puzzle.get(&"block_node") as NetworkNode
	var reset_node: NetworkNode = puzzle.get(&"reset_node") as NetworkNode
	var door: PacketDoor = puzzle.get(&"door") as PacketDoor
	var solved_calls: Array[bool] = []
	puzzle.connect(&"solved", func() -> void: solved_calls.append(true))
	for wrong_count: int in [3, 2]:
		for index: int in range(sequence.size()):
			var packet: Dictionary = sequence[index]
			var pass_packet: bool = bool(filter.call(&"is_allowed", packet["shape"], packet["color"], triangle, red))
			if index < wrong_count:
				pass_packet = not pass_packet
			var node: NetworkNode = pass_node if pass_packet else block_node
			node.interact()
		check(int(puzzle.get(&"mistakes")) == wrong_count, "la cinta recorre todos los paquetes y suma los fallos")
		check(door.opened == (wrong_count <= 2) and GameState.puzzle_complete == door.opened,
			"la compuerta aplica el límite de dos fallos")
		reset_node.interact()
		check(int(puzzle.get(&"packet_index")) == 0 and int(puzzle.get(&"mistakes")) == 0 and not door.opened,
			"el reinicio restaura el paquete inicial y cierra la puerta")
	check(solved_calls.size() == 1 and AudioManager.last_sfx == &"firewall_connected", "el éxito emite solved y reproduce la conexión")
	puzzle.queue_free()
	await tree.process_frame


func _test_boss(tree: SceneTree) -> void:
	var scene: PackedScene = _require_scene("res://scenes/bosses/FirewallBoss.tscn")
	if scene == null:
		return
	var boss: Node2D = scene.instantiate() as Node2D
	var script: Script = boss.get_script() as Script
	for ratio: float in [1.0, 0.70, 0.69, 0.40, 0.39]:
		var expected_phase: int = 1 if ratio > 0.70 else (2 if ratio > 0.40 else 3)
		check(int(script.call(&"phase_for", ratio)) == expected_phase, "fase para %.2f PV" % ratio)
	for index: int in range(21):
		check(int(script.call(&"rule_gap_lane", index)) == index % 3, "carril de barrido %d" % index)
		check(int(script.call(&"correct_port", index)) == index % 3, "puerto de ciclo %d" % index)
	for input: Vector3 in [Vector3(0, 0, 480), Vector3(5, 0, 360), Vector3(5, 10, 440),
			Vector3(100, 0, 160), Vector3(0, 50, 480)]:
		check(is_equal_approx(float(script.call(&"wall_x", input.x, int(input.y))), input.z), "límite de avance %s" % input)

	tree.root.add_child(boss)
	boss.set_physics_process(false)
	var player: PacketPlayer = boss.get(&"player") as PacketPlayer
	player.set_physics_process(false)
	var health: HealthComponent = boss.get(&"health") as HealthComponent
	var core: Hurtbox = boss.get(&"core") as Hurtbox
	var card: Label = boss.get(&"card") as Label
	var pool: ProjectilePool = boss.get(&"pool") as ProjectilePool
	check(health.current == 120.0 and core.invulnerable and core.homing_target, "el núcleo del Firewall empieza cerrado")
	boss.call(&"_physics_process", 1.2)
	boss.call(&"_physics_process", 1.1)
	check(core.invulnerable, "el aviso del puerto F1 conserva la invulnerabilidad")
	boss.call(&"_physics_process", 0.6)
	check(not core.invulnerable and core.global_position == Vector2(520, 176), "F1 abre su puerto central")
	pool.fire(false, Vector2(450, 247), Vector2.RIGHT * 480.0)
	for _frame: int in range(12):
		await tree.physics_frame
	check(health.current == 120.0, "el mundo absorbe las balas fuera del puerto")
	player.position = Vector2(322, 249)
	player.set_physics_process(true)
	for _frame: int in range(3):
		await tree.physics_frame
	Input.action_press(&"jump")
	for _frame: int in range(30):
		await tree.physics_frame
		if player.position.y <= 194.0:
			break
	Input.action_press(&"shoot")
	await tree.physics_frame
	await tree.physics_frame
	Input.action_release(&"shoot")
	Input.action_release(&"jump")
	for _frame: int in range(30):
		await tree.physics_frame
	check(health.current == 119.0, "Byte salta desde el chip y su disparo horizontal acierta por el puerto central")
	player.set_physics_process(false)
	player.position = Vector2(64, 296)

	var shot: Projectile = pool.fire(true, Vector2(340, 140), Vector2.LEFT * 100)
	core.take_damage(35.0, Vector2.ZERO)
	check(int(boss.get(&"phase")) == 2 and core.invulnerable and card.visible and not shot.active,
		"el 70 % muestra la tarjeta, cierra el núcleo y limpia proyectiles")
	boss.call(&"_physics_process", 2.39)
	core.take_damage(36.0, Vector2.ZERO)
	check(health.current == 84.0 and core.invulnerable, "el cambio mantiene 2,4 s de invulnerabilidad")
	boss.call(&"_physics_process", 0.01)
	check(core.position.y == 184.0 and not core.invulnerable and not card.visible, "F2 empieza por el puerto alto")
	boss.call(&"_physics_process", 1.21)
	check(core.position.y == 240.0, "F2 continúa por el puerto medio")
	check(player.health.current == 3.0, "el aviso del láser horizontal es inocuo")
	boss.call(&"_physics_process", 1.2)
	check(core.position.y == 288.0, "F2 termina por el puerto bajo")

	core.take_damage(36.0, Vector2.ZERO)
	check(int(boss.get(&"phase")) == 2 and core.invulnerable, "el láser en curso termina antes de la pausa")
	boss.call(&"_physics_process", 0.45)
	check(player.health.current == 2.0, "el láser activo quita un PV a la altura señalada")
	Engine.time_scale = 1.0
	check(int(boss.get(&"phase")) == 3 and core.invulnerable and card.visible, "el 40 % inicia la fase de avance")
	boss.call(&"_physics_process", 2.4)
	check(core.global_position == Vector2(520, 176) and not core.invulnerable, "F3 expone el puerto central")
	boss.call(&"_physics_process", 5.0)
	check(is_equal_approx(core.global_position.x, 400.0), "el núcleo avanza con el muro")
	pool.fire(false, Vector2(320, 219), Vector2.RIGHT * 480.0)
	for _frame: int in range(12):
		await tree.physics_frame
	check(is_equal_approx(core.global_position.x, 408.0) and health.current == 48.0,
		"disparar a un ladrillo lo empuja ocho píxeles (núcleo: %s, PV: %s)" % [core.global_position, health.current])
	boss.call(&"_physics_process", 60.0)
	check(is_equal_approx(core.global_position.x, 200.0), "el muro conserva 160 píxeles de arena")
	pool.fire(false, Vector2(100, 219), Vector2.RIGHT * 480.0)
	for _frame: int in range(12):
		await tree.physics_frame
	check(is_equal_approx(core.global_position.x, 208.0), "un ladrillo también retrocede desde el tope (núcleo: %s)" % core.global_position)
	boss.queue_free()
	await tree.process_frame


func _test_level_route(tree: SceneTree) -> void:
	var stage_scene: PackedScene = _require_scene("res://scenes/levels/World3Level1.tscn")
	if stage_scene == null:
		return
	GameState.data = SaveManager.defaults()
	GameState.data["unlocked_worlds"].append(2)
	GameState.current_world = 2
	GameState.win()
	check(GameState.is_world_playable(GameState.data, 3), "el nivel y el jefe habilitan Firewall")
	GameState.open_map()
	await tree.scene_changed
	var network_map: Node = tree.current_scene
	var event: InputEventAction = InputEventAction.new()
	event.action = &"ui_right"
	event.pressed = true
	Input.parse_input_event(event)
	await tree.process_frame
	event = InputEventAction.new()
	event.action = &"ui_right"
	Input.parse_input_event(event)
	var enter: Button = network_map.get(&"enter_button") as Button
	check(int(network_map.get(&"selected_world")) == 3 and "Firewall" in enter.text, "derecha selecciona Firewall en el mapa")
	if int(network_map.get(&"selected_world")) != 3:
		return
	enter.pressed.emit()
	await tree.scene_changed
	var stage: Node2D = tree.current_scene as Node2D
	check(stage.scene_file_path == stage_scene.resource_path, "Entrar carga el nivel 3-1")
	if stage.scene_file_path != stage_scene.resource_path:
		return
	_check_lane_heights(stage)
	var player: PacketPlayer = stage.get(&"player") as PacketPlayer
	var level_constants: Dictionary = (stage.get_script() as Script).get_script_constant_map()
	var pit_left: float = level_constants["PIT_LEFT"]
	var pit_right: float = level_constants["PIT_RIGHT"]
	check(pit_right - pit_left == 96.0, "el foso mide 96 px")
	player.position = Vector2(pit_left - 34.0, 296)
	await tree.physics_frame
	await tree.physics_frame
	Input.action_press(&"move_right")
	Input.action_press(&"jump")
	for _frame: int in range(15):
		await tree.physics_frame
	Input.action_press(&"dash")
	await tree.physics_frame
	Input.action_release(&"dash")
	for _frame: int in range(36):
		await tree.physics_frame
	Input.action_release(&"jump")
	Input.action_release(&"move_right")
	check(player.position.x > pit_right and player.is_on_floor(), "Byte cruza el foso con salto y dash (posición %s)" % player.position)
	await _cross_rule_lanes(tree, stage, player)

	player.position = Vector2(2380, 296)
	player.velocity = Vector2.ZERO
	await _walk_to(tree, player, 2440.0)
	check(GameState.checkpoint == Vector2(2400, 296), "caminar a la sala del puzle activa el checkpoint")
	player.position = Vector2((pit_left + pit_right) / 2.0, 380.0)
	for _frame: int in range(12):
		await tree.physics_frame
	check(player.state == PacketPlayer.State.DEAD, "caer al foso es letal")
	GameState.retry()
	await tree.scene_changed
	stage = tree.current_scene as Node2D
	player = stage.get(&"player") as PacketPlayer
	check(player.position == Vector2(2400, 296), "reintentar reaparece en la sala del puzle")

	var puzzle: FirewallPuzzle = stage.get(&"puzzle") as FirewallPuzzle
	for packet: Dictionary in FirewallFilter.generate_sequence(0):
		var passes: bool = FirewallFilter.is_allowed(packet["shape"], packet["color"], FirewallFilter.TRIANGLE, FirewallFilter.RED)
		var node: NetworkNode = puzzle.pass_node if passes else puzzle.block_node
		await _walk_to(tree, player, node.global_position.x)
		Input.action_press(&"interact")
		await tree.physics_frame
		await tree.physics_frame
		Input.action_release(&"interact")
		await tree.physics_frame
	check(puzzle.is_solved and puzzle.door.opened, "los terminales del nivel abren la compuerta")
	if not puzzle.is_solved:
		return
	# Desde el último terminal se recorre a pie toda la distancia hasta la salida.
	Input.action_press(&"move_right")
	for _frame: int in range(260):
		await tree.physics_frame
		if tree.current_scene is FirewallBoss:
			break
	Input.action_release(&"move_right")
	var boss: FirewallBoss = tree.current_scene as FirewallBoss
	check(boss != null and GameState.in_boss and GameState.current_world == 3, "caminar por la salida carga la arena")
	if boss == null:
		return
	_check_lane_heights(boss)
	boss.set_physics_process(false)
	boss._physics_process(1.2)
	boss._physics_process(1.61)
	boss.core.take_damage(36.0, Vector2.ZERO)
	boss._physics_process(2.4)
	boss.core.take_damage(36.0, Vector2.ZERO)
	boss._physics_process(2.4)
	boss.core.take_damage(48.0, Vector2.ZERO)
	check(boss.health.current == 0.0, "derrotar al jefe completa el mundo")
	if boss.health.current > 0.0:
		return
	boss._physics_process(0.8)
	await tree.scene_changed
	var data: Dictionary = SaveManager.load_game()
	check(tree.current_scene.scene_file_path == GameState.MAP, "la victoria devuelve a Byte al mapa")
	check("w3_boss" in data["completed_levels"] and "w3_firewall_boss" in data["collected_cores"]
		and GameState.is_world_unlocked(data, 4) and not GameState.is_world_playable(data, 4),
		"la victoria se guarda y desbloquea Servidor como próximo destino")

func _cross_rule_lanes(tree: SceneTree, stage: Node2D, player: PacketPlayer) -> void:
	var bar: RuleBar
	for child: Node in stage.get_children():
		if child is RuleBar:
			bar = child as RuleBar
		elif child is EnemyBase:
			child.set_physics_process(false)
	if bar == null:
		errors.append("falta la barra de S4")
		return
	for lane: int in range(RuleBar.LANES_Y.size()):
		bar.set(&"_age", lane * RuleBar.LANE_TIME + 0.05)
		player.position = Vector2(bar.position.x - 43.0, 296.0 if lane == 0 else 249.0)
		player.velocity = Vector2.ZERO
		for _frame: int in range(4):
			await tree.physics_frame
		var hp: float = player.health.current
		Input.action_press(&"move_right")
		if lane == 2:
			Input.action_press(&"jump")
		for _frame: int in range(34):
			await tree.physics_frame
		Input.action_release(&"jump")
		Input.action_release(&"move_right")
		check(player.position.x > bar.position.x + 13 and player.health.current == hp,
			"Byte cruza a salvo el carril %d de S4 (posición %s)" % [lane, player.position])

func _walk_to(tree: SceneTree, player: PacketPlayer, x: float) -> void:
	if absf(x - player.position.x) <= 5.0:
		return
	var action: StringName = &"move_right" if x > player.position.x else &"move_left"
	Input.action_press(action)
	for _frame: int in range(150):
		await tree.physics_frame
		if absf(x - player.position.x) <= 5.0:
			break
	Input.action_release(action)
	for _frame: int in range(7):
		await tree.physics_frame

func _check_lane_heights(stage: Node2D) -> void:
	var surfaces: Array[float] = []
	for child: Node in stage.get_children():
		if child is ChipPlatform and (child as ChipPlatform).position.y in [256.0, 304.0]:
			surfaces.append((child as ChipPlatform).position.y)
	check(256.0 in surfaces and 304.0 in surfaces, "suelo y plataformas a 256 en " + stage.name)
	for y: float in RuleBar.LANES_Y:
		var reachable: bool = false
		for surface: float in surfaces:
			var standing: float = surface - 7.0
			# El colisionador 10×14 debe caber entero en el hueco de 64 px.
			var half_clearance: float = RuleBar.GAP_HEIGHT / 2.0 - 7.0
			if standing >= y - half_clearance and standing - (y + half_clearance) <= 60.0:
				reachable = true
		check(reachable, "carril y=%d alcanzable en %s" % [y, stage.name])

func check(condition: bool, message: String) -> void:
	if not condition:
		errors.append(message)
