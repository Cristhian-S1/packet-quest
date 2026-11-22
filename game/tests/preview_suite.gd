extends RefCounted

var tree: SceneTree

func snap(file: String) -> void:
	await tree.process_frame
	await RenderingServer.frame_post_draw
	tree.root.get_texture().get_image().save_png("res://validation/" + file + ".png")

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
