extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var wins := 0
	var trials := int(OS.get_environment("BENCH_TRIALS")) if OS.has_environment("BENCH_TRIALS") else 10
	for trial: int in range(trials):
		seed(trial + 1)
		var suite: RefCounted = load("res://tests/e2e_suite.gd").new()
		suite.set("tree", self)
		suite.set("pilot", load("res://tests/bot/pilot.gd").new(self))
		suite.call("_reset_state")
		change_scene_to_file("res://scenes/bosses/TrojanBoss.tscn")
		await scene_changed
		await process_frame
		var won: bool = await load("res://tests/bot/trojan_pilot.gd").fight(self, current_scene)
		print("Banco Troyano %d: %s" % [trial + 1, "PASS" if won else "FAIL"])
		if won:
			wins += 1
		suite.call("_finish")
	print("Banco Troyano: %d/%d" % [wins, trials])
	quit(0 if wins * 10 >= trials * 9 else 1)
