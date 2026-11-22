extends RefCounted

const LEVEL: String = "res://scenes/levels/World4Level1.tscn"
const BOSS: String = "res://scenes/bosses/TrojanBoss.tscn"

var errors: PackedStringArray = []
var finished: bool = false

func run(tree: SceneTree) -> PackedStringArray:
	_test_world_progress()
	_test_platforms()
	await _test_trojan(tree)
	await _test_password(tree)
	await _test_boss(tree)
	await _test_level_route(tree)
	finished = true
	return errors

func _test_world_progress() -> void:
	GameState.current_world = 3
	check(not GameState.is_world_playable(GameState.data, 4), "Servidor comienza bloqueado")
	GameState.win()
	var saved: Dictionary = SaveManager.load_game()
	check(GameState.is_world_unlocked(saved, 4), "vencer al Firewall desbloquea Servidor")
	check(GameState.WORLDS.size() == 4 and GameState.WORLDS.has({"level": LEVEL, "boss": BOSS}),
		"Servidor registra su nivel y su jefe")
	check(GameState.is_world_playable(saved, 4) == (ResourceLoader.exists(LEVEL) and ResourceLoader.exists(BOSS)),
		"Servidor requiere ambas escenas para poder jugar")
	saved["unlocked_worlds"].append(5)
	check(not GameState.is_world_playable(saved, 5), "Centro de datos sigue pendiente aunque esté desbloqueado")

func _test_platforms() -> void:
	var vent: Script = require_script("res://scripts/objects/air_vent.gd")
	if vent != null:
		var times: Array[float] = [0.0, 1.9, 2.2, 2.6, 3.1]
		var states: Array[StringName] = [&"active", &"active", &"inactive", &"warning", &"active"]
		for index: int in range(times.size()):
			check(vent.call(&"state_at", times[index]) == states[index], "estado del ventilador a %.1f s" % times[index])
		for sample: Vector2 in [Vector2(0, -240), Vector2(-330, -330), Vector2(100, -240)]:
			check(float(vent.call(&"lift_velocity", sample.x, 240.0)) == sample.y, "impulso vertical desde %s" % sample.x)
	var elevator: Script = require_script("res://scripts/objects/data_elevator.gd")
	if elevator != null:
		var bottom: float = elevator.call(&"top_y", 280.0, 64.0, 3.2, 0.0)
		var top: float = elevator.call(&"top_y", 280.0, 64.0, 3.2, 1.6)
		var returned: float = elevator.call(&"top_y", 280.0, 64.0, 3.2, 3.2)
		check(is_equal_approx(bottom, 280.0) and is_equal_approx(top, 216.0)
			and is_equal_approx(returned, 280.0), "el ascensor sube 64 px y regresa al anclaje")
		check(304.0 - bottom == 24.0 and top - 176.0 == 40.0, "ambos saltos del ascensor miden menos de 60 px")

func require_script(path: String) -> Script:
	if not ResourceLoader.exists(path):
		errors.append("falta " + path.get_file())
		return null
	return load(path) as Script

func require_scene(path: String) -> PackedScene:
	if not ResourceLoader.exists(path, "PackedScene"):
		errors.append("falta " + path.get_file())
		return null
	return load(path) as PackedScene

