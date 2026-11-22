extends RefCounted

var tree: SceneTree

func snap(file: String, directory: String = "res://validation") -> Error:
	await tree.process_frame
	await RenderingServer.frame_post_draw
	return tree.root.get_texture().get_image().save_png(directory.path_join(file + ".png"))

func capture(scene_tree: SceneTree) -> void:
	tree = scene_tree
	var state: Node = tree.root.get_node("GameState")
	var manager: Node = tree.root.get_node("SaveManager")
	manager.set("save_path", "user://preview_session.json")
	state.set("data", manager.call("defaults"))
	var menu: Node = load("res://scenes/main/Main.tscn").instantiate()
	tree.root.add_child(menu)
	await snap("01-menu")
	menu.queue_free()
	await tree.process_frame
	state.set("checkpoint", Vector2(48, 296))
	var world: World1Level1 = load("res://scenes/levels/World1Level1.tscn").instantiate() as World1Level1
	tree.root.add_child(world)
	await snap("02-level")
	world.player.global_position = Vector2(2430, 296)
	await snap("03-puzzle")
	world.queue_free()
	await tree.process_frame
	var boss: RouterBoss = load("res://scenes/bosses/RouterBoss.tscn").instantiate() as RouterBoss
	tree.root.add_child(boss)
	boss.state = RouterBoss.State.TELEGRAPH
	boss.attack = &"B"
	boss.card.visible = false
	boss.timer = 0.8
	await snap("04-boss")
	boss.queue_free()
	await tree.process_frame
	tree.quit()

func capture_m8(scene_tree: SceneTree) -> void:
	tree = scene_tree
	var state: Node = tree.root.get_node("GameState")
	var manager: Node = tree.root.get_node("SaveManager")
	manager.set("save_path", "res://validation/preview_m8_session.json")
	state.set("data", manager.call("defaults"))
	state.set("checkpoint", Vector2(899, 241))
	var directory: String = ProjectSettings.globalize_path("res://../docs/capturas").simplify_path()
	var world: World2Level1 = preload("res://scenes/levels/World2Level1.tscn").instantiate() as World2Level1
	tree.root.add_child(world)
	var level_result: Error = await snap("level2", directory)
	world.queue_free()
	await tree.process_frame

	var queen: WifiQueenBoss = preload("res://scenes/bosses/WifiQueenBoss.tscn").instantiate() as WifiQueenBoss
	tree.root.add_child(queen)
	queen.set_physics_process(false)
	queen.player.set_physics_process(false)
	queen._physics_process(1.2)
	queen.take_damage(27.0, Vector2.ZERO)
	queen._physics_process(2.4)
	queen.take_damage(27.0, Vector2.ZERO)
	queen._physics_process(2.4)
	queen.player.position = Vector2(96, 296)
	queen.player.interact()
	queen._physics_process(0.55)
	var boss_result: Error = await snap("boss2", directory)
	if level_result != OK or boss_result != OK:
		push_error("Error al guardar las capturas M8 (%d, %d)" % [level_result, boss_result])
		tree.quit(1)
	else:
		print("CAPTURAS M8: level2.png y boss2.png")
		tree.quit()

func capture_m9(scene_tree: SceneTree) -> void:
	tree = scene_tree
	var state: Node = tree.root.get_node("GameState")
	var manager: Node = tree.root.get_node("SaveManager")
	manager.set("save_path", "res://validation/preview_m9_session.json")
	state.set("data", manager.call("defaults"))
	state.set("checkpoint", Vector2(819, 296))
	var directory: String = ProjectSettings.globalize_path("res://../docs/capturas").simplify_path()
	var stage: World3Level1 = preload("res://scenes/levels/World3Level1.tscn").instantiate() as World3Level1
	tree.root.add_child(stage)
	await tree.create_timer(1.72).timeout
	var level_result: Error = await snap("level3", directory)
	stage.queue_free()
	await tree.process_frame

	var boss: FirewallBoss = preload("res://scenes/bosses/FirewallBoss.tscn").instantiate() as FirewallBoss
	tree.root.add_child(boss)
	boss.set_physics_process(false)
	boss.player.set_physics_process(false)
	boss._physics_process(1.2)
	boss._physics_process(1.61)
	boss.core.take_damage(36.0, Vector2.ZERO)
	boss._physics_process(2.4)
	boss.player.position = Vector2(132, 249)
	boss._physics_process(0.1)
	boss._physics_process(0.8)
	boss.player.position = Vector2(167, 296)
	boss._physics_process(0.32)
	var boss_result: Error = await snap("boss3", directory)
	if level_result != OK or boss_result != OK:
		push_error("Error al guardar las capturas M9 (%d, %d)" % [level_result, boss_result])
		tree.quit(1)
	else:
		print("CAPTURAS M9: level3.png y boss3.png")
		tree.quit()
