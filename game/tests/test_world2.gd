extends RefCounted

var errors: PackedStringArray = []
var finished: bool = false

func run(tree: SceneTree) -> PackedStringArray:
	errors = []
	finished = false
	_test_world_progress()
	_test_wave()
	_test_coverage()
	await _test_spyware(tree)
	finished = true
	return errors

func _test_world_progress() -> void:
	var state: Node = GameState
	var has_world_query: bool = state.has_method(&"is_world_playable")
	check(has_world_query, "falta la consulta de mundos jugables")
	if has_world_query:
		check(not bool(state.call(&"is_world_playable", GameState.data, 2)), "Wi-Fi comienza bloqueado")
	GameState.win()
	check("w1_boss" in GameState.data["completed_levels"], "victoria registra el jefe del mundo 1")
	check(2 in GameState.data["unlocked_worlds"], "victoria desbloquea Wi-Fi")
	var saved: Dictionary = SaveManager.load_game()
	GameState.data = saved
	GameState.win()
	check(GameState.data["unlocked_worlds"].size() == 2, "repetir victoria tras cargar no duplica mundos")
	check(GameState.data["completed_levels"].count("w1_boss") == 1, "repetir victoria no duplica el jefe")
	if has_world_query:
		check(bool(state.call(&"is_world_playable", saved, 2)), "Wi-Fi se puede jugar tras cargar el progreso")
		saved["unlocked_worlds"].append(3)
		check(not bool(state.call(&"is_world_playable", saved, 3)), "Firewall desbloqueado sigue sin escenas")

func _test_wave() -> void:
	var wave: Script = _require_script("res://scripts/objects/wave_zone.gd")
	if wave == null:
		return
	var times: Array[float] = [0.0, 1.9, 2.2, 2.6, 3.1]
	var expected: Array[StringName] = [&"active", &"active", &"inactive", &"warning", &"active"]
	for index: int in range(times.size()):
		check(wave.call(&"state_at", times[index]) == expected[index], "estado de onda a %.1f s" % times[index])

func _test_coverage() -> void:
	var platform: Script = _require_script("res://scripts/objects/coverage_platform.gd")
	if platform == null:
		return
	check(bool(platform.call(&"is_covered", Vector2(159, 0), Vector2.ZERO, 160.0)), "159 px tiene cobertura")
	check(bool(platform.call(&"is_covered", Vector2(160, 0), Vector2.ZERO, 160.0)), "160 px tiene cobertura")
	check(not bool(platform.call(&"is_covered", Vector2(161, 0), Vector2.ZERO, 160.0)), "161 px queda sin cobertura")

func _test_spyware(tree: SceneTree) -> void:
	var scene: PackedScene = _require_scene("res://scenes/enemies/Spyware.tscn")
	if scene == null:
		return
	var stage: Node2D = Node2D.new()
	tree.root.add_child(stage)
	StageBuilder.platform(stage, Vector2(0, 304), Vector2(640, 56))
	var player: PacketPlayer = StageBuilder.player(stage, Vector2(400, 296), 640)
	player.set_physics_process(false)
	var spy: EnemyBase = scene.instantiate() as EnemyBase
	spy.position = Vector2(200, 296)
	stage.add_child(spy)
	await tree.physics_frame
	check(int(spy.get("spy_state")) == 0, "Spyware disfrazado a 200 px")
	check(not spy.is_in_group(&"homing_target") and spy.collision_layer == 0, "el disfraz oculta la hurtbox")
	spy.take_damage(1.0, Vector2.ZERO)
	check(is_equal_approx(spy.health.current, 4.0), "el disfraz es inmune")
	player.position.x = 250.0
	await tree.physics_frame
	await tree.physics_frame
	check(int(spy.get("spy_state")) == 1 and spy.is_in_group(&"homing_target"), "Spyware se revela a 50 px")
	for frame: int in range(24):
		await tree.physics_frame
	var jump_velocity: Vector2 = spy.get("jump_velocity")
	check(int(spy.get("spy_state")) == 2 and jump_velocity.x > 0.0 and jump_velocity.y < 0.0,
		"tras el aviso Spyware salta hacia Byte")
	stage.queue_free()
	await tree.process_frame

func _require_scene(path: String) -> PackedScene:
	if not ResourceLoader.exists(path):
		errors.append("falta " + path.get_file())
		return null
	return load(path) as PackedScene

func _require_script(path: String) -> Script:
	if not ResourceLoader.exists(path):
		errors.append("falta " + path.get_file())
		return null
	return load(path) as Script

func check(condition: bool, message: String) -> void:
	if not condition:
		errors.append(message)