func _test_trojan(tree: SceneTree) -> void:
	var scene: PackedScene = require_scene("res://scenes/enemies/Trojan.tscn")
	var portal_script: Script = require_script("res://scripts/enemies/trojan_portal.gd")
	if scene == null or portal_script == null:
		return
	for sample: Vector2i in [Vector2i(0, 2), Vector2i(3, 1), Vector2i(4, 0), Vector2i(5, 0)]:
		check(int(portal_script.call(&"spawn_count", sample.x)) == sample.y, "límite del portal con %d Pop-ups" % sample.x)
	var stage: Node2D = Node2D.new()
	tree.root.add_child(stage)
	var player: PacketPlayer = StageBuilder.player(stage, Vector2(48, 296), 640)
	player.set_physics_process(false)
	var trojan: EnemyBase = scene.instantiate() as EnemyBase
	trojan.position = Vector2(450, 296)
	stage.add_child(trojan)
	trojan.set_physics_process(false)
	check(trojan.health.current == 8.0 and trojan.is_in_group(&"homing_target"), "Troyano con ocho PV y objetivo para Ping")
	trojan.advance(trojan.timer)
	var portal: Node2D = trojan.get(&"portal") as Node2D
	check(portal != null and _popups(stage).is_empty(), "el aviso muestra el portal sin generar enemigos")
	trojan.advance(0.99)
	check(_popups(stage).is_empty(), "el portal espera un segundo")
	trojan.advance(0.011)
	var popups: Array[PopUp] = _popups(stage)
	check(popups.size() == 2, "la primera apertura genera dos Pop-ups")
	if portal != null and popups.size() == 2:
		for index: int in range(popups.size()):
			var offset: Vector2 = Vector2(-28 if index == 0 else 28, 0)
			check(popups[index].position == portal.position + offset and popups[index].health.current == 3.0,
				"el Pop-up nace a ±28 px y tiene tres PV")
		trojan.set_physics_process(true)
		for _frame: int in range(310):
			await tree.physics_frame
		check(_popups(stage).size() == 4, "el mismo portal genera otra pareja a los cinco segundos")
		for _frame: int in range(310):
			await tree.physics_frame
		check(_popups(stage).size() == 4, "el portal se mantiene en cuatro Pop-ups vivos")
		popups[0].take_damage(3.0, Vector2.ZERO)
		for _frame: int in range(310):
			await tree.physics_frame
		check(_popups(stage).size() == 4, "el siguiente ciclo repone solo la vacante")
		trojan.take_damage(8.0, Vector2.ZERO)
		await tree.process_frame
		check(not is_instance_valid(portal) and _popups(stage).size() == 4,
			"al morir el Troyano se cierra el portal y sobreviven sus Pop-ups")
	stage.queue_free()
	await tree.process_frame

func _popups(stage: Node2D) -> Array[PopUp]:
	var popups: Array[PopUp] = []
	for child: Node in stage.get_children():
		if child is PopUp:
			popups.append(child as PopUp)
	return popups

