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

func check(condition: bool, message: String) -> void:
	if not condition:
		errors.append(message)
