extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	await process_frame
	var suite: RefCounted = load("res://tests/e2e_suite.gd").new()
	suite.set("tree", self)
	suite.set("pilot", load("res://tests/bot/pilot.gd").new(self))
	suite.call("_reset_state")
	var state: Node = root.get_node("GameState")
	var data: Dictionary = state.get("data")
	data["unlocked_worlds"].assign([1, 2, 3, 4, 5])
	state.set("current_world", 5)
	change_scene_to_file("res://scenes/main/NetworkMap.tscn")
	await scene_changed
	await process_frame
	var won: bool = await suite.call("_world5")
	suite.call("_finish")
	print("Banco mundo 5: %s" % ("PASS" if won else "FAIL"))
	quit(0 if won else 1)
