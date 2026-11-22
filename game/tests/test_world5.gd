extends RefCounted

const LEVEL: String = "res://scenes/levels/World5Level1.tscn"
const BOSS: String = "res://scenes/bosses/MalwarexBoss.tscn"

var errors: PackedStringArray = []
var finished: bool = false

func run(tree: SceneTree) -> PackedStringArray:
	_test_progress()
	await _test_cloud(tree)
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

func require_script(path: String) -> Script:
	if not ResourceLoader.exists(path):
		errors.append("falta " + path.get_file())
		return null
	return load(path) as Script

func check(condition: bool, message: String) -> void:
	if not condition:
		errors.append(message)
