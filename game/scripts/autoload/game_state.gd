extends Node

signal settings_changed(key: String)

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
var puzzle_complete: bool = false
var playing: bool = false
var death_cause: String = "nivel_1_1"
var save_error: Error = OK
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
	if playing and not data.is_empty():
		data["stats"]["play_time_s"] = float(data["stats"]["play_time_s"]) + delta

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
	current_world = world
	in_boss = false
	checkpoint = Vector2(48, 296)
	puzzle_complete = false
	boss_progress = 0.0
	playing = true
	change_scene(current_level)

func retry() -> void:
	playing = true
	boss_progress = 0.0
	change_scene(current_level)

func enter_boss() -> void:
	in_boss = true
	checkpoint = Vector2(64, 296)
	Events.checkpoint_reached.emit(checkpoint)
	change_scene(current_level)

func change_scene(path: String) -> void:
	get_tree().paused = false
	restore_speed()
	get_tree().change_scene_to_file.call_deferred(path)

func collect_core(id: StringName) -> bool:
	var cores: Array = data["collected_cores"]
	if String(id) in cores:
		return false
	cores.append(String(id))
	data["data_cores"] = int(data["data_cores"]) + 1
	Events.core_collected.emit(id)
	save_error = SaveManager.save_game(data)
	return true

func record_death() -> void:
	playing = false
	var deaths: Dictionary = data["stats"]["deaths"]
	deaths[death_cause] = int(deaths.get(death_cause, 0)) + 1
	save_error = SaveManager.save_game(data)

func win() -> void:
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
	change_scene(MAP)

func open_workshop() -> void:
	playing = false
	change_scene(WORKSHOP)

func show_credits() -> void:
	playing = false
	change_scene(CREDITS)

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
