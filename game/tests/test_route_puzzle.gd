extends RefCounted

func run(tree: SceneTree) -> PackedStringArray:
	var errors: PackedStringArray = []
	var state: Node = tree.root.get_node("GameState")
	state.set("puzzle_complete", false)
	var puzzle: RoutePuzzle = RoutePuzzle.new()
	var count: Array[int] = [0]
	puzzle.solved.connect(func() -> void: count[0] += 1)
	tree.root.add_child(puzzle)
	if puzzle.check_solution() or count[0] != 0 or puzzle.door.opened: errors.append("ruta inicial incorrecta no abre")
	for index: int in range(3):
		puzzle.nodes[index].direction = puzzle.solution[index]
	if not puzzle.check_solution() or count[0] != 1 or not puzzle.door.opened: errors.append("ruta correcta abre y emite")
	puzzle.check_solution()
	if count[0] != 1: errors.append("solved duplicado")
	puzzle.reset_puzzle()
	if puzzle.is_solved or puzzle.door.opened or puzzle.check_solution(): errors.append("reinicio cierra puerta")
	for index: int in range(3):
		while puzzle.nodes[index].direction != puzzle.solution[index]:
			puzzle.nodes[index].interact()
	if not puzzle.is_solved or count[0] != 2: errors.append("interacción y señales conectadas")
	puzzle.reset_puzzle()
	puzzle.queue_free()
	await tree.process_frame
	return errors
