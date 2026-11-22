extends RefCounted

var errors: PackedStringArray = []
var finished: bool = false

func run(_tree: SceneTree) -> PackedStringArray:
	_test_world_progress()
	await _test_filter(_tree)
	await _test_armor(_tree)
	await _test_hazards(_tree)
	finished = true
	return errors

func _test_world_progress() -> void:
	GameState.current_world = 2
	check(not GameState.is_world_playable(GameState.data, 3), "Firewall comienza bloqueado")
	GameState.win()
	var saved: Dictionary = SaveManager.load_game()
	check(GameState.is_world_unlocked(saved, 3), "la victoria del mundo 2 desbloquea Firewall")
	check(GameState.WORLDS.size() == 3 and GameState.WORLDS.has({
		"level": "res://scenes/levels/World3Level1.tscn", "boss": "res://scenes/bosses/FirewallBoss.tscn"
	}), "Mundo 3 registrado con el nivel y la arena")
	saved["unlocked_worlds"].append(4)
	check(not GameState.is_world_playable(saved, 4), "Servidor desbloqueado sigue sin escenas")


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

func check(condition: bool, message: String) -> void:
	if not condition:
		errors.append(message)
