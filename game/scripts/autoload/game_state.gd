extends Node

signal settings_changed(key: String)

enum Mode { CAMPAIGN, BOSS_RUSH }

const WORLDS: Array[Dictionary] = [
	{"level": "res://scenes/levels/World1Level1.tscn", "boss": "res://scenes/bosses/RouterBoss.tscn"},
	{"level": "res://scenes/levels/World2Level1.tscn", "boss": "res://scenes/bosses/WifiQueenBoss.tscn"},
	{"level": "res://scenes/levels/World3Level1.tscn", "boss": "res://scenes/bosses/FirewallBoss.tscn"},
	{"level": "res://scenes/levels/World4Level1.tscn", "boss": "res://scenes/bosses/TrojanBoss.tscn"},
	{"level": "res://scenes/levels/World5Level1.tscn", "boss": "res://scenes/bosses/MalwarexBoss.tscn"},
]
const MAP: String = "res://scenes/main/NetworkMap.tscn"
const WORKSHOP: String = "res://scenes/ui/Workshop.tscn"
const CREDITS: String = "res://scenes/ui/CreditsScreen.tscn"
const BOSS_RUSH_RESULTS: String = "res://scenes/ui/BossRushResults.tscn"
# Todos los núcleos de datos del juego (2 por nivel salvo el 1-1, más los que sueltan los jefes).
# Los créditos cuentan cuántos se recogieron; `data_cores` es solo el saldo gastable del Taller.
const ALL_CORE_IDS: Array[String] = ["w1_hidden_a", "w1_router", "w2_core_a", "w2_core_b",
	"w3_core_a", "w3_core_b", "w3_firewall_boss", "w4_core_a", "w4_core_b", "w4_trojan_boss",
	"w5_core_a", "w5_core_b"]
var data: Dictionary = {}
var checkpoint: Vector2 = Vector2(48, 296)
var current_world: int = 1
var in_boss: bool = false
var current_level: String:
	get:
		return String(WORLDS[current_world - 1]["boss" if in_boss else "level"])
var boss_progress: float = 0.0
var level_progress: float = 0.0
var puzzle_complete: bool = false
var playing: bool = false
var death_cause: String = "nivel_1_1"
var save_error: Error = OK
var level_record: bool = false
var boss_record: bool = false
var _stage_time: float = 0.0
var _boss_cleared: bool = false
var mode: Mode = Mode.CAMPAIGN
var boss_rush_active: bool:
	get:
		return mode == Mode.BOSS_RUSH
var boss_rush_unlocked: bool:
	get:
		return bool(data.get("unlocked_boss_rush", false))
var boss_rush_time: float = 0.0
var boss_rush_defeated: int = 0
var boss_rush_hp: float = -1.0
var boss_rush_record: bool = false
var _campaign_world: int = 1
var settings: Dictionary:
	get:
		return data.get("settings", {})
var reduce_flashes: bool:
	get:
		return bool(settings.get("reduce_flashes", false))
var assist_mode: bool:
	get:
		return bool(settings.get("assist_mode", false))
var screen_shake: bool:
	get:
		return bool(settings.get("screen_shake", true))

func _ready() -> void:
	restore()

func restore() -> void:
	data = SaveManager.load_game()
	InputBindings.apply(settings["bindings"])
	restore_speed()
	settings_changed.emit("")

func update_setting(key: String, value: Variant) -> Error:
	var current: Dictionary = settings
	var previous: Variant = current[key]
	current[key] = value
	var result: Error = save()
	if result != OK:
		current[key] = previous
		return result
	if key == "assist_mode":
		restore_speed()
	elif key == "bindings":
		InputBindings.apply(value)
	settings_changed.emit(key)
	return OK

func restore_speed() -> void:
	Engine.time_scale = 0.8 if assist_mode else 1.0

func _process(delta: float) -> void:
	var scene: Node = get_tree().current_scene
	if not playing or scene == null or scene.scene_file_path != current_level:
		return
	if boss_rush_active:
		if not _boss_cleared:
			boss_rush_time += delta
		return
	data["stats"]["play_time_s"] = float(data["stats"]["play_time_s"]) + delta
	if not _boss_cleared:
		_stage_time += delta

static func is_world_unlocked(progress: Dictionary, world: int) -> bool:
	var unlocked: Array = progress.get("unlocked_worlds", [])
	# JSON carga los mundos como números de punto flotante.
	return world in unlocked or float(world) in unlocked

static func is_world_playable(progress: Dictionary, world: int) -> bool:
	return is_world_unlocked(progress, world) and has_world_scenes(world)

static func has_world_scenes(world: int) -> bool:
	if world < 1 or world > WORLDS.size():
		return false
	var scenes: Dictionary = WORLDS[world - 1]
	return ResourceLoader.exists(scenes["level"], "PackedScene") and ResourceLoader.exists(scenes["boss"], "PackedScene")

func start_run(world: int = 1) -> void:
	if not is_world_playable(data, world):
		return
	mode = Mode.CAMPAIGN
	current_world = world
	in_boss = false
	checkpoint = Vector2(48, 296)
	puzzle_complete = false
	boss_progress = 0.0
	level_progress = 0.0
	level_record = false
	_reset_attempt()
	playing = true
	change_scene(current_level)

func retry() -> void:
	if boss_rush_active:
		return
	_reset_attempt()
	playing = true
	boss_progress = 0.0
	level_progress = 0.0
	change_scene(current_level)

func enter_boss() -> void:
	if in_boss:
		return
	if playing:
		level_record = _record_clear(false)
		save()
	in_boss = true
	_reset_attempt()
	checkpoint = Vector2(64, 296)
	Events.checkpoint_reached.emit(checkpoint)
	change_scene(current_level)

