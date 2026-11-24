extends RefCounted

var errors: PackedStringArray = []
var finished: bool = false

func run(tree: SceneTree) -> PackedStringArray:
	_test_migration()
	await _test_attempts(tree)
	finished = true
	return errors

func _test_migration() -> void:
	var old: Dictionary = SaveManager.defaults()
	old["stats"] = {"deaths": {"nivel_1_1": 3, "router_boss": 2, "router_boss_A": 1}, "play_time_s": 24.0}
	old["collected_cores"] = ["w1_hidden_a", "w1_router"]
	old["completed_levels"] = ["w1_l1", "w1_boss"]
	old["data_cores"] = 1
	old["unlocked_worlds"] = [1, 2]
	check(SaveManager.save_game(old) == OK, "escribe guardado anterior a M15")
	var restored: Dictionary = SaveManager.load_game()
	check(int(restored["data_cores"]) == 1 and GameState.is_world_unlocked(restored, 2), "la migración conserva saldo y mundos")
	var level: Dictionary = _stats(restored, "w1_l1")
	var boss: Dictionary = _stats(restored, "w1_boss")
	check(level.get("deaths") == 3 and boss.get("deaths") == 3, "migra muertes conocidas por escenario")
	check(level.get("completions") == 1 and boss.get("completions") == 1, "migra las finalizaciones conocidas")
	check(level.get("cores_collected") == 1 and level.get("cores_available") == 1, "migra núcleos únicos del nivel")
	check(level.has("best_time_s") and level["best_time_s"] == null, "el guardado antiguo carece de tiempos por nivel")

func _test_attempts(tree: SceneTree) -> void:
	GameState.start_run()
	await tree.scene_changed
	GameState.collect_core(&"w1_hidden_a")
	check(_stats(SaveManager.load_game(), "w1_l1").get("cores_collected") == 1, "recoger el núcleo actualiza las estadísticas persistidas")
	await _frames(tree, 12)
	var before_pause: float = float(GameState.data["stats"]["play_time_s"])
	tree.paused = true
	await _frames(tree, 90)
	check(float(GameState.data["stats"]["play_time_s"]) == before_pause, "el reloj se congela durante pausa")
	tree.paused = false
	GameState.enter_boss()
	await tree.scene_changed
	var best: Variant = _stats(GameState.data, "w1_l1").get("best_time_s")
	check(best != null and absf(float(best) - before_pause) < 0.04, "el récord de nivel excluye la pausa")
	await _frames(tree, 12)
	var router: RouterBoss = tree.current_scene as RouterBoss
	router.health.damage(router.health.max_health)
	var boss: Dictionary = _stats(GameState.data, "w1_boss")
	check(boss.get("completions") == 1 and float(boss.get("best_time_s", 0.0)) > 0.0, "el jefe registra el tiempo al caer")
	check(not GameState.is_world_unlocked(GameState.data, 2), "el Router todavía requiere recoger el núcleo")
	GameState.start_run()
	await tree.scene_changed
	await _frames(tree, 30)
	GameState.enter_boss()
	await tree.scene_changed
	check(_stats(GameState.data, "w1_l1").get("best_time_s") == best, "un intento más lento conserva el récord")
	GameState.start_run()
	await tree.scene_changed
	await _frames(tree, 3)
	GameState.enter_boss()
	await tree.scene_changed
	var level: Dictionary = _stats(GameState.data, "w1_l1")
	check(best != null and float(level.get("best_time_s", 0.0)) < float(best), "un intento más rápido mejora el récord")
	check(level.get("completions") == 3, "cada pasada suma una finalización")
	for _attempt: int in range(2):
		var byte: PacketPlayer = tree.get_first_node_in_group(&"player") as PacketPlayer
		byte.health.damage(byte.health.max_health)
		GameState.retry()
		await tree.scene_changed
	check(_stats(GameState.data, "w1_boss").get("deaths") == 2, "las muertes se acumulan por jefe")
	check(CreditsScreen.best_run_line({"levels": {"w1_l1": {"best_time_s": 24.0}, "w1_boss": {"best_time_s": 37.5}}})
		== "Mejor partida: 01:01.50  ·  2/10 tramos con marca", "créditos suman los mejores tiempos disponibles")
	GameState.open_map()
	await tree.scene_changed

func _stats(progress: Dictionary, id: String) -> Dictionary:
	return progress["stats"].get("levels", {}).get(id, {})

func _frames(tree: SceneTree, count: int) -> void:
	for _frame: int in range(count):
		await tree.process_frame

func check(ok: bool, message: String) -> void:
	if not ok:
		errors.append(message)
