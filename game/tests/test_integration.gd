extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var suite: RefCounted = load("res://tests/integration_suite.gd").new() as RefCounted
	var errors: PackedStringArray = await suite.call("run", self)
	quit(0 if errors.is_empty() else 1)