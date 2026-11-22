extends RefCounted

func run(tree: SceneTree) -> PackedStringArray:
	var errors: PackedStringArray = []
	var boss: RouterBoss = RouterBoss.new()
	tree.root.add_child(boss)
	boss.process_mode = Node.PROCESS_MODE_DISABLED
	boss.state = RouterBoss.State.IDLE
	boss.invulnerable = false
	boss.take_damage(29)
	if boss.phase != 0 or boss.health.current != 31: errors.append("fase prematura")
	var bullet: Projectile = boss.pool.fire(true, Vector2(100, 100), Vector2.RIGHT)
	boss.take_damage(1)
	if boss.phase != 1 or boss.state != RouterBoss.State.PHASE_TRANSITION or not boss.invulnerable: errors.append("umbral exacto 50 %")
	if bullet.active: errors.append("transición no limpia balas")
	if not boss.card.visible or "SOBRECARGA" not in boss.card.text: errors.append("tarjeta de fase")
	boss.take_damage(10)
	if boss.health.current != 30: errors.append("invulnerabilidad de transición")
	boss.advance(2.39)
	if not boss.invulnerable: errors.append("transición demasiado corta")
	boss.advance(0.02)
	if boss.invulnerable or boss.state != RouterBoss.State.IDLE: errors.append("fin de transición")
	# Crossing during ACTIVE must finish that attack, then transition.
	boss.phase = 0
	boss.health.current = 31
	boss.state = RouterBoss.State.ACTIVE
	boss.attack = &"A"
	boss.timer = 0.2
	boss.take_damage(1)
	if boss.phase != 0 or not boss.pending_transition: errors.append("no espera al ataque activo")
	boss.advance(0.21)
	if boss.phase != 1 or not boss.invulnerable: errors.append("no cambia tras ataque")
	boss.advance(2.41)
	boss.take_damage(30)
	if boss.state != RouterBoss.State.DEFEATED: errors.append("derrota")
	boss.queue_free()
	await tree.process_frame
	return errors
