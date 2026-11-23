extends RefCounted

var finished: bool = false
var errors: PackedStringArray = []

func check(value: bool, message: String) -> void:
	if not value:
		errors.append(message)

func run(tree: SceneTree) -> PackedStringArray:
	var hurt: Hurtbox = Hurtbox.new()
	var hits: Array = []
	hurt.hit.connect(func(amount: float, origin: Vector2) -> void: hits.append([amount, origin]))
	tree.root.add_child(hurt)
	hurt.take_damage(2.0, Vector2(3, 4))
	check(hits == [[2.0, Vector2(3, 4)]], "Hurtbox transmite daño y origen")
	hurt.invulnerable = true
	hurt.take_damage(1.0, Vector2.ZERO)
	check(hits.size() == 1, "Hurtbox invulnerable no emite")
	hurt.marked = true
	check(hurt.marked, "Hurtbox conserva la marca")
	hurt.free()

	var grid: CableGrid = CableGrid.new()
	# Comprueba cada orientación de cada celda contra una tabla independiente.
	var rotations: Array[int] = CableGrid.INITIAL.duplicate()
	var masks: Array[Array] = [[0, 0, 0, 0], [5, 10, 5, 10], [3, 6, 12, 9], [7, 14, 13, 11]]
	for index: int in range(12):
		var cell: Vector2i = Vector2i(index % 4, index / 4)
		for turn: int in range(4):
			check(grid.openings(cell) == masks[CableGrid.TILES[index]][(rotations[index] + turn) % 4], "cable celda %d giro %d" % [index, turn])
			grid.rotate_cell(cell)
	check(not grid.is_solved(), "rejilla inicial sin resolver")
	grid.restore_solution()
	check(grid.is_solved(), "solución conecta antena y router")
	grid.reset()
	check(not grid.is_solved(), "reinicio restaura rejilla")

	for sample: Array in [[0.0, &"active"], [1.999, &"active"], [2.0, &"inactive"], [2.499, &"inactive"], [2.5, &"warning"], [3.0, &"active"], [-0.1, &"warning"]]:
		check(WaveZone.state_at(sample[0]) == sample[1], "fase de onda %s" % sample[0])
	check(CoveragePlatform.is_covered(Vector2(3, 4), Vector2.ZERO, 5), "cobertura incluye borde")
	check(not CoveragePlatform.is_covered(Vector2(3, 4.1), Vector2.ZERO, 5), "cobertura excluye exterior")
	for sample: Array in [[0.0, 100.0], [0.5, 50.0], [1.0, 0.0], [1.5, 50.0], [2.0, 100.0]]:
		check(is_equal_approx(ChipPlatform.oscillating_top(100, 100, 2, sample[0]), sample[1]), "plataforma móvil t=%s" % sample[0])

	var player: PacketPlayer = PacketPlayer.new()
	tree.root.add_child(player)
	player.set_physics_process(false)
	var checkpoint: PacketCheckpoint = PacketCheckpoint.new()
	checkpoint.position = Vector2(200, 100)
	tree.root.add_child(checkpoint)
	var reached: Array[int] = [0]
	checkpoint.reached.connect(func() -> void: reached[0] += 1)
	player.health.damage(2)
	checkpoint._entered(player)
	checkpoint._entered(player)
	check(checkpoint.active and reached[0] == 1, "checkpoint se activa una vez")
	check(GameState.checkpoint == checkpoint.global_position, "checkpoint guarda posición")
	check(player.health.current == player.health.max_health, "checkpoint cura")
	var core: DataCore = DataCore.new()
	core.core_id = &"test_unit_core"
	tree.root.add_child(core)
	var collected: Array[int] = [0]
	core.collected.connect(func() -> void: collected[0] += 1)
	core._entered(player)
	core._entered(player)
	check(collected[0] == 1, "núcleo se recoge una vez")
	check(GameState.data["collected_cores"].count("test_unit_core") == 1, "identificador de núcleo guardado")
	check(SaveManager.load_game()["collected_cores"].has("test_unit_core"), "identificador persiste en archivo")
	var door: PacketDoor = PacketDoor.new()
	tree.root.add_child(door)
	var node: NetworkNode = NetworkNode.new()
	node.corruption_hits = 2
	tree.root.add_child(node)
	node.targets = [node.get_path_to(door)]
	var activations: Array[int] = [0]
	node.activated.connect(func() -> void: activations[0] += 1)
	node.interact()
	check(not door.opened and activations[0] == 0, "nodo corrupto bloquea interacción")
	node.take_damage(1, Vector2.ZERO)
	check(node.corruption_hits == 1, "nodo requiere dos impactos")
	node.take_damage(1, Vector2.ZERO)
	check(node.corruption_hits == 0 and node.collision_layer == 32, "nodo queda limpio")
	node.interact()
	check(door.opened and activations[0] == 1, "nodo activa puerta")
	await tree.process_frame
	check(door.shape.disabled, "puerta abierta desactiva colisión")
	door.set_open(false)
	await tree.process_frame
	check(not door.shape.disabled, "puerta cerrada restaura colisión")
	node.free()
	door.free()
	checkpoint.free()
	player.free()
	await _popup_appearance(tree)
	finished = true
	return errors

func _popup_appearance(tree: SceneTree) -> void:
	var popup: PopUp = PopUp.new()
	popup.position = Vector2(900, 180)
	tree.root.add_child(popup)
	popup.set_physics_process(false)
	popup._physics_process(1.0 / 60.0)
	check(not popup.visible, "Pop-up fuera de cámara no aparece")
	popup.position.x = 320
	popup._physics_process(1.0 / 60.0)
	check(popup.visible and popup.self_modulate.a < 1.0, "Pop-up inicia con una aparición visible y gradual")
	var hitbox: CollisionShape2D = popup.get_child(0) as CollisionShape2D
	var rectangle: RectangleShape2D = hitbox.shape as RectangleShape2D
	check(popup.scale == Vector2.ONE and rectangle.size == Vector2(20, 16) and popup.collision_layer == 4, "aparición conserva el colisionador")
	popup.take_damage(1.0, Vector2.ZERO)
	check(popup.health.current == 2.0, "Pop-up recibe daño durante la aparición")
	for index: int in range(15):
		await tree.process_frame
	check(is_equal_approx(popup.self_modulate.a, 1.0), "la aparición del Pop-up dura como máximo 0,25 s")
	popup.position.x = 900
	popup._physics_process(1.0 / 60.0)
	popup.position.x = 320
	popup._physics_process(1.0 / 60.0)
	check(is_equal_approx(popup.self_modulate.a, 1.0), "el mismo Pop-up no reaparece al volver a cámara")
	popup.queue_free()
	await tree.process_frame