func _test_password(tree: SceneTree) -> void:
	var logic: Script = require_script("res://scripts/puzzles/password_logic.gd")
	var scene: PackedScene = require_scene("res://scenes/puzzles/PasswordPuzzle.tscn")
	if logic == null or scene == null:
		return
	var canonical: Array[int] = [0, 1, 2, 3]
	check(bool(logic.call(&"is_solution", canonical)), "▲ ● ★ ■ resuelve el panel")
	for code: Array in [[1, 0, 2, 3], [0, 1, 3, 2], [2, 0, 1, 3], [3, 1, 2, 3]]:
		check(not bool(logic.call(&"is_solution", code)), "se rechaza %s" % [code])
	check(int(logic.call(&"cycle", 0)) == 1 and int(logic.call(&"cycle", 3)) == 0, "las ranuras ciclan entre cuatro símbolos")
	check(int(logic.call(&"index_of", canonical, 2)) == 2 and int(logic.call(&"index_of", [0], 2)) == -1,
		"se encuentra la posición o se devuelve −1")
	var clues: Array[StringName] = [&"circle_before_star", &"triangle_before_square", &"circle_not_first", &"star_not_last"]
	var counterexamples: Array[Array] = [[0, 1, 3, 2], [3, 1, 2, 0], [1, 2, 0, 3], [0, 3, 1, 2]]
	for index: int in range(clues.size()):
		check(bool(logic.call(clues[index], canonical)) and not bool(logic.call(clues[index], counterexamples[index])),
			"el predicado de la pista %d distingue su contraejemplo" % (index + 1))
	var permutations: int = 0
	var permutation_solutions: int = 0
	var solutions: int = 0
	for a: int in range(4):
		for b: int in range(4):
			for c: int in range(4):
				for d: int in range(4):
					var code: Array[int] = [a, b, c, d]
					var permutation: bool = bool(logic.call(&"is_permutation", code))
					var solution: bool = bool(logic.call(&"is_solution", code))
					permutations += int(permutation)
					permutation_solutions += int(permutation and solution)
					solutions += int(solution)
	check(permutations == 24 and permutation_solutions == 1 and solutions == 1, "una solución entre 24 permutaciones y 256 códigos")

	GameState.current_world = 4
	var puzzle: Node2D = scene.instantiate() as Node2D
	tree.root.add_child(puzzle)
	var slots: Array = puzzle.get(&"slots")
	var door: PacketDoor = puzzle.get(&"door") as PacketDoor
	var reset: NetworkNode = puzzle.get(&"reset_node") as NetworkNode
	var notifications: Array[bool] = []
	puzzle.connect(&"solved", func() -> void: notifications.append(true))
	check(slots.size() == 4 and not door.opened, "el puzle empieza con cuatro ranuras y puerta cerrada")
	for slot: NetworkNode in slots:
		for _turn: int in range(3):
			slot.interact()
	check(door.opened and GameState.puzzle_complete and notifications.size() == 1
		and AudioManager.last_sfx == &"cable_connected", "las ranuras resuelven el puzle, abren la puerta y emiten conexión")
	puzzle.queue_free()
	await tree.process_frame
	puzzle = scene.instantiate() as Node2D
	tree.root.add_child(puzzle)
	door = puzzle.get(&"door") as PacketDoor
	reset = puzzle.get(&"reset_node") as NetworkNode
	check(door.opened, "reintentar conserva la puerta abierta")
	reset.interact()
	check(not door.opened and not GameState.puzzle_complete, "reiniciar restaura el panel y cierra la puerta")
	puzzle.queue_free()
	await tree.process_frame

