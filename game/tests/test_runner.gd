extends SceneTree

const TESTS: Array[String] = ["components_objects", "state_edges", "save_edge", "player_edges", "performance", "health_component", "route_puzzle", "boss_phases", "save_manager", "scenes_load", "progression", "weapons", "world2", "world3", "world4", "world5", "options", "controls", "level_progress", "audio", "visual_polish", "hit_stop", "fuzz"]

# Cuenta los errores del motor y de GDScript mientras corre cada prueba: un error de script
# dentro de una subfunción solo aborta esa subfunción y la prueba seguía como PASS.
class ErrorCounter extends Logger:
	var count: int = 0
	var last: String = ""
	var _mutex: Mutex = Mutex.new()

	func _log_error(function: String, file: String, line: int, code: String, rationale: String, _editor_notify: bool, error_type: int, _script_backtraces: Array[ScriptBacktrace]) -> void:
		if error_type == ERROR_TYPE_WARNING:
			return
		_mutex.lock()
		count += 1
		last = "%s (%s:%d %s)" % [rationale if not rationale.is_empty() else code, file.get_file(), line, function]
		_mutex.unlock()

var error_counter: ErrorCounter = ErrorCounter.new()

func _initialize() -> void:
	OS.add_logger(error_counter)
	call_deferred("run_all")

func run_all() -> void:
	# Every test runs with isolated state and a disposable save path.
	var state: Node = root.get_node("GameState")
	var manager: Node = root.get_node("SaveManager")
	manager.set("save_path", "user://test_session.json")
	state.set("data", manager.call("defaults"))
	var failures: int = 0
	var selected: PackedStringArray = OS.get_cmdline_user_args()
	var tests: Array[String] = TESTS
	if not selected.is_empty():
		tests = []
		tests.assign(Array(selected))
	for test_name: String in tests:
		var path: String = "res://tests/test_%s.gd" % test_name
		if not ResourceLoader.exists(path):
			print("FAIL test_%s: implementación pendiente" % test_name)
			failures += 1
			continue
		var script: Script = load(path) as Script
		if script == null or not script.can_instantiate():
			print("FAIL test_%s: el script no compila" % test_name)
			failures += 1
			continue
		var test: RefCounted = script.new() as RefCounted
		state.set("data", manager.call("defaults"))
		state.set("puzzle_complete", false)
		state.set("checkpoint", Vector2(48, 296))
		state.set("current_world", 1)
		state.set("in_boss", false)
		var errors_before: int = error_counter.count
		var errors: PackedStringArray = await test.call("run", self)
		if error_counter.count > errors_before:
			errors.append("%d error(es) del motor o de script; último: %s" % [error_counter.count - errors_before, error_counter.last])
		# A runtime script error aborts run() silently; tests that declare
		# `finished` must reach the end to count as PASS.
		if "finished" in test and not bool(test.get("finished")):
			errors.append("abortada por un error de script")
		if errors.is_empty():
			print("PASS test_%s" % test_name)
		else:
			failures += 1
			print("FAIL test_%s: %s" % [test_name, "; ".join(errors)])
	print("RESULTADO: %d/%d PASS" % [tests.size() - failures, tests.size()])
	if FileAccess.file_exists("user://test_session.json"):
		DirAccess.remove_absolute("user://test_session.json")
	quit(0 if failures == 0 else 1)
