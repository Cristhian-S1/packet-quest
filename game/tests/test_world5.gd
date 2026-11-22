extends RefCounted

const LEVEL: String = "res://scenes/levels/World5Level1.tscn"
const BOSS: String = "res://scenes/bosses/MalwarexBoss.tscn"

var errors: PackedStringArray = []
var finished: bool = false

func run(tree: SceneTree) -> PackedStringArray:
	_test_progress()
	await _test_cloud(tree)
	await _test_bot(tree)
	await _test_qos(tree)
	await _test_malwarex(tree)
	await _test_level(tree)
	finished = true
	return errors

func _test_progress() -> void:
	check(GameState.WORLDS.size() == SaveManager.WORLD_COUNT
		and GameState.WORLDS.back() == {"level": LEVEL, "boss": BOSS}, "el mapa registra exactamente cinco mundos")
	var map_script: Script = load("res://scripts/main/network_map.gd") as Script
	check(is_equal_approx(float(map_script.call(&"node_x", 4)), 518.0), "el mapa distribuye los cinco nodos")
	GameState.current_world = 4
	GameState.win()
	var saved: Dictionary = SaveManager.load_game()
	check(GameState.is_world_unlocked(saved, 5), "vencer al Troyano Real desbloquea Centro de datos")
	check(GameState.is_world_playable(saved, 5) == (ResourceLoader.exists(LEVEL) and ResourceLoader.exists(BOSS)),
		"Centro de datos se puede jugar al contar con nivel y jefe")
	saved["unlocked_worlds"].append(6)
	check(not GameState.is_world_playable(saved, 6), "el mundo 6 nunca es jugable")
	SaveManager.save_game(saved)
	check(not GameState.is_world_unlocked(SaveManager.load_game(), 6), "una partida antigua descarta el mundo 6")
	GameState.current_world = 5
	GameState.win()
	GameState.win()
	check(bool(GameState.data.get("finished", false)) and not GameState.is_world_unlocked(GameState.data, 6)
		and GameState.data["completed_levels"].count("w5_boss") == 1
		and bool(SaveManager.load_game().get("finished", false)), "Malwarex registra la victoria final una vez")

func _test_cloud(tree: SceneTree) -> void:
	var script: Script = require_script("res://scripts/objects/cloud_platform.gd")
	if script == null:
		return
	var times: Array[float] = [0.0, 1.9, 2.2, 2.6, 3.9, 4.1]
	var expected: Array[StringName] = [&"solid", &"solid", &"fading", &"gone", &"gone", &"solid"]
	for index: int in range(times.size()):
		check(script.call(&"state_at", times[index]) == expected[index], "estado de nube a %.1f s" % times[index])
	var cloud: StaticBody2D = script.new() as StaticBody2D
	tree.root.add_child(cloud)
	cloud.set_physics_process(false)
	var shape: CollisionShape2D = cloud.get_child(0) as CollisionShape2D
	check(cloud.collision_layer == 1 and not shape.disabled, "nube sólida en la capa del mundo")
	cloud.call(&"_physics_process", 2.2)
	await tree.process_frame
	check(not shape.disabled, "la nube conserva la colisión durante el aviso")
	cloud.call(&"_physics_process", 0.4)
	await tree.process_frame
	check(shape.disabled, "la nube pierde la colisión al desaparecer")
	cloud.call(&"_physics_process", 1.5)
	await tree.process_frame
	check(not shape.disabled, "la nube recupera la colisión al reiniciar su ciclo")
	cloud.queue_free()
	await tree.process_frame

