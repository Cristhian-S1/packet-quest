extends RefCounted

var errors: PackedStringArray = []
var finished: bool = false

func run(_tree: SceneTree) -> PackedStringArray:
	errors = []
	finished = false
	_test_world_progress()
	_test_wave()
	_test_coverage()
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

func _require_script(path: String) -> Script:
	if not ResourceLoader.exists(path):
		errors.append("falta " + path.get_file())
		return null
	return load(path) as Script

func check(condition: bool, message: String) -> void:
	if not condition:
		errors.append(message)
