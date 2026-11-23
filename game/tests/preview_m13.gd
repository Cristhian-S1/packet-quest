extends RefCounted

const ENEMIES: Array[String] = ["PopUp", "NetworkWorm", "Spyware", "ArmoredPopUp", "ArmoredWorm", "Trojan", "BotDDoS"]
const BOSSES: Array[String] = ["RouterBoss", "WifiQueenBoss", "FirewallBoss", "TrojanBoss", "MalwarexBoss"]
const BYTE_POSES: Array[String] = ["reposo", "carrera", "salto", "caida", "dash", "disparo", "dano", "muerte", "escudo"]

var directory: String
var failed: bool = false

func capture(suite: RefCounted, tree: SceneTree, before: bool) -> void:
	directory = ProjectSettings.globalize_path("res://../docs/capturas/m13/" + ("antes" if before else "despues")).simplify_path()
	if DirAccess.make_dir_recursive_absolute(directory) != OK:
		push_error("No se pudo crear " + directory)
		tree.quit(1)
		return
	SaveManager.save_path = "res://.godot/preview_m13_session.json"
	GameState.data = SaveManager.defaults()
	GameState.checkpoint = Vector2(48, 296)
	var gallery: Node2D = Node2D.new()
	gallery.process_mode = Node.PROCESS_MODE_DISABLED
	tree.root.add_child(gallery)
	StageBuilder.background(gallery)
	var chip: ChipPlatform = StageBuilder.platform(gallery, Vector2(262, 189), Vector2(116, 32))
	var camera: Camera2D = Camera2D.new()
	camera.position = Vector2(320, 180)
	camera.zoom = Vector2(5, 5)
	gallery.add_child(camera)
	var byte: PacketPlayer = StageBuilder.player(gallery, Vector2(320, 180))
	camera.make_current()
	for index: int in range(BYTE_POSES.size()):
		byte.state = [PacketPlayer.State.IDLE, PacketPlayer.State.RUN, PacketPlayer.State.JUMP,
			PacketPlayer.State.FALL, PacketPlayer.State.DASH, PacketPlayer.State.IDLE, PacketPlayer.State.HURT,
			PacketPlayer.State.DEAD, PacketPlayer.State.SHIELD][index] as PacketPlayer.State
		byte.animation_time = 0.36
		byte.hurt_left = byte.hurt_duration if index == 6 else 0.0
		byte.shield_active = index == 8
		if "art_shot_left" in byte:
			byte.set("art_shot_left", 0.08 if index == 5 else 0.0)
			byte.set("art_death_age", 0.17 if index == 7 else 0.0)
		byte.trails.clear()
		if index == 4:
			for distance: int in [7, 14, 21]:
				byte.trails.append(byte.position - Vector2(distance, 0))
		chip.visible = index != 2 and index != 3 and index != 4 and index != 7
		byte.queue_redraw()
		await _snap(suite, "byte-" + BYTE_POSES[index])
	byte.hide()
	chip.hide()
	for scene_name: String in ENEMIES:
		var scene: PackedScene = load("res://scenes/enemies/%s.tscn" % scene_name)
		var enemy: EnemyBase = scene.instantiate() as EnemyBase
		enemy.position = Vector2(320, 180)
		gallery.add_child(enemy)
		enemy.self_modulate.a = 1.0
		enemy.age = 0.43
		for index: int in range(3):
			enemy.state = [EnemyBase.State.IDLE, EnemyBase.State.TELEGRAPH, EnemyBase.State.DEAD][index] as EnemyBase.State
			enemy.timer = enemy.telegraph_time * 0.36 if index == 1 else 0.17
			if "spy_state" in enemy:
				enemy.set("spy_state", [3, 1, 2][index])
			enemy.queue_redraw()
			var pose: String = ["reposo", "aviso", "muerte"][index]
			await _snap(suite, scene_name.to_snake_case() + "-" + pose)
		enemy.queue_free()
		await tree.process_frame
	gallery.queue_free()
	await tree.process_frame

	for index: int in range(BOSSES.size()):
		GameState.data = SaveManager.defaults()
		GameState.current_world = index + 1
		var level_scene: PackedScene = load("res://scenes/levels/World%dLevel1.tscn" % (index + 1))
		var level: Node2D = level_scene.instantiate() as Node2D
		tree.root.add_child(level)
		await _snap(suite, "mundo-%d" % (index + 1))
		level.queue_free()
		await tree.process_frame
		var boss_name: String = BOSSES[index]
		var boss_scene: PackedScene = load("res://scenes/bosses/%s.tscn" % boss_name)
		var boss: Node2D = boss_scene.instantiate() as Node2D
		tree.root.add_child(boss)
		boss.set_physics_process(false)
		boss.call("_physics_process", 1.2)
		await _snap(suite, boss_name.to_snake_case() + "-fase-1")
		var phase: int = int(boss.get("phase"))
		boss.set("phase", phase + 1)
		boss.queue_redraw()
		await _snap(suite, boss_name.to_snake_case() + "-fase-2")
		boss.call("_defeat")
		boss.call("_physics_process", 0.18)
		await _snap(suite, boss_name.to_snake_case() + "-restaurado")
		boss.queue_free()
		await tree.process_frame
	print("CAPTURAS M13: " + directory)
	tree.quit(1 if failed else 0)

func _snap(suite: RefCounted, file: String) -> void:
	var result: Error = await suite.call("snap", file, directory)
	if result != OK:
		push_error("No se pudo guardar %s.png (%d)" % [file, result])
		failed = true