func _test_bot(tree: SceneTree) -> void:
	var script: Script = require_script("res://scripts/enemies/bot_ddos.gd")
	var scene: PackedScene = require_scene("res://scenes/enemies/BotDDoS.tscn")
	if script == null or scene == null:
		return
	var directions: Array[Vector2] = script.call(&"fan_directions", Vector2(0, 3), 6, 120.0)
	check(directions.size() == 6, "el abanico tiene seis direcciones")
	if directions.size() == 6:
		check(is_equal_approx(rad_to_deg(directions[0].angle_to(directions[5])), 120.0),
			"los extremos del abanico abarcan 120 grados")
		for index: int in range(directions.size()):
			var angle: float = rad_to_deg(Vector2.DOWN.angle_to(directions[index]))
			check(directions[index].is_normalized() and is_equal_approx(angle, -60.0 + index * 24.0),
				"dirección normalizada y centrada %d" % index)
	var stage: Node2D = Node2D.new()
	tree.root.add_child(stage)
	var pool: ProjectilePool = ProjectilePool.new()
	stage.add_child(pool)
	var player: PacketPlayer = StageBuilder.player(stage, Vector2(64, 296), 640)
	player.set_physics_process(false)
	var bot: EnemyBase = scene.instantiate() as EnemyBase
	bot.position = Vector2(320, 224)
	stage.add_child(bot)
	bot.set_physics_process(false)
	check(bot.health.current == 2.0 and bot.is_in_group(&"homing_target"), "Bot DDoS aparece con dos PV")
	bot.advance(bot.timer)
	bot.advance(0.59)
	check(bot.state == EnemyBase.State.TELEGRAPH and not pool.enemy_bullets[0].active, "aviso de 0,6 s antes del abanico")
	bot.on_screen = true
	bot.advance(0.011)
	for index: int in range(6):
		var shot: Projectile = pool.enemy_bullets[index]
		check(shot.active and is_equal_approx(shot.velocity.length(), 90.0)
			and shot.damage == 1.0 and shot.get(&"enemy_color") == PQStyle.AMBER, "bala ámbar %d" % index)
	pool.clear_enemy()
	bot.on_screen = false
	bot.fire()
	check(not pool.enemy_bullets[0].active, "el Bot DDoS no dispara fuera de pantalla")
	stage.queue_free()
	await tree.process_frame

func _test_qos(tree: SceneTree) -> void:
	var logic: Script = require_script("res://scripts/puzzles/qos_puzzle.gd")
	var scene: PackedScene = require_scene("res://scenes/puzzles/QoSPuzzle.tscn")
	if logic == null or scene == null:
		return
	var correct: Array[StringName] = [&"voz", &"video", &"correo", &"descarga"]
	var wrong: Array[StringName] = [&"video", &"voz", &"correo", &"descarga"]
	var empty: Array[StringName] = []
	var partial: Array[StringName] = [&"voz", &"video"]
	check(not bool(logic.call(&"is_correct_order", empty))
		and bool(logic.call(&"is_correct_order", correct))
		and not bool(logic.call(&"is_correct_order", wrong)), "QoS exige las cuatro prioridades en orden")
	for index: int in range(correct.size()):
		check(int(logic.call(&"urgency", correct[index])) == 4 - index, "urgencia de %s" % correct[index])
	check(logic.call(&"next_expected", partial) == &"correo", "la pista espera el correo después del vídeo")

	GameState.puzzle_complete = false
	GameState.current_world = 5
	var stage: Node2D = Node2D.new()
	tree.root.add_child(stage)
	var player: PacketPlayer = StageBuilder.player(stage, Vector2(64, 296), 640)
	player.set_physics_process(false)
	var puzzle: Node2D = scene.instantiate() as Node2D
	stage.add_child(puzzle)
	var nodes: Dictionary[StringName, Area2D] = {}
	for node: Area2D in puzzle.get(&"nodes"):
		nodes[StringName(node.get(&"traffic_id"))] = node
	check(nodes.size() == 4, "la sala tiene cuatro interruptores QoS")
	if nodes.size() == 4:
		var door: PacketDoor = puzzle.get(&"door") as PacketDoor
		var reset: NetworkNode = puzzle.get(&"reset_node") as NetworkNode
		var solved: Array[bool] = []
		puzzle.connect(&"solved", func() -> void: solved.append(true))
		for id: StringName in wrong:
			nodes[id].call(&"interact")
		check(Array(puzzle.get(&"activated")).is_empty() and not door.opened and solved.is_empty(),
			"la secuencia incorrecta derriba los puentes y permite reintentar")
		nodes[&"voz"].call(&"interact")
		nodes[&"voz"].call(&"interact")
		check(Array(puzzle.get(&"activated")).size() == 1, "cada interruptor cuenta una vez")
		reset.interact()
		check(Array(puzzle.get(&"activated")).is_empty(), "el nodo de reinicio vacía la secuencia")
		puzzle.call(&"_process", 60.0)
		check(puzzle.get(&"_hint_bridge") == &"voz", "a los 60 s la pista ilumina el puente de voz")
		puzzle.call(&"_process", 1.1)
		check(puzzle.get(&"_hint_bridge") == &"", "la pista deja de iluminar el puente tras un segundo")
		for id: StringName in correct:
			nodes[id].call(&"interact")
		check(door.opened and GameState.puzzle_complete and solved.size() == 1
			and AudioManager.last_sfx == &"cable_connected", "QoS abre la puerta y emite la conexión")
	stage.queue_free()
	await tree.process_frame

