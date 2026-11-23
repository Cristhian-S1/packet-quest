extends RefCounted

var errors: PackedStringArray = []
var finished: bool = false

func run(tree: SceneTree) -> PackedStringArray:
	_test_cable(tree)
	_test_password(tree)
	finished = true
	return errors

func _test_cable(tree: SceneTree) -> void:
	GameState.current_world = 2
	GameState.puzzle_complete = false
	var level: World2Level1 = (load(GameState.current_level) as PackedScene).instantiate() as World2Level1
	tree.root.add_child(level)
	var puzzle: CablePuzzle = level.puzzle
	var hint: Control = _hint_for(puzzle)
	if hint == null:
		level.free()
		return
	level.player.position.x = puzzle.position.x - 1.0
	puzzle.call("_process", 75.0)
	_check(not hint.visible, "la pista de cable no empieza fuera de la sala")
	level.player.position.x = puzzle.position.x + 60.0
	puzzle.call("_process", 59.75)
	_check(not hint.visible, "la pista sigue oculta antes de 60 s dentro de la sala")
	puzzle.call("_process", 0.5)
	var first_alpha: float = hint.modulate.a
	_check(hint.visible and _contains(hint, puzzle.cells[4].position), "la primera pista señala la pieza de la antena")
	puzzle.call("_process", 0.25)
	_check(hint.visible and first_alpha > 0.0 and first_alpha < hint.modulate.a, "un solo pulso sube suavemente")
	puzzle.call("_process", 1.0)
	_check(not hint.visible, "el pulso desaparece antes del siguiente intervalo")
	puzzle.cells[4].receive_projectile(1.0, Vector2.ZERO, Vector2.UP)
	puzzle.call("_process", 8.75)
	_check(hint.visible and _contains(hint, puzzle.cells[5].position), "a los 70 s la pista señala la siguiente pieza")

	GameState.settings["reduce_flashes"] = true
	puzzle.call("_process", 4.0)
	_check(hint.visible and is_equal_approx(hint.modulate.a, 1.0), "Reducir destellos deja un contorno fijo entre intervalos")
	level.player.position.x = puzzle.position.x - 1.0
	puzzle.call("_process", 1.0)
	_check(not hint.visible, "al salir de la sala se oculta el contorno")
	level.player.position.x = puzzle.position.x + 60.0
	puzzle.call("_process", 0.0)
	_check(hint.visible, "el tiempo de pista se conserva al volver a la sala")
	puzzle.reset_puzzle()
	puzzle.call("_process", 59.0)
	_check(not hint.visible, "reiniciar el cable reinicia la espera")
	GameState.settings["reduce_flashes"] = false
	level.free()

func _test_password(tree: SceneTree) -> void:
	GameState.current_world = 4
	GameState.puzzle_complete = false
	var level: World4Level1 = (load(GameState.current_level) as PackedScene).instantiate() as World4Level1
	tree.root.add_child(level)
	var puzzle: PasswordPuzzle = level.puzzle
	var hint: Control = _hint_for(puzzle)
	if hint == null:
		level.free()
		return
	for poster: Vector2 in PasswordPuzzle.POSTERS:
		level.player.position.x = puzzle.position.x + poster.x + 67.0
		puzzle.call("_process", 0.0)
	_check(puzzle.is_processing(), "revelar todos los pósteres mantiene activo el reloj de pista")
	puzzle.call("_process", 60.5)
	_check(hint.visible and _contains(hint, puzzle.slots[0].position + Vector2(0, -16)),
		"la pista de contraseña señala la primera ranura incorrecta")
	for slot: PasswordSlot in puzzle.slots:
		for turn: int in range(3):
			slot.interact()
		if slot == puzzle.slots[0]:
			_check(hint.visible and _contains(hint, puzzle.slots[1].position + Vector2(0, -16)),
				"el contorno pasa a la siguiente ranura incorrecta")
	_check(puzzle.is_solved and not hint.visible, "resolver la contraseña apaga la pista")
	level.free()

func _hint_for(puzzle: Node) -> Control:
	var hint: Control = puzzle.get_node_or_null("PuzzleHint") as Control
	_check(hint != null, "%s tiene el componente de pista" % puzzle.name)
	return hint

func _contains(hint: Control, point: Vector2) -> bool:
	return Rect2(hint.position, hint.size).has_point(point)

func _check(condition: bool, message: String) -> void:
	if not condition:
		errors.append(message)
