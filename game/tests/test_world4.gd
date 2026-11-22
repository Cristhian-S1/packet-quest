extends RefCounted

const LEVEL: String = "res://scenes/levels/World4Level1.tscn"
const BOSS: String = "res://scenes/bosses/TrojanBoss.tscn"

var errors: PackedStringArray = []
var finished: bool = false

func run(_tree: SceneTree) -> PackedStringArray:
	_test_world_progress()
	_test_platforms()
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

func _test_platforms() -> void:
	var vent: Script = require_script("res://scripts/objects/air_vent.gd")
	if vent != null:
		var times: Array[float] = [0.0, 1.9, 2.2, 2.6, 3.1]
		var states: Array[StringName] = [&"active", &"active", &"inactive", &"warning", &"active"]
		for index: int in range(times.size()):
			check(vent.call(&"state_at", times[index]) == states[index], "estado del ventilador a %.1f s" % times[index])
		for sample: Vector2 in [Vector2(0, -240), Vector2(-330, -330), Vector2(100, -240)]:
			check(float(vent.call(&"lift_velocity", sample.x, 240.0)) == sample.y, "impulso vertical desde %s" % sample.x)
	var elevator: Script = require_script("res://scripts/objects/data_elevator.gd")
	if elevator != null:
		var bottom: float = elevator.call(&"top_y", 280.0, 64.0, 3.2, 0.0)
		var top: float = elevator.call(&"top_y", 280.0, 64.0, 3.2, 1.6)
		var returned: float = elevator.call(&"top_y", 280.0, 64.0, 3.2, 3.2)
		check(is_equal_approx(bottom, 280.0) and is_equal_approx(top, 216.0)
			and is_equal_approx(returned, 280.0), "el ascensor sube 64 px y regresa al anclaje")
		check(304.0 - bottom == 24.0 and top - 176.0 == 40.0, "ambos saltos del ascensor miden menos de 60 px")

func require_script(path: String) -> Script:
	if not ResourceLoader.exists(path):
		errors.append("falta " + path.get_file())
		return null
	return load(path) as Script

func check(condition: bool, message: String) -> void:
	if not condition:
		errors.append(message)