func _test_malwarex(tree: SceneTree) -> void:
	var scene: PackedScene = require_scene(BOSS)
	if scene == null:
		return
	var boss: Node2D = scene.instantiate() as Node2D
	var script: Script = boss.get_script() as Script
	var ratios: Array[float] = [1.0, 0.76, 0.75, 0.51, 0.5, 0.26, 0.25, 0.0]
	var phases: Array[int] = [1, 1, 2, 2, 3, 3, 4, 4]
	for index: int in range(ratios.size()):
		check(int(script.call(&"phase_for", ratios[index])) == phases[index], "fase de Malwarex al %.0f %%" % (ratios[index] * 100.0))
	var times: Array[float] = [0.0, 1.5, 3.0, 16.0]
	var columns: Array[Array] = [[], [9], [9, 8], [9, 8, 7, 6, 5, 4]]
	for index: int in range(times.size()):
		check(script.call(&"erased_columns", times[index]) == columns[index], "borrado de suelo a %.1f s" % times[index])
	for index: int in range(21):
		var x: float = script.call(&"cable_gap_x", index)
		check(x >= 32.0 and x <= 544.0, "hueco de cable %d queda dentro de la arena" % index)
		var lanes: Array[int] = script.call(&"wave_lanes", index)
		check(lanes == [0, 2] or lanes == [1, 2], "la oleada %d deja un carril esquivable" % index)
	var expected_positions: Array[Vector2] = [Vector2(120, 288), Vector2(320, 240), Vector2(520, 288)]
	check(script.call(&"node_positions") == expected_positions, "posiciones de los tres nodos de combate")

	GameState.data = SaveManager.defaults()
	tree.root.add_child(boss)
	boss.set_physics_process(false)
	var player: PacketPlayer = boss.get(&"player") as PacketPlayer
	player.set_physics_process(false)
	var body: Hurtbox = boss.get(&"body") as Hurtbox
	var health: HealthComponent = boss.get(&"health") as HealthComponent
	var pool: ProjectilePool = boss.get(&"pool") as ProjectilePool
	var card: Label = boss.get(&"card") as Label
	check(health.current == 200.0 and body.homing_target and body.collision_layer == 4,
		"Malwarex tiene 200 PV y una hurtbox para Ping")
	boss.call(&"_physics_process", 1.2)
	boss.call(&"_physics_process", 0.59)
	check(not pool.enemy_bullets[0].active, "el anillo conserva el aviso")
	boss.call(&"_physics_process", 0.011)
	var first_shot: Projectile = pool.enemy_bullets[0]
	check(first_shot.active and first_shot.position == Vector2(320, 112)
		and is_equal_approx(first_shot.velocity.length(), 150.0), "el anillo de señal sale del emisor")
	for phase: int in range(2, 5):
		var shot: Projectile = pool.fire(true, Vector2(320, 100), Vector2.DOWN)
		body.take_damage(50.0, Vector2.ZERO)
		check(int(boss.get(&"phase")) == phase and card.visible and body.invulnerable
			and is_equal_approx(float(boss.get(&"timer")), 2.4) and not shot.active and not first_shot.active,
			"F%d inicia 2,4 s invulnerables y limpia las balas" % phase)
		boss.call(&"_physics_process", 2.39)
		body.take_damage(10.0, Vector2.ZERO)
		check(health.current == 200.0 - (phase - 1) * 50.0 and card.visible, "F%d mantiene la pausa" % phase)
		boss.call(&"_physics_process", 0.01)
		if phase == 3:
			var nodes: Array = boss.get(&"network_nodes")
			check(body.invulnerable and not card.visible and nodes.size() == 3, "F3 blinda el núcleo y muestra los nodos")
			for index: int in range(nodes.size()):
				var node: NetworkNode = nodes[index] as NetworkNode
				if index < expected_positions.size():
					check(node.position == expected_positions[index], "el nodo %d aparece en su posición" % index)
				node.interact()
				node.interact()
				check(body.invulnerable == (index < 2), "el nodo %d solo quita un escudo" % index)
		else:
			check(not body.invulnerable and not card.visible, "F%d vuelve a exponer el núcleo" % phase)
	var floor_shapes: Array = boss.get(&"_floor_shapes")
	boss.call(&"_physics_process", 1.5)
	await tree.process_frame
	check(floor_shapes.size() == 10 and floor_shapes[9].disabled and not floor_shapes[8].disabled,
		"F4 quita físicamente la columna derecha después del aviso")
	body.take_damage(50.0, Vector2.ZERO)
	check(bool(GameState.data.get("finished", false)) and "w5_boss" in GameState.data["completed_levels"]
		and not GameState.is_world_unlocked(GameState.data, 6) and GameState.data["collected_cores"].is_empty(),
		"la derrota completa la partida sin núcleo ni sexto mundo")
	await _test_credits(tree, boss)
	boss.queue_free()
	await tree.process_frame

