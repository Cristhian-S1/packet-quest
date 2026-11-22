extends SceneTree

func _initialize() -> void:
	call_deferred("capture")

func capture() -> void:
	var suite: RefCounted = load("res://tests/preview_suite.gd").new() as RefCounted
	await suite.call("capture", self)