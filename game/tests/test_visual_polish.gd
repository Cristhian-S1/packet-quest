extends RefCounted

var errors: PackedStringArray = []
var finished: bool = false

func run(tree: SceneTree) -> PackedStringArray:
	await _test_parallax(tree)
	await _test_core(tree)
	await _test_bosses(tree)
	GameState.current_world = 1
	GameState.in_boss = false
	GameState.data = SaveManager.defaults()
	GameState.settings_changed.emit("")
	finished = true
	return errors

func _test_parallax(tree: SceneTree) -> void:
	for index: int in range(1, GameState.WORLDS.size()):
		var path: String = GameState.WORLDS[index]["level"]
		var level: Node2D = (load(path) as PackedScene).instantiate() as Node2D
		tree.root.add_child(level)
		var backdrop: CanvasLayer = level.get_node_or_null("LevelParallax") as CanvasLayer
		if backdrop == null:
			errors.append("%s debe tener tres capas de parallax" % path.get_file())
		else:
			_check(backdrop.layer < 0, "parallax detrás del escenario")
			var grid: Node2D = backdrop.get_node("Grid") as Node2D
			var racks: Node2D = backdrop.get_node("CablesAndRacks") as Node2D
			var leds: Node2D = backdrop.get_node("LEDs") as Node2D
			var player: PacketPlayer = level.get("player") as PacketPlayer
			player.camera.position_smoothing_enabled = false
			player.position.x = 480.0
			player.camera.force_update_scroll()
			backdrop.call("_process", 0.0)
			_check(0.0 > grid.position.x and grid.position.x > racks.position.x
				and racks.position.x > leds.position.x, "%s debe separar las tres velocidades" % path.get_file())
		level.queue_free()
		await tree.process_frame

func _test_core(tree: SceneTree) -> void:
	var level: World1Level1 = preload("res://scenes/levels/World1Level1.tscn").instantiate() as World1Level1
	tree.root.add_child(level)
	var core: DataCore = DataCore.new()
	core.core_id = &"test_m12"
	core.position = Vector2(128, 220)
	level.add_child(core)
	GameState.settings["reduce_flashes"] = true
	GameState.settings["screen_shake"] = false
	core._entered(level.player)
	_check(core.taken and AudioManager.last_sfx == &"core_collected", "recoger núcleo real debe reproducir su efecto")
	var burst: Node2D = level.get_node_or_null("CoreBurst") as Node2D
	_check(burst != null and burst.global_position == core.global_position, "el núcleo debe emitir partículas donde se recoge")
	if burst != null:
		_check(is_zero_approx(float(burst.call("flash_alpha"))), "reducir destellos debe conservar partículas sin anillo brillante")
		GameState.settings["reduce_flashes"] = false
		_check(float(burst.call("flash_alpha")) > 0.0, "el efecto normal debe mostrar el destello local")
	_check(level.player.shake_left == 0.0, "el núcleo debe respetar la sacudida desactivada")
	level.queue_free()
	await tree.process_frame

func _test_bosses(tree: SceneTree) -> void:
	for world: Dictionary in GameState.WORLDS:
		GameState.data = SaveManager.defaults()
		var path: String = world["boss"]
		var boss: Node2D = (load(path) as PackedScene).instantiate() as Node2D
		tree.root.add_child(boss)
		var player: PacketPlayer = boss.get("player") as PacketPlayer
		boss.call("_defeat")
		var burst: Node2D = boss.get_node_or_null("BossBurst") as Node2D
		_check(burst != null and AudioManager.last_sfx == &"boss_defeated", "%s debe celebrar la victoria" % path.get_file())
		_check(player.shake_left > 0.0, "%s debe activar la sacudida" % path.get_file())
		if player.shake_left > 0.0:
			await tree.process_frame
			await tree.process_frame
			_check(player.camera.offset != Vector2.ZERO, "%s debe mover la cámara al vencer" % path.get_file())
		GameState.settings["screen_shake"] = false
		GameState.settings_changed.emit("screen_shake")
		_check(player.camera.offset == Vector2.ZERO and player.shake_left == 0.0,
			"%s debe cancelar la sacudida al desactivarla" % path.get_file())
		boss.queue_free()
		await tree.process_frame

func _check(condition: bool, message: String) -> void:
	if not condition:
		errors.append(message)
