extends RefCounted

const BOSS_NAMES: Array[String] = ["RouterBoss", "WifiQueenBoss", "FirewallBoss", "TrojanBoss", "MalwarexBoss"]
const RESULTS: String = "res://scenes/ui/BossRushResults.tscn"

var errors: PackedStringArray = []
var finished: bool = false

func run(tree: SceneTree) -> PackedStringArray:
	GameState.open_map()
	await tree.scene_changed
	check(_button(tree.current_scene, "Boss Rush") == null, "el mapa oculta Boss Rush antes de los créditos")
	GameState.start_boss_rush()
	await tree.process_frame
	check(tree.current_scene.scene_file_path == GameState.MAP, "Boss Rush bloqueado no arranca")
	GameState.data["finished"] = true
	GameState.data.erase("unlocked_boss_rush")
	GameState.data["stats"].erase("boss_rush")
	SaveManager.save_game(GameState.data)
	GameState.data = SaveManager.load_game()
	check(GameState.data.get("unlocked_boss_rush") == false, "un guardado anterior con Malwarex vencido conserva el bloqueo hasta ver créditos")
	GameState.show_credits()
	await tree.scene_changed
	check(SaveManager.load_game().get("unlocked_boss_rush") == true, "ver créditos desbloquea y guarda Boss Rush")
	GameState.open_map()
	await tree.scene_changed
	var rush: Button = _button(tree.current_scene, "Boss Rush")
	check(rush != null, "el mapa muestra Boss Rush después de los créditos")
	if rush != null:
		await _test_rounds(tree, rush)
	finished = true
	return errors

func _test_rounds(tree: SceneTree, rush: Button) -> void:
	GameState.data["owned_upgrades"] = ["more_health", "ping"]
	GameState.data["equipped"]["weapons"] = ["packet", "ping"]
	GameState.data["data_cores"] = 2
	GameState.data["collected_cores"] = ["w1_hidden_a"]
	var before: Dictionary = GameState.data.duplicate(true)
	rush.pressed.emit()
	await tree.scene_changed
	var router: RouterBoss = tree.current_scene as RouterBoss
	check(router.find_child("RushClock", true, false) is Label, "el HUD muestra el cronómetro de Boss Rush")
	for _frame: int in range(12):
		await tree.process_frame
	var paused_at: float = GameState.boss_rush_time
	tree.paused = true
	for _frame: int in range(30):
		await tree.process_frame
	check(paused_at > 0.0 and GameState.boss_rush_time == paused_at, "la pausa congela el reloj de la ronda")
	tree.paused = false
	GameState.retry()
	await tree.process_frame
	check(tree.current_scene == router, "el reintento de checkpoint no recarga la arena en Boss Rush")
	check(not GameState.collect_core(&"w1_router"), "Boss Rush rechaza la recogida de núcleos")
	router.health.damage(router.health.max_health)
	await tree.scene_changed
	var queen: WifiQueenBoss = tree.current_scene as WifiQueenBoss
	queen.player.health.damage(queen.player.health.max_health)
	await tree.scene_changed
	var partial: Dictionary = GameState.data["stats"]["boss_rush"]
	check(partial["best_bosses"] == 1 and partial["best_time_s"] == null, "una ronda parcial solo mejora el número de jefes")
	_button(tree.current_scene, "Reintentar").pressed.emit()
	await tree.scene_changed
	for index: int in range(BOSS_NAMES.size()):
		var arena: Node = tree.current_scene
		check(arena.scene_file_path.get_file().get_basename() == BOSS_NAMES[index], "orden del jefe %d" % (index + 1))
		var byte: PacketPlayer = tree.get_first_node_in_group(&"player") as PacketPlayer
		check(byte.health.max_health == 4.0 and byte.weapon_slots.size() == 2, "Byte conserva sus mejoras y armas")
		if index == 0:
			check(byte.health.current == 4.0, "la ronda empieza a tope de PV")
			byte.health.damage(2.0)
		else:
			check(byte.health.current == (3.0 if index == 1 else 4.0), "+1 PV entre jefes acotado al máximo")
		for _frame: int in range(12):
			await tree.process_frame
		var health: HealthComponent = arena.get("health") as HealthComponent
		health.damage(health.max_health)
		await tree.scene_changed
	check(tree.current_scene.scene_file_path == RESULTS, "vencer a los cinco lleva a los resultados")
	var won: Dictionary = GameState.data["stats"]["boss_rush"].duplicate()
	check(won.get("best_bosses") == 5 and float(won.get("best_time_s", 0.0)) > 0.0, "guarda la mejor ronda completa")
	var restored: Dictionary = SaveManager.load_game()["stats"]["boss_rush"]
	check(restored["best_bosses"] == won["best_bosses"]
		and is_equal_approx(float(restored["best_time_s"]), float(won["best_time_s"])), "persiste las marcas de Boss Rush")
	var retry: Button = _button(tree.current_scene, "Reintentar")
	check(retry != null, "los resultados permiten reintentar la ronda")
	if retry == null:
		return
	retry.pressed.emit()
	await tree.scene_changed
	check(tree.current_scene is RouterBoss, "reintentar vuelve al primer jefe")
	var player: PacketPlayer = tree.get_first_node_in_group(&"player") as PacketPlayer
	player.health.damage(player.health.max_health)
	await tree.scene_changed
	check(tree.current_scene.scene_file_path == RESULTS, "morir termina la ronda")
	check(GameState.data["stats"].get("boss_rush", {}) == won, "morir mantiene las marcas anteriores")
	for key: String in ["data_cores", "collected_cores", "unlocked_worlds", "completed_levels", "finished"]:
		check(GameState.data[key] == before[key], "Boss Rush conserva %s" % key)
	for key: String in ["levels", "deaths", "play_time_s"]:
		check(GameState.data["stats"].get(key) == before["stats"].get(key), "Boss Rush aísla las estadísticas normales (%s)" % key)
	var map: Button = _button(tree.current_scene, "Volver al mapa")
	check(map != null, "los resultados permiten volver al mapa")
	if map != null:
		map.pressed.emit()
		await tree.scene_changed
		check(tree.current_scene.scene_file_path == GameState.MAP, "salir de resultados vuelve al mapa")

func _button(root: Node, label: String) -> Button:
	for child: Node in root.find_children("*", "Button", true, false):
		var button: Button = child as Button
		if button.text == label:
			return button
	return null

func check(ok: bool, message: String) -> void:
	if not ok:
		errors.append(message)
