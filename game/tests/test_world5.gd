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
	var puzzle: Node2D = scene.instantiate() as Node2D
	tree.root.add_child(puzzle)
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
		for id: StringName in correct:
			nodes[id].call(&"interact")
		check(door.opened and GameState.puzzle_complete and solved.size() == 1
			and AudioManager.last_sfx == &"cable_connected", "QoS abre la puerta y emite la conexión")
	puzzle.queue_free()
	await tree.process_frame

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