func _test_credits(tree: SceneTree, boss: Node2D) -> void:
	var scene: PackedScene = require_scene(GameState.CREDITS)
	if scene == null:
		return
	GameState.data["data_cores"] = 7
	GameState.data["stats"] = {"deaths": {"nivel_5_1": 2, "malwarex": 3}, "play_time_s": 65.9}
	GameState.data["settings"]["reduce_flashes"] = true
	boss.call(&"_physics_process", 0.8)
	await tree.scene_changed
	var credits: PacketScreen = tree.current_scene as PacketScreen
	check(credits != null and credits.scene_file_path == GameState.CREDITS and not GameState.playing,
		"la derrota lleva a los créditos sin pasar por el mapa")
	if credits == null or credits.scene_file_path != GameState.CREDITS:
		return
	var script: Script = credits.get_script() as Script
	check(script.call(&"format_time", 65.0) == "01:05"
		and script.call(&"format_time", 3600.0) == "60:00", "formato de minutos y segundos")
	var texts: Array[String] = []
	var buttons: Dictionary[String, Button] = {}
	for child: Node in credits.panel.get_children():
		if child is Label:
			texts.append((child as Label).text)
		elif child is Button:
			buttons[(child as Button).text] = child as Button
	for title: String in ["INTERNET RESTAURADA", "Núcleos de datos: 7/10", "Muertes: 5", "Tiempo: 01:05"]:
		check(title in texts, "los créditos muestran " + title)
	check(buttons.has("Menú principal") and buttons.has("Nueva partida"), "los créditos ofrecen menú y nueva partida")
	if buttons.has("Nueva partida"):
		buttons["Nueva partida"].pressed.emit()
		await tree.scene_changed
		var fresh: Dictionary = SaveManager.load_game()
		check(GameState.current_world == 1 and tree.current_scene is World1Level1
			and not bool(fresh["finished"]) and int(fresh["data_cores"]) == 0 and fresh["stats"]["deaths"].is_empty()
			and bool(fresh["settings"]["reduce_flashes"]), "nueva partida vuelve a Red Local con ajustes y progreso nuevo")

