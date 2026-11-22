extends SceneTree

func _initialize() -> void:
	call_deferred("capture")

func capture() -> void:
	var suite: RefCounted = load("res://tests/preview_suite.gd").new() as RefCounted
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if "--m11" in args:
		await suite.call("capture_m11", self)
	elif "--m10" in args:
		await suite.call("capture_m10", self)
	elif "--m9" in args:
		await suite.call("capture_m9", self)
	elif "--m8" in args:
		await suite.call("capture_m8", self)
	else:
		await suite.call("capture", self)