func _test_boss(tree: SceneTree) -> void:
	var scene: PackedScene = require_scene(BOSS)
	if scene == null:
		return
	var boss: Node2D = scene.instantiate() as Node2D
	var script: Script = boss.get_script() as Script
	for ratio: float in [1.0, 0.70, 0.69, 0.40, 0.39]:
		var phase: int = 1 if ratio > 0.7 else (2 if ratio > 0.4 else 3)
		check(int(script.call(&"phase_for", ratio)) == phase, "fase de Troyano Real con %.2f PV" % ratio)
	for sample: Vector3 in [Vector3(1, 0, 1.5), Vector3(2, 1, 2.0), Vector3(2, 4, 3.0), Vector3(3, 2, 2.5)]:
		check(float(script.call(&"open_window", int(sample.x), int(sample.y))) == sample.z, "apertura para %s" % sample)
	for index: int in range(-1, 21):
		var chest_index: int = posmod(index, 3)
		check(int(script.call(&"true_chest", index)) == chest_index, "cofre real en el ciclo %d" % index)
		check(script.call(&"chest_spot", index) == Vector2(160 + chest_index * 160, 296), "posición del cofre %d" % index)
	for index: int in range(13):
		var lanes: Array = script.call(&"descarga_lanes", index)
		check(lanes == ([0, 2] if (index >> 1) & 1 == 0 else [1, 2]), "carriles esquivables del ciclo %d" % index)
	var heights: Array = script.get_script_constant_map()["DESCARGA_LANES"]
	check(heights == [296.0, 256.0, 216.0] and heights[0] - 3.0 >= 290.0
		and heights[1] + 3.0 < 290.0 and heights[2] + 3.0 < 304.0 - 60.5 - 14.0,
		"los carriles se esquivan de pie o con el salto base")

	tree.root.add_child(boss)
	boss.set_physics_process(false)
	var body: Hurtbox = boss.get(&"body") as Hurtbox
	var player: PacketPlayer = boss.get(&"player") as PacketPlayer
	var pool: ProjectilePool = boss.get(&"pool") as ProjectilePool
	var health: HealthComponent = boss.get(&"health") as HealthComponent
	var card: Label = boss.get(&"card") as Label
	player.set_physics_process(false)
	check(health.current == 150.0 and body.invulnerable and body.homing_target and body.collision_layer == 4,
		"el cofre nace cerrado con 150 PV y puede atraer al Ping")
	body.take_damage(1.0, Vector2.ZERO)
	boss.call(&"_physics_process", 1.2)
	boss.call(&"_physics_process", 0.59)
	check(body.invulnerable and health.current == 150.0, "el aviso de salto no abre el cofre")
	boss.call(&"_physics_process", 0.011)
	boss.call(&"_physics_process", 0.3)
	check(body.position.y < 296.0 and body.invulnerable, "el arco eleva el cofre cerrado")
	boss.call(&"_physics_process", 0.3)
	check(body.position == Vector2(160, 296) and not body.invulnerable, "el cofre se abre al aterrizar")
	boss.call(&"_physics_process", 0.59)
	check(not pool.enemy_bullets[0].active, "el carril avisa antes de emitir")
	boss.call(&"_physics_process", 0.011)
	var shot: Projectile = pool.enemy_bullets[0]
	check(shot.active and shot.velocity == Vector2(-160, 0) and shot.damage == 1.0
		and shot.position.y == 296.0 and pool.enemy_bullets[1].position.y == 216.0,
		"la descarga emite dos proyectiles a 160 px/s en los carriles anunciados")
	for _cycle: int in range(2):
		boss.call(&"_physics_process", 1.5)
		boss.call(&"_physics_process", 0.8)
		boss.call(&"_physics_process", 0.6)
		boss.call(&"_physics_process", 0.6)
		pool.clear_enemy()
	boss.call(&"_physics_process", 0.6)
	for _frame: int in range(3):
		await tree.physics_frame
	check(shot.active and shot.position.y == 256.0 and shot.position.x < 480.0,
		"el disparo medio atraviesa el chip situado a la misma altura")
	body.take_damage(45.0, Vector2.ZERO)
	check(int(boss.get(&"phase")) == 2 and card.visible and body.invulnerable and not shot.active,
		"el 70 % limpia el pool y muestra la tarjeta de F2")
	boss.call(&"_physics_process", 2.39)
	body.take_damage(45.0, Vector2.ZERO)
	check(health.current == 105.0 and card.visible, "la pausa conserva la invulnerabilidad por 2,4 s")
	boss.call(&"_physics_process", 0.01)
	boss.call(&"_physics_process", 0.6)
	boss.call(&"_physics_process", 0.6)
	var minions: Array[PopUp] = _popups(boss)
	check(not card.visible and not body.invulnerable and minions.size() == 2, "F2 abre el cofre e invoca dos Pop-ups")
	if minions.size() == 2:
		check(minions[0].health.current == 3.0 and minions[1].health.current == 3.0, "los minions tienen tres PV")
		minions[0].take_damage(3.0, Vector2.ZERO)
	boss.call(&"_physics_process", 1.51)
	check(not body.invulnerable, "matar un minion extiende la apertura por medio segundo")
	body.take_damage(45.0, Vector2.ZERO)
	check(int(boss.get(&"phase")) == 3 and body.invulnerable and card.visible
		and not pool.enemy_bullets[0].active, "el 40 % inicia la pausa de F3 y cancela la descarga")
	boss.call(&"_physics_process", 2.4)
	boss.call(&"_physics_process", 0.6)
	boss.call(&"_physics_process", 0.6)
	player.position = Vector2(480, 296)
	boss.call(&"_physics_process", 0.01)
	check(body.position == Vector2(160, 296) and not body.invulnerable and player.health.current == 2.0,
		"en F3 solo el cofre real se abre y el contacto con un mímico quita un PV")
	boss.queue_free()
	await tree.process_frame
	Engine.time_scale = 1.0