func _test_level(tree: SceneTree) -> void:
	if require_scene(LEVEL) == null:
		return
	GameState.data = SaveManager.defaults()
	GameState.data["unlocked_worlds"].assign([1, 2, 3, 4])
	GameState.current_world = 4
	GameState.win()
	if not GameState.is_world_playable(GameState.data, 5):
		check(false, "Centro de datos recibe su nivel y su jefe")
		return
	GameState.open_map()
	await tree.scene_changed
	var map: Node = tree.current_scene
	var event: InputEventAction = InputEventAction.new()
	event.action = &"ui_right"
	event.pressed = true
	Input.parse_input_event(event)
	await tree.process_frame
	event = InputEventAction.new()
	event.action = &"ui_right"
	Input.parse_input_event(event)
	var enter: Button = map.get(&"enter_button") as Button
	check("Centro de datos" in enter.text, "desde Servidor, el mapa permite elegir Centro de datos")
	if not "Centro de datos" in enter.text:
		return
	enter.pressed.emit()
	await tree.scene_changed
	var level: Node2D = tree.current_scene as Node2D
	check(level != null and level.scene_file_path == LEVEL, "Entrar abre 5-1")
	if level == null or level.scene_file_path != LEVEL:
		return
	var player: PacketPlayer = level.get(&"player") as PacketPlayer
	player.invulnerability = 90.0
	var landing: ChipPlatform = level.get_node("VentLanding") as ChipPlatform
	var height: float = 304.0 - landing.position.y
	check(height > 60.0 and height <= 152.0, "S1 exige el ventilador para alcanzar su repisa")
	await _walk_to(tree, player, 168.0)
	for _frame: int in range(180):
		await tree.physics_frame
		if player.is_on_floor() and absf(player.position.y + 7.0 - landing.position.y) < 1.0:
			break
	check(player.is_on_floor() and absf(player.position.y + 7.0 - landing.position.y) < 1.0,
		"Byte alcanza la repisa con la corriente (Byte %s)" % player.position)

	await _walk_to(tree, player, 779.0)
	await _jump_to(tree, player, 827.0)
	await _walk_to(tree, player, 1065.0)
	check(player.position.x >= 1065.0 and player.state != PacketPlayer.State.DEAD,
		"Byte cruza el foso de cobertura por sus cuatro apoyos (Byte %s)" % player.position)
	if player.state == PacketPlayer.State.DEAD:
		return
	await _walk_to(tree, player, 1587.0)
	Input.action_press(&"move_right")
	Input.action_press(&"jump")
	await _frames(tree, 16)
	Input.action_press(&"dash")
	await _frames(tree, 1)
	Input.action_release(&"dash")
	await _frames(tree, 40)
	Input.action_release(&"jump")
	Input.action_release(&"move_right")
	check(player.position.x > 1696.0 and "w5_core_a" in GameState.data["collected_cores"],
		"salto y dash cruzan 96 px y alcanzan el núcleo de S3 (Byte %s)" % player.position)
	if player.state == PacketPlayer.State.DEAD:
		return
	await _walk_to(tree, player, 2629.0)
	check(GameState.checkpoint == Vector2(2560, 296), "Byte activa el checkpoint de S5")
	var clouds: Array = level.get(&"clouds")
	check(clouds.size() == 3, "el foso de S5 tiene tres nubes")
	if clouds.size() != 3:
		return
	var start_cloud: StaticBody2D = clouds[0] as StaticBody2D
	for _frame: int in range(240):
		if fposmod(float(start_cloud.get(&"_age")), 4.0) < 0.12:
			break
		await tree.physics_frame
	for cloud: StaticBody2D in clouds:
		await _jump_to(tree, player, cloud.global_position.x)
		check(player.is_on_floor() and absf(player.position.x - cloud.global_position.x) < 20.0,
			"Byte aterriza en la nube de x = %.0f (Byte %s)" % [cloud.global_position.x, player.position])
		if player.state == PacketPlayer.State.DEAD:
			return
	await _jump_to(tree, player, 2938.0)
	check(player.position.x >= 2920.0 and "w5_core_b" in GameState.data["collected_cores"],
		"el último apoyo revela el núcleo oculto y deja llegar al otro lado (Byte %s)" % player.position)
	if player.state == PacketPlayer.State.DEAD:
		return
	await _walk_to(tree, player, 3070.0)
	check(GameState.checkpoint == Vector2(3040, 296), "Byte activa el checkpoint de entrada a QoS")
	var puzzle: QosRoom = level.get(&"puzzle") as QosRoom
	for id: StringName in QosPuzzle.PRIORITY:
		for node: QosNode in puzzle.nodes:
			if StringName(node.traffic_id) == id:
				await _walk_to(tree, player, node.global_position.x)
				Input.action_press(&"interact")
				await _frames(tree, 2)
				Input.action_release(&"interact")
				await _frames(tree, 2)
				break
	check(puzzle.is_solved and puzzle.door.opened and puzzle.door.global_position.x == 3600.0,
		"interactuar abre la compuerta del centro de datos")
	Input.action_press(&"move_right")
	for _frame: int in range(210):
		await tree.physics_frame
		if tree.current_scene is MalwarexBoss:
			break
	Input.action_release(&"move_right")
	check(tree.current_scene is MalwarexBoss and GameState.in_boss,
		"caminar desde el último interruptor cruza la salida y entra a Malwarex")
	var boss: MalwarexBoss = tree.current_scene as MalwarexBoss
	if boss != null:
		await _test_combat_route(tree, boss)

