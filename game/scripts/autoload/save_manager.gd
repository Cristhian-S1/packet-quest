extends Node

@export var save_path: String = "user://save.json"

func defaults() -> Dictionary:
	return {
		"version": 1, "unlocked_worlds": [1], "completed_levels": [],
		"data_cores": 0, "collected_cores": [], "owned_upgrades": [],
		"equipped": {"weapons": ["packet"], "passive": ""},
		"settings": {"screen_shake": true, "reduce_flashes": false,
			"assist_mode": false, "music_volume": 0.8, "sfx_volume": 0.9},
		"stats": {"deaths": {}, "play_time_s": 0.0}
	}

func save_game(data: Dictionary, path: String = "") -> Error:
	var target: String = save_path if path.is_empty() else path
	var file: FileAccess = FileAccess.open(target + ".tmp", FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(JSON.stringify(data, "\t"))
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
		if not _is_count(world) or float(world) < 1 or float(world) > 6:
			return base
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
	return data

func _is_number(value: Variant) -> bool:
	return (value is int or value is float) and is_finite(float(value))

func _is_count(value: Variant) -> bool:
	return _is_number(value) and float(value) >= 0 and float(value) == floorf(float(value))
