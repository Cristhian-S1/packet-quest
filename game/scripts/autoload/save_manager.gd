extends Node

@export var save_path: String = "user://save.json"

const WORLD_COUNT: int = 5

func defaults() -> Dictionary:
	var data: Dictionary = {
		"version": 1, "unlocked_worlds": [1], "completed_levels": [], "finished": false,
		"unlocked_boss_rush": false,
		"data_cores": 0, "collected_cores": [], "owned_upgrades": [],
		"equipped": {"weapons": ["packet"], "passive": ""},
		"settings": {"screen_shake": true, "reduce_flashes": false,
			"assist_mode": false, "music_volume": 0.8, "sfx_volume": 0.9, "bindings": {}},
		"stats": {"deaths": {}, "play_time_s": 0.0, "boss_rush": {"best_bosses": 0, "best_time_s": null}}
	}
	_migrate_levels(data)
	return data

func save_game(data: Dictionary, path: String = "") -> Error:
	var target: String = save_path if path.is_empty() else path
	var file: FileAccess = FileAccess.open(target + ".tmp", FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(JSON.stringify(data, "\t", true, true))
	file.close()
	return DirAccess.rename_absolute(target + ".tmp", target)

func load_game(path: String = "") -> Dictionary:
	var target: String = save_path if path.is_empty() else path
	if not FileAccess.file_exists(target):
		return defaults()
	var file: FileAccess = FileAccess.open(target, FileAccess.READ)
	if file == null:
		return defaults()
	var json: JSON = JSON.new()
	if json.parse(file.get_as_text()) != OK:
		return defaults()
	if not json.data is Dictionary:
		return defaults()
	var data: Dictionary = json.data as Dictionary
	var base: Dictionary = defaults()
	if not _is_count(data.get("version")) or data["version"] != 1:
		return base
	for key: String in ["unlocked_worlds", "completed_levels", "collected_cores", "owned_upgrades"]:
		if not data.get(key) is Array:
			return base
	for world: Variant in data["unlocked_worlds"]:
		if not _is_count(world) or float(world) < 1:
			return base
	# Partidas de cuando había 6 mundos: se descartan los que ya no existen sin borrar el resto.
	data["unlocked_worlds"] = data["unlocked_worlds"].filter(func(world: Variant) -> bool: return float(world) <= WORLD_COUNT)
	for key: String in ["completed_levels", "collected_cores", "owned_upgrades"]:
		for item: Variant in data[key]:
			if not item is String:
				return base
	if not data.get("equipped") is Dictionary or not data.get("settings") is Dictionary or not data.get("stats") is Dictionary:
		return base
	if not _is_count(data.get("data_cores")):
		return base
	var equipment: Dictionary = data["equipped"]
	var stats: Dictionary = data["stats"]
	if not equipment.get("weapons") is Array or not equipment.get("passive") is String or not stats.get("deaths") is Dictionary:
		return base
	for weapon: Variant in equipment["weapons"]:
		if not weapon is String:
			return base
	for count: Variant in stats["deaths"].values():
		if not _is_count(count):
			return base
	for key: String in ["screen_shake", "reduce_flashes", "assist_mode"]:
		if not data["settings"].get(key) is bool:
			return base
	for key: String in ["music_volume", "sfx_volume"]:
		if not _is_number(data["settings"].get(key)):
			return base
		if float(data["settings"][key]) < 0 or float(data["settings"][key]) > 1:
			return base
	if not _is_number(stats.get("play_time_s")):
		return base
	if float(stats["play_time_s"]) < 0:
		return base
	var finished: Variant = data.get("finished", false)
	data["finished"] = finished if finished is bool else false
	var rush_unlocked: Variant = data.get("unlocked_boss_rush", false)
	data["unlocked_boss_rush"] = rush_unlocked is bool and rush_unlocked == true
	var rush: Variant = stats.get("boss_rush")
	if rush is Dictionary:
		var bosses: Variant = rush.get("best_bosses")
		var count: int = int(bosses) if _is_count(bosses) and float(bosses) <= WORLD_COUNT else 0
		var best_time: Variant = _validated_time(rush.get("best_time_s")) if count == WORLD_COUNT else null
		stats["boss_rush"] = {"best_bosses": count, "best_time_s": best_time}
	else:
		stats["boss_rush"] = base["stats"]["boss_rush"]
	data["settings"]["bindings"] = InputBindings.validated(data["settings"].get("bindings", {}))
	_migrate_levels(data)
	return data

func _migrate_levels(data: Dictionary) -> void:
	var stats: Dictionary = data["stats"]
	var legacy_deaths: Dictionary = stats["deaths"]
	var completed: Array = data["completed_levels"]
	var levels: Variant = stats.get("levels")
	var normalized: Dictionary = {}
	for world: int in range(1, WORLD_COUNT + 1):
		var boss_completed: bool = StageStats.id(world, true) in completed
		for boss: bool in [false, true]:
			var id: String = StageStats.id(world, boss)
			var stored: Variant = levels.get(id) if levels is Dictionary else null
			var entry: Dictionary = stored if stored is Dictionary else {}
			var deaths: int = 0
			var causes: Array = StageStats.LEGACY_BOSS_DEATHS[world - 1] if boss else ["nivel_%d_1" % world]
			for cause: String in causes:
				deaths += int(legacy_deaths.get(cause, 0))
			var completions: int = 1 if boss_completed or id in completed else 0
			var row: Dictionary = {
				"best_time_s": _validated_time(entry.get("best_time_s")),
				"deaths": int(entry["deaths"]) if _is_count(entry.get("deaths")) else deaths,
				"completions": int(entry["completions"]) if _is_count(entry.get("completions")) else completions,
			}
			if not boss:
				row["cores_collected"] = StageStats.core_count(data, world)
				row["cores_available"] = StageStats.LEVEL_CORES[world - 1].size()
			normalized[id] = row
	stats["levels"] = normalized

func _validated_time(value: Variant) -> Variant:
	if _is_number(value) and float(value) > 0.0:
		return float(value)
	return null

func _is_number(value: Variant) -> bool:
	return (value is int or value is float) and is_finite(float(value))

func _is_count(value: Variant) -> bool:
	return _is_number(value) and float(value) >= 0 and float(value) == floorf(float(value))