func _test_combat_route(tree: SceneTree, boss: MalwarexBoss) -> void:
	boss.set_physics_process(false)
	boss._physics_process(1.2)
	for _phase: int in range(2):
		boss.body.take_damage(50.0, Vector2.ZERO)
		boss._physics_process(2.4)
	var player: PacketPlayer = boss.player
	player.invulnerability = 16.0
	for node: NetworkNode in boss.network_nodes:
		await _walk_to(tree, player, node.position.x)
		if node.position.y == 240.0:
			await _jump_to(tree, player, node.position.x)
			check(player.is_on_floor() and absf(player.position.y + 7.0 - 256.0) < 1.0,
				"Byte alcanza la plataforma del nodo elevado (Byte %s)" % player.position)
		Input.action_press(&"interact")
		await _frames(tree, 2)
		Input.action_release(&"interact")
		await _frames(tree, 2)
		check(node.accent == PQStyle.CYAN, "Byte conecta con E el nodo de x = %.0f" % node.position.x)
	check(not boss.body.invulnerable, "caminar y saltar permiten retirar los tres escudos")

func _walk_to(tree: SceneTree, player: PacketPlayer, x: float) -> void:
	var right: bool = player.position.x < x
	var action: StringName = &"move_right" if right else &"move_left"
	Input.action_press(action)
	for _frame: int in range(380):
		await tree.physics_frame
		if (player.position.x >= x if right else player.position.x <= x) or player.state == PacketPlayer.State.DEAD:
			break
	Input.action_release(action)

func _jump_to(tree: SceneTree, player: PacketPlayer, x: float) -> void:
	Input.action_press(&"jump")
	await _walk_to(tree, player, x)
	for _frame: int in range(40):
		await tree.physics_frame
		if player.is_on_floor() or player.state == PacketPlayer.State.DEAD:
			break
	Input.action_release(&"jump")
	await tree.physics_frame

func _frames(tree: SceneTree, count: int) -> void:
	for _frame: int in range(count):
		await tree.physics_frame

func require_scene(path: String) -> PackedScene:
	if not ResourceLoader.exists(path, "PackedScene"):
		errors.append("falta " + path.get_file())
		return null
	return load(path) as PackedScene

func require_script(path: String) -> Script:
	if not ResourceLoader.exists(path):
		errors.append("falta " + path.get_file())
		return null
	return load(path) as Script

func check(condition: bool, message: String) -> void:
	if not condition:
		errors.append(message)
