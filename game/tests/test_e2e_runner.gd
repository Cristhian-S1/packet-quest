extends SceneTree

class ErrorCounter extends Logger:
	var count: int = 0
	var last: String = ""
	var mutex: Mutex = Mutex.new()

	func _log_error(function: String, file: String, line: int, code: String, rationale: String, _notify: bool, type: int, _backtraces: Array[ScriptBacktrace]) -> void:
		if type == ERROR_TYPE_WARNING:
			return
		mutex.lock()
		count += 1
		last = "%s (%s:%d %s)" % [rationale if not rationale.is_empty() else code, file, line, function]
		mutex.unlock()

var error_counter: ErrorCounter = ErrorCounter.new()

func _initialize() -> void:
	# Semilla fija: enemy_base.gd suelta fragmentos con randf(); así el recorrido es reproducible.
	seed(20261123)
	OS.add_logger(error_counter)
	call_deferred("run")

func run() -> void:
	var script: Script = load("res://tests/e2e_suite.gd") as Script
	if script == null or not script.can_instantiate():
		print("FAIL e2e: el script no compila")
		quit(1)
		return
	var suite: RefCounted = script.new() as RefCounted
	var errors: PackedStringArray = await suite.call("run", self)
	if error_counter.count > 0:
		errors.append("%d error(es) del motor o script: %s" % [error_counter.count, error_counter.last])
	if not bool(suite.get("finished")):
		errors.append("prueba abortada antes de terminar")
	if errors.is_empty():
		print("PASS e2e")
	else:
		print("FAIL e2e: %s" % "; ".join(errors))
	quit(0 if errors.is_empty() else 1)
