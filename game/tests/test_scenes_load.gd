extends RefCounted

func run(tree: SceneTree) -> PackedStringArray:
	var errors: PackedStringArray = []
	var paths: PackedStringArray = []
	_find_scenes("res://scenes", paths)
	if paths.size() < 24: errors.append("faltan escenas requeridas (%d)" % paths.size())
	for path: String in paths:
		var packed: PackedScene = load(path) as PackedScene
		if packed == null:
			errors.append("no carga " + path)
			continue
		var instance: Node = packed.instantiate()
		if instance == null:
			errors.append("no instancia " + path)
			continue
		tree.root.add_child(instance)
		await tree.process_frame
		await tree.physics_frame
		instance.queue_free()
		await tree.process_frame
		tree.paused = false
	return errors

func _find_scenes(path: String, paths: PackedStringArray) -> void:
	for file: String in DirAccess.get_files_at(path):
		if file.ends_with(".tscn"):
			paths.append(path.path_join(file))
	for directory: String in DirAccess.get_directories_at(path):
		_find_scenes(path.path_join(directory), paths)
