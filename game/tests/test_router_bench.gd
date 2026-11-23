extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var wins := 0
	for trial: int in range(10):
		seed(trial + 1)
		var suite: RefCounted = load("res://tests/e2e_suite.gd").new()
		suite.set("tree", self)
		suite.set("pilot", load("res://tests/bot/pilot.gd").new(self))
		suite.call("_reset_state")
		change_scene_to_file("res://scenes/bosses/RouterBoss.tscn")
		await scene_changed
		await process_frame
		var won: bool = await suite.call("_fight_router")
		print("Banco Router %d: %s" % [trial + 1, "PASS" if won else "FAIL"])
		if won:
			wins += 1
		suite.call("_finish")
	print("Banco Router: %d/10" % wins)
	quit(0 if wins >= 9 else 1)
