extends RefCounted

var finished: bool = false
var errors: PackedStringArray = []
const PATH: String = "user://unit_edge_cases.json"

func check(ok: bool, message: String) -> void:
	if not ok:
		errors.append(message)

func run(tree: SceneTree) -> PackedStringArray:
	var manager: Node = tree.root.get_node("SaveManager")
	for content: String in ["", " ", "{", "null", "[]", "{}", "{\"version\":0}", "{\"version\":1}"]:
		var file: FileAccess = FileAccess.open(PATH, FileAccess.WRITE)
		file.store_string(content)
		file.close()
		check(manager.call("load_game", PATH) == manager.call("defaults"), "guardado inválido: %s" % content)
	for key: String in ["version", "unlocked_worlds", "completed_levels", "data_cores", "collected_cores", "owned_upgrades", "equipped", "settings", "stats"]:
		var data: Dictionary = manager.call("defaults")
		data.erase(key)
		manager.call("save_game", data, PATH)
		check(manager.call("load_game", PATH) == manager.call("defaults"), "clave ausente: " + key)
	for section: String in ["equipped", "settings", "stats"]:
		var data: Dictionary = manager.call("defaults")
		for key: String in data[section].keys():
			if section == "settings" and key == "bindings":
				continue # Es opcional en partidas antiguas; test_controls comprueba la migración.
			var incomplete: Dictionary = data.duplicate(true)
			incomplete[section].erase(key)
			manager.call("save_game", incomplete, PATH)
			check(manager.call("load_game", PATH) == manager.call("defaults"), "clave ausente: %s.%s" % [section, key])
	DirAccess.remove_absolute(PATH)
	finished = true
	return errors
