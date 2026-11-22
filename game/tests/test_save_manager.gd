extends RefCounted

const PATH: String = "user://test_save.json"

func run(tree: SceneTree) -> PackedStringArray:
	var errors: PackedStringArray = []
	var manager: Node = tree.root.get_node("SaveManager")
	var data: Dictionary = manager.call("defaults")
	data["data_cores"] = 2
	data["collected_cores"] = ["w1_hidden_a", "w1_router"]
	data["completed_levels"] = ["w1_l1"]
	data["equipped"] = {"weapons": ["packet", "triple"], "passive": ""}
	data["stats"]["deaths"] = {"router_boss": 4}
	data["stats"]["play_time_s"] = 812
	var result: Error = manager.call("save_game", data, PATH)
	if result != OK: errors.append("escritura")
	var loaded: Dictionary = manager.call("load_game", PATH)
	# JSON has a single number type; compare decoded values, not int/float spelling.
	var expected: Dictionary = JSON.parse_string(JSON.stringify(data)) as Dictionary
	if loaded != expected: errors.append("roundtrip del esquema completo")
	for corrupt: String in ["{roto", "null", "[]", "{\"version\":99}", "{\"version\":1,\"data_cores\":\"incorrecto\"}"]:
		var file: FileAccess = FileAccess.open(PATH, FileAccess.WRITE)
		file.store_string(corrupt)
		file.close()
		loaded = manager.call("load_game", PATH)
		if loaded != manager.call("defaults"): errors.append("fallback corrupto: " + corrupt)
	DirAccess.remove_absolute(PATH)
	if manager.call("load_game", PATH) != manager.call("defaults"): errors.append("archivo ausente")
	var malformed: Dictionary = data.duplicate(true)
	malformed["stats"]["deaths"] = {"nivel_1_1": {"bad": 1}}
	manager.call("save_game", malformed, PATH)
	if manager.call("load_game", PATH) != manager.call("defaults"): errors.append("contador de muertes corrupto aceptado")
	malformed = data.duplicate(true)
	malformed["data_cores"] = 1.5
	manager.call("save_game", malformed, PATH)
	if manager.call("load_game", PATH) != manager.call("defaults"): errors.append("núcleos fraccionarios aceptados")
	malformed = data.duplicate(true)
	malformed["version"] = {"invalid": 1}
	manager.call("save_game", malformed, PATH)
	if manager.call("load_game", PATH) != manager.call("defaults"): errors.append("versión objeto aceptada")
	DirAccess.remove_absolute(PATH)
	return errors
