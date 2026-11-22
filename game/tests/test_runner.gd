extends SceneTree

const TESTS: Array[String] = ["health_component", "route_puzzle", "boss_phases", "save_manager", "scenes_load"]

func _initialize() -> void:
	call_deferred("run_all")

func run_all() -> void:
	# Every test runs with isolated state and a disposable save path.
	var state: Node = root.get_node("GameState")
	var manager: Node = root.get_node("SaveManager")
	manager.set("save_path", "user://test_session.json")
	state.set("data", manager.call("defaults"))
	var failures: int = 0
	for test_name: String in TESTS:
		var path: String = "res://tests/test_%s.gd" % test_name
		if not ResourceLoader.exists(path):
			print("FAIL test_%s: implementación pendiente" % test_name)
			failures += 1
			continue
		var script: Script = load(path) as Script
		var test: RefCounted = script.new() as RefCounted
		state.set("data", manager.call("defaults"))
		state.set("puzzle_complete", false)
		state.set("checkpoint", Vector2(48, 296))
		var errors: PackedStringArray = await test.call("run", self)
		if errors.is_empty():
			print("PASS test_%s" % test_name)
		else:
			failures += 1
			print("FAIL test_%s: %s" % [test_name, "; ".join(errors)])
	print("RESULTADO: %d/%d PASS" % [TESTS.size() - failures, TESTS.size()])
	if FileAccess.file_exists("user://test_session.json"):
		DirAccess.remove_absolute("user://test_session.json")
	quit(0 if failures == 0 else 1)