func _test_level_route(tree: SceneTree) -> void:
	if require_scene(LEVEL) == null:
		return
	GameState.data = SaveManager.defaults()
	GameState.data["unlocked_worlds"].assign([1, 2, 3])
	GameState.current_world = 3
	GameState.win()
	check(GameState.is_world_playable(GameState.data, 4), "Servidor se habilita al vencer al Firewall")
	GameState.open_map()
	await tree.scene_changed
	var network_map: Node = tree.current_scene
	await _map_right(tree)
	var enter: Button = network_map.get(&"enter_button") as Button
	check(int(network_map.get(&"selected_world")) == 4 and "Servidor" in enter.text, "el mapa permite seleccionar Servidor")
	if int(network_map.get(&"selected_world")) != 4:
		return
	enter.pressed.emit()
	await tree.scene_changed
	var stage: Node2D = tree.current_scene as Node2D
	check(stage.scene_file_path == LEVEL, "Entrar abre 4-1")
	if stage.scene_file_path != LEVEL:
		return
	var player: PacketPlayer = stage.get(&"player") as PacketPlayer
	player.invulnerability = 60.0
	await _walk_to(tree, player, 176.0)
	for _frame: int in range(180):
		await tree.physics_frame
		if player.is_on_floor() and player.position.y < 208.0 and "w4_core_a" in GameState.data["collected_cores"]:
			break
	check(player.position.y < 208.0 and "w4_core_a" in GameState.data["collected_cores"],
		"caminar a la corriente alcanza el núcleo y la repisa de S1 (Byte %s)" % player.position)

	if not await _reach_rack(tree, player, stage.get_node("ElevatorS2") as DataElevator, 858.0):
		return
	await _walk_to(tree, player, 1534.0)
	check(player.position.y > 289.0 and player.is_on_floor(), "bajar del rack deja a Byte en el suelo de S3")
	Input.action_press(&"move_right")
	Input.action_press(&"jump")
	await _frames(tree, 15)
	Input.action_press(&"dash")
	await _frames(tree, 1)
	Input.action_release(&"dash")
	await _frames(tree, 36)
	Input.action_release(&"jump")
	Input.action_release(&"move_right")
	check(player.position.x > 1664.0 and player.is_on_floor(), "Byte cruza 96 px con salto y dash (Byte %s)" % player.position)
	if player.position.x <= 1664.0:
		return
	await _walk_to(tree, player, 1944.0)
	check(GameState.checkpoint == Vector2(1920, 296) and player.fatal_pits, "S4 activa el punto de restauración")
	await _walk_to(tree, player, 1616.0)
	await _frames(tree, 40)
	check(player.state == PacketPlayer.State.DEAD, "caminar al foso sin saltar es letal")
	GameState.retry()
	await tree.scene_changed
	stage = tree.current_scene as Node2D
	player = stage.get(&"player") as PacketPlayer
	check(player.position == Vector2(1920, 296), "reintentar reaparece en el checkpoint de S4")
	player.invulnerability = 60.0
	if not await _reach_rack(tree, player, stage.get_node("ElevatorS4") as DataElevator, 2280.0):
		return
	check("w4_core_b" in GameState.data["collected_cores"], "el ascensor de S4 permite recoger el núcleo oculto")
	await _walk_to(tree, player, 2590.0)
	check(GameState.checkpoint == Vector2(2560, 296), "caminar al puzle activa el segundo checkpoint")
	var puzzle: PasswordPuzzle = stage.get(&"puzzle") as PasswordPuzzle
	for slot: PasswordSlot in puzzle.slots:
		await _walk_to(tree, player, slot.global_position.x)
		for _turn: int in range(3):
			Input.action_press(&"interact")
			await _frames(tree, 2)
			Input.action_release(&"interact")
			await _frames(tree, 2)
	check(puzzle.is_solved and puzzle.door.opened and puzzle.door.position.x + puzzle.position.x == 3200.0,
		"interactuar con las cuatro ranuras abre la compuerta en x = 3200")
	if not puzzle.is_solved:
		return
	Input.action_press(&"move_right")
	for _frame: int in range(150):
		await tree.physics_frame
		if tree.current_scene is TrojanBoss:
			break
	Input.action_release(&"move_right")
	var boss: TrojanBoss = tree.current_scene as TrojanBoss
	check(boss != null and GameState.in_boss, "caminar desde la última ranura lleva a Troyano Real")
	if boss == null:
		return
	boss.set_physics_process(false)
	boss._physics_process(1.2)
	for damage: float in [45.0, 45.0, 60.0]:
		boss._physics_process(0.6)
		boss._physics_process(0.6)
		boss.body.take_damage(damage, Vector2.ZERO)
		if boss.health.current > 0.0:
			boss._physics_process(2.4)
	check(boss.health.current == 0.0, "vencer al último cofre completa Servidor")
	if boss.health.current > 0.0:
		return
	boss._physics_process(0.8)
	await tree.scene_changed
	var saved: Dictionary = SaveManager.load_game()
	check(tree.current_scene.scene_file_path == GameState.MAP and "w4_boss" in saved["completed_levels"]
		and "w4_trojan_boss" in saved["collected_cores"] and GameState.is_world_unlocked(saved, 5)
		and not GameState.is_world_playable(saved, 5), "el mapa guarda la victoria y Centro de datos queda PRÓXIMAMENTE")
	await _map_right(tree)
	check(int(tree.current_scene.get(&"selected_world")) == 1, "derecha desde Servidor pasa al primer mundo disponible")