func change_scene(path: String) -> void:
	get_tree().paused = false
	restore_speed()
	get_tree().change_scene_to_file.call_deferred(path)

func collect_core(id: StringName) -> bool:
	if boss_rush_active:
		return false
	var cores: Array = data["collected_cores"]
	if String(id) in cores:
		return false
	cores.append(String(id))
	data["data_cores"] = int(data["data_cores"]) + 1
	if String(id) in StageStats.LEVEL_CORES[current_world - 1]:
		StageStats.entry(data, current_world, false)["cores_collected"] = StageStats.core_count(data, current_world)
	Events.core_collected.emit(id)
	save_error = SaveManager.save_game(data)
	return true

func record_death() -> void:
	if boss_rush_active:
		end_boss_rush()
		return
	playing = false
	var deaths: Dictionary = data["stats"]["deaths"]
	deaths[death_cause] = int(deaths.get(death_cause, 0)) + 1
	var stats: Dictionary = StageStats.entry(data, current_world, in_boss)
	stats["deaths"] = int(stats.get("deaths", 0)) + 1
	save_error = SaveManager.save_game(data)

func _reset_attempt() -> void:
	_stage_time = 0.0
	_boss_cleared = false
	boss_record = false

func _record_clear(boss: bool) -> bool:
	var stats: Dictionary = StageStats.entry(data, current_world, boss)
	stats["completions"] = int(stats.get("completions", 0)) + 1
	var best: Variant = stats.get("best_time_s")
	if _stage_time <= 0.0 or (best != null and _stage_time >= float(best)):
		return false
	stats["best_time_s"] = _stage_time
	return true

func record_boss_clear(health: HealthComponent, reward: StringName = &"") -> void:
	if boss_rush_active:
		if playing and not _boss_cleared:
			_boss_cleared = true
			boss_rush_defeated += 1
			health.heal(1.0)
			boss_rush_hp = health.current
		return
	if playing and not _boss_cleared:
		boss_record = _record_clear(true)
		_boss_cleared = true
		if current_world == 1:
			save()
	# El Router conserva el núcleo físico y registra la progresión al recogerlo.
	if current_world != 1:
		if reward != &"":
			collect_core(reward)
		win()

func continue_after_boss() -> void:
	if boss_rush_active:
		if not playing or not _boss_cleared:
			return
		if boss_rush_defeated == WORLDS.size():
			end_boss_rush()
		else:
			_enter_rush_boss(boss_rush_defeated + 1)
	elif current_world == WORLDS.size():
		show_credits()
	else:
		open_map()

func start_boss_rush() -> void:
	if not boss_rush_unlocked or (boss_rush_active and playing):
		return
	if not boss_rush_active:
		_campaign_world = current_world
	mode = Mode.BOSS_RUSH
	boss_rush_time = 0.0
	boss_rush_defeated = 0
	boss_rush_hp = -1.0
	boss_rush_record = false
	_enter_rush_boss(1)

func _enter_rush_boss(world: int) -> void:
	current_world = world
	in_boss = true
	checkpoint = Vector2(64, 296)
	boss_progress = 0.0
	_reset_attempt()
	playing = true
	change_scene(current_level)

func end_boss_rush() -> void:
	if not boss_rush_active or not playing:
		return
	playing = false
	var stats: Dictionary = data["stats"]["boss_rush"]
	var best: Variant = stats["best_time_s"]
	if boss_rush_defeated > int(stats["best_bosses"]):
		stats["best_bosses"] = boss_rush_defeated
		boss_rush_record = true
	if boss_rush_defeated == WORLDS.size() and boss_rush_time > 0.0 and (best == null or boss_rush_time < float(best)):
		stats["best_time_s"] = boss_rush_time
		boss_rush_record = true
	if boss_rush_record:
		save()
	change_scene(BOSS_RUSH_RESULTS)

func win() -> void:
	if boss_rush_active:
		return
	playing = false
	var completed: Array = data["completed_levels"]
	# Conserva el identificador que ya registraba la victoria del Router.
	if current_world == 1 and "w1_l1" not in completed:
		completed.append("w1_l1")
	var boss_id: String = "w%d_boss" % current_world
	if boss_id not in completed:
		completed.append(boss_id)
	var next_world: int = current_world + 1
	if current_world == WORLDS.size():
		data["finished"] = true
	elif not is_world_unlocked(data, next_world):
		data["unlocked_worlds"].append(next_world)
	save_error = SaveManager.save_game(data)

func save() -> Error:
	save_error = SaveManager.save_game(data)
	return save_error

func open_map() -> void:
	playing = false
	if boss_rush_active:
		current_world = _campaign_world
		in_boss = false
		mode = Mode.CAMPAIGN
	change_scene(MAP)

func open_workshop() -> void:
	playing = false
	change_scene(WORKSHOP)

func show_credits() -> void:
	playing = false
	change_scene(CREDITS)

func visit_credits() -> void:
	if bool(data.get("finished", false)) and not boss_rush_unlocked:
		data["unlocked_boss_rush"] = true
		save()

func new_game() -> Error:
	var fresh: Dictionary = SaveManager.defaults()
	var saved_settings: Dictionary = data.get("settings", fresh["settings"])
	fresh["settings"] = saved_settings.duplicate(true)
	save_error = SaveManager.save_game(fresh)
	if save_error == OK:
		data = fresh
		start_run()
	return save_error

func menu() -> void:
	playing = false
	change_scene("res://scenes/main/Main.tscn")
