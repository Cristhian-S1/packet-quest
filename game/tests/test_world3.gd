extends RefCounted

var errors: PackedStringArray = []
var finished: bool = false

func run(_tree: SceneTree) -> PackedStringArray:
	_test_world_progress()
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

func check(condition: bool, message: String) -> void:
	if not condition:
		errors.append(message)
