extends RefCounted

var errors: PackedStringArray = []
var finished: bool = false

func run(_tree: SceneTree) -> PackedStringArray:
	_test_world_progress()
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

func check(condition: bool, message: String) -> void:
	if not condition:
		errors.append(message)
