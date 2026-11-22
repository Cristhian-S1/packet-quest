extends RefCounted

var errors: PackedStringArray = []
var finished: bool = false

func run(_tree: SceneTree) -> PackedStringArray:
	errors = []
	finished = false
	_test_world_progress()
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

func check(condition: bool, message: String) -> void:
	if not condition:
		errors.append(message)
