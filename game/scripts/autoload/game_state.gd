extends Node

const LEVEL: String = "res://scenes/levels/World1Level1.tscn"
const BOSS: String = "res://scenes/bosses/RouterBoss.tscn"
var data: Dictionary = {}
var checkpoint: Vector2 = Vector2(48, 296)
var current_level: String = LEVEL
var boss_progress: float = 0.0
var puzzle_complete: bool = false
var playing: bool = false
var death_cause: String = "nivel_1_1"
var save_error: Error = OK

func _ready() -> void:
	call_deferred("restore")

func restore() -> void:
	data = SaveManager.load_game()

func _process(delta: float) -> void:
	if playing and not data.is_empty():
		data["stats"]["play_time_s"] = float(data["stats"]["play_time_s"]) + delta

func start_run() -> void:
	checkpoint = Vector2(48, 296)
	current_level = LEVEL
	puzzle_complete = false
	boss_progress = 0.0
	playing = true
	change_scene(LEVEL)

func retry() -> void:
	playing = true
	boss_progress = 0.0
	change_scene(current_level)

func enter_boss() -> void:
	current_level = BOSS
	checkpoint = Vector2(64, 296)
	Events.checkpoint_reached.emit(checkpoint)
	change_scene(BOSS)

func change_scene(path: String) -> void:
	get_tree().paused = false
	Engine.time_scale = 0.8 if bool(data.get("settings", {}).get("assist_mode", false)) else 1.0
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
	if "w1_l1" not in completed:
		completed.append("w1_l1")
	var worlds: Array = data["unlocked_worlds"]
	if 2 not in worlds:
		worlds.append(2)
	save_error = SaveManager.save_game(data)

func menu() -> void:
	playing = false
	change_scene("res://scenes/main/Main.tscn")