func _reach_rack(tree: SceneTree, player: PacketPlayer, elevator: DataElevator, target: float) -> bool:
	await _walk_to(tree, player, elevator.position.x + elevator.size.x * 0.5)
	var riding: bool = false
	for _frame: int in range(240):
		await tree.physics_frame
		if not player.is_on_floor():
			continue
		if player.position.y <= 215.0 and elevator.position.y <= 221.0:
			riding = true
			break
		if player.position.y > 290.0 and elevator.position.y >= 263.0:
			Input.action_press(&"jump")
			await _frames(tree, 34)
			Input.action_release(&"jump")
	check(riding, "Byte monta el ascensor de %d y sube con la cabina (Byte %s)" % [elevator.position.x, player.position])
	if not riding:
		return false
	Input.action_press(&"jump")
	await _walk_to(tree, player, target)
	Input.action_release(&"jump")
	await _frames(tree, 24)
	var reached: bool = player.is_on_floor() and absf(player.position.y + 7.0 - 176.0) < 1.0
	check(reached, "Byte salta de la cabina al rack de y = 176 (Byte %s)" % player.position)
	return reached

func _walk_to(tree: SceneTree, player: PacketPlayer, x: float) -> void:
	var right: bool = player.position.x < x
	var action: StringName = &"move_right" if right else &"move_left"
	Input.action_press(action)
	for _frame: int in range(360):
		await tree.physics_frame
		if (player.position.x >= x if right else player.position.x <= x) or player.state == PacketPlayer.State.DEAD:
			break
	Input.action_release(action)

func _map_right(tree: SceneTree) -> void:
	var event: InputEventAction = InputEventAction.new()
	event.action = &"ui_right"
	event.pressed = true
	Input.parse_input_event(event)
	await tree.process_frame
	event = InputEventAction.new()
	event.action = &"ui_right"
	Input.parse_input_event(event)

func _frames(tree: SceneTree, count: int) -> void:
	for _frame: int in range(count):
		await tree.physics_frame

func check(condition: bool, message: String) -> void:
	if not condition:
		errors.append(message)
