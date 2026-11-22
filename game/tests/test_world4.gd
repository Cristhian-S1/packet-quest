extends RefCounted

const LEVEL: String = "res://scenes/levels/World4Level1.tscn"
const BOSS: String = "res://scenes/bosses/TrojanBoss.tscn"

var errors: PackedStringArray = []
var finished: bool = false

func run(_tree: SceneTree) -> PackedStringArray:
	_test_world_progress()
	finished = true
	return errors

func _test_world_progress() -> void:
	GameState.current_world = 3
	check(not GameState.is_world_playable(GameState.data, 4), "Servidor comienza bloqueado")
	GameState.win()
	var saved: Dictionary = SaveManager.load_game()
	check(GameState.is_world_unlocked(saved, 4), "vencer al Firewall desbloquea Servidor")
	check(GameState.WORLDS.size() == 4 and GameState.WORLDS.has({"level": LEVEL, "boss": BOSS}),
		"Servidor registra su nivel y su jefe")
	check(GameState.is_world_playable(saved, 4) == (ResourceLoader.exists(LEVEL) and ResourceLoader.exists(BOSS)),
		"Servidor requiere ambas escenas para poder jugar")
	saved["unlocked_worlds"].append(5)
	check(not GameState.is_world_playable(saved, 5), "Centro de datos sigue pendiente aunque esté desbloqueado")

func check(condition: bool, message: String) -> void:
	if not condition:
		errors.append(message)
