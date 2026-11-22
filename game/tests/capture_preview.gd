extends SceneTree

func _initialize() -> void:
	call_deferred("capture")

func capture() -> void:
	var suite: RefCounted = load("res://tests/preview_suite.gd").new() as RefCounted
	if "--m8" in OS.get_cmdline_user_args():
		await suite.call("capture_m8", self)
	else:
		await suite.call("capture", self)
