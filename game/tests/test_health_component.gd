extends RefCounted

func run(tree: SceneTree) -> PackedStringArray:
	var errors: PackedStringArray = []
	var health: HealthComponent = HealthComponent.new()
	var depleted_count: Array[int] = [0]
	var changed_count: Array[int] = [0]
	health.depleted.connect(func() -> void: depleted_count[0] += 1)
	health.changed.connect(func(_cur: float, _max: float) -> void: changed_count[0] += 1)
	tree.root.add_child(health)
	if health.current != 3: errors.append("vida inicial")
	health.damage(1)
	if health.current != 2: errors.append("daño")
	health.heal(10)
	if health.current != 3: errors.append("límite de curación")
	health.damage(-4)
	health.heal(-2)
	if health.current != 3: errors.append("rechazo de cantidades negativas")
	health.damage(100)
	health.damage(1)
	if health.current != 0 or depleted_count[0] != 1: errors.append("límite inferior y depleted una sola vez")
	if changed_count[0] != 4: errors.append("señal changed")
	health.reset()
	health.damage(3)
	if depleted_count[0] != 2: errors.append("nuevo ciclo de vida")
	health.free()
	return errors
