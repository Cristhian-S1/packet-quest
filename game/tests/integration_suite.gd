extends RefCounted

var tree: SceneTree
var errors: PackedStringArray = []
var state: Node
var manager: Node

func check(condition: bool, message: String) -> void:
	if not condition:
		errors.append(message)

func frames(count: int) -> void:
	for index: int in range(count):
		await tree.physics_frame
		await tree.process_frame

func run(scene_tree: SceneTree) -> PackedStringArray:
	tree = scene_tree
	state = tree.root.get_node("GameState")
	manager = tree.root.get_node("SaveManager")
	manager.set("save_path", "user://test_integration.json")
	state.set("data", manager.call("defaults"))
	state.set("checkpoint", Vector2(48, 296))
	for binding: Array in [["move_left", KEY_LEFT], ["move_right", KEY_RIGHT], ["aim_up", KEY_UP], ["aim_down", KEY_DOWN], ["dash", KEY_SHIFT]]:
		var found: bool = false
		for event: InputEvent in InputMap.action_get_events(binding[0]):
			if event is InputEventKey and (event as InputEventKey).physical_keycode == binding[1]:
				found = true
		check(found, "InputMap físico: " + str(binding[0]))
	# Real physics, same scene as Jugar. Disable enemies to isolate movement.
	var world: World1Level1 = preload("res://scenes/levels/World1Level1.tscn").instantiate() as World1Level1
	tree.root.add_child(world)
	for enemy: Node in tree.get_nodes_in_group("enemies"):
		enemy.queue_free()
	var byte: PacketPlayer = world.player
	await frames(20)
	check(byte.is_on_floor() and absf(byte.position.y - 297) < 1, "Byte no aterriza en suelo y=304")
	# A real grounded shot must hit the tutorial enemy (not call damage directly).
	var target: PopUp = PopUp.new()
	target.position = Vector2(192, 296)
	world.add_child(target)
	target.set_physics_process(false)
	Input.action_press("shoot")
	await frames(45)
	Input.action_release("shoot")
	check(target.health.current == 0, "disparo horizontal no alcanza Pop-up desde suelo")
	target.queue_free()
	for bullet: Projectile in byte.pool.player_bullets: bullet.deactivate()
	byte.weapon_slots[0] = byte.weapon_slots[0].duplicate() as WeaponData
	byte.weapon_slots[0].bullet_speed = 0
	byte.shoot_wait = 0
	Input.action_press("shoot")
	await frames(120)
	Input.action_release("shoot")
	check(_count_active(byte.pool.player_bullets) == 16, "cadencia no mantiene 8/s durante 2 s")
	byte.weapon_slots[0].bullet_speed = 480
	for bullet: Projectile in byte.pool.player_bullets: bullet.deactivate()
	var start: Vector2 = byte.global_position
	Input.action_press("dash")
	await frames(1)
	Input.action_release("dash")
	await frames(10)
	check(absf(byte.global_position.x - start.x - 72) < 0.2, "dash no recorre 72 px: %.3f" % (byte.global_position.x - start.x))
	await frames(40)
	Input.action_press("jump")
	await frames(2)
	var jumping_speed: float = byte.velocity.y
	Input.action_release("jump")
	await frames(1)
	check(byte.velocity.y > jumping_speed * 0.6, "salto variable no corta ascenso")
	await frames(50)
	# Leave the edge, then jump during the 0.10 s coyote window.
	byte.position = Vector2(748, 297)
	byte.velocity = Vector2(150, 0)
	Input.action_press("move_right")
	await frames(5)
	check(not byte.is_on_floor(), "fixture de coyote no abandona borde")
	Input.action_press("jump")
	await frames(1)
	check(byte.velocity.y < -300, "coyote no permite saltar fuera del borde")
	Input.action_release("jump")
	Input.action_release("move_right")
	# Press before landing: the buffered jump must fire without a second press.
	byte.position = Vector2(64, 281)
	byte.velocity = Vector2(0, 240)
	byte.coyote = 0
	await frames(1)
	Input.action_press("jump")
	await frames(5)
	check(byte.velocity.y < -250, "jump buffer no salta al aterrizar")
	Input.action_release("jump")
	await frames(40)
	# Raised landing: ordinary jump fails, jump + dash clears the 96px pit.
	for use_dash: bool in [false, true]:
		byte.position = Vector2(740, 297)
		byte.safe_position = byte.position
		byte.velocity = Vector2.ZERO
		byte.health.reset()
		byte.cooldown = 0
		await frames(2)
		byte.velocity.x = 150
		Input.action_press("move_right")
		Input.action_press("jump")
		await frames(18)
		if use_dash: Input.action_press("dash")
		await frames(1)
		Input.action_release("dash")
		await frames(18)
		Input.action_release("jump")
		Input.action_release("move_right")
		check((byte.position.x > 848 and byte.position.y < 260) if use_dash else byte.position.x < 848, "hueco S2 con dash=" + str(use_dash))
	byte.position = Vector2(64, 296)
	byte.velocity = Vector2.ZERO
	await frames(5)
	Input.action_press("lock_aim")
	Input.action_press("move_left")
	Input.action_press("aim_down")
	await frames(2)
	check(byte.aim.is_equal_approx(Vector2(-1, 1).normalized()), "apuntado diagonal abajo con lock_aim")
	check(absf(byte.velocity.x) < 0.01, "lock_aim permite desplazamiento")
	Input.action_release("lock_aim")
	Input.action_release("move_left")
	Input.action_release("aim_down")
	byte.facing = 1
	byte.shield_active = true
	byte.shield_meter = 100
	byte.receive_projectile(1, byte.global_position + Vector2(12, 0), Vector2(-120, 0))
	check(byte.health.current == 3 and byte.shield_meter == 85, "escudo no bloquea frontal por 15")
	byte.receive_projectile(1, byte.global_position - Vector2(12, 0), Vector2(120, 0))
	check(byte.health.current == 2, "escudo bloquea por detrás")
	byte.receive_projectile(1, byte.global_position - Vector2(12, 0), Vector2(120, 0))
	check(byte.health.current == 2, "i-frames de daño")
	byte.shield_active = true
	byte.shield_meter = 10
	byte.receive_projectile(1, byte.global_position + Vector2(12, 0), Vector2(-120, 0))
	check(byte.shield_broken == 2 and not byte.shield_active, "rotura de escudo")
	byte.health.heal(3)
	byte.safe_position = Vector2(64, 296)
	byte.global_position = Vector2(800, 400)
	byte.pit_respawn()
	check(byte.health.current == 2 and byte.global_position == Vector2(64, 296), "vacío no restaura posición y resta PV")
	var pool: ProjectilePool = byte.pool
	for index: int in range(pool.player_capacity):
		check(pool.fire(false, Vector2(60, 100), Vector2.RIGHT) != null, "pool jugador no ofrece %d" % pool.player_capacity)
	check(pool.fire(false, Vector2.ZERO, Vector2.RIGHT) == null, "pool excede %d" % pool.player_capacity)
	pool.player_bullets[0].deactivate()
	check(pool.fire(false, Vector2.ZERO, Vector2.RIGHT) != null, "pool no recicla")
	# A moving AnimatableBody2D must carry its passenger.
	byte.invulnerability = 0
	byte.hurt_left = 0
	var moving_chip: ChipPlatform = null
	for child: Node in world.get_children():
		if child is ChipPlatform and (child as ChipPlatform).vertical_travel > 0:
			moving_chip = child as ChipPlatform
	var guide: Line2D = moving_chip.get_node_or_null("CableGuide") as Line2D
	check(guide != null and guide.points.size() == 2, "el cable móvil necesita una guía con dos extremos")
	var guide_origin: Vector2 = Vector2.ZERO
	if guide != null and guide.points.size() == 2:
		guide_origin = guide.to_global(guide.points[0])
		check(guide.to_global(guide.points[1]) - guide_origin == Vector2(0, -64), "la guía del cable debe medir 64 px")
	byte.global_position = moving_chip.global_position + Vector2(32, -24)
	byte.velocity = Vector2.ZERO
	await frames(90)
	check(byte.is_on_floor() and absf(byte.position.y + 7 - moving_chip.position.y) < 1, "plataforma móvil no transporta pasajero: Byte=%.2f, plataforma=%.2f" % [byte.position.y, moving_chip.position.y])
	if guide != null and guide.points.size() == 2:
		check(guide.to_global(guide.points[0]) == guide_origin, "la guía debe seguir anclada mientras se mueve la plataforma")
	# Solve with actual player interaction; no direct setting of directions.
	world.puzzle.reset_puzzle()
	for node: PuzzleNode in world.puzzle.nodes:
		byte.global_position = node.global_position + Vector2(0, 16)
		var index: int = world.puzzle.nodes.find(node)
		while node.direction != world.puzzle.solution[index]:
			byte.interact()
	check(world.puzzle.is_solved and world.puzzle.door.opened, "puzle inaccesible por interact")
	check(world.puzzle.door.global_position.x == 2720, "compuerta desalineada con transición")
	# Exercise the real scene transition, death screen and checkpoint retry.
	tree.current_scene = world
	# Byte debe llegar caminando: el muro del borde no puede tapar la salida.
	byte.global_position = Vector2(2680, 296)
	byte.velocity = Vector2.ZERO
	Input.action_press("move_right")
	await frames(60)
	Input.action_release("move_right")
	await frames(2)
	check(tree.current_scene is RouterBoss, "puerta no lleva a arena")
	check(state.checkpoint == Vector2(64, 296), "entrar al jefe no fija checkpoint de arena")
	var retry_boss: RouterBoss = tree.current_scene as RouterBoss
	retry_boss.invulnerable = false
	retry_boss.state = RouterBoss.State.IDLE
	retry_boss.take_damage(18)
	retry_boss.player.health.damage(3)
	check(tree.paused and is_equal_approx(float(state.get("boss_progress")), 0.3), "muerte no pausa ni conserva progreso del jefe")
	state.call("retry")
	await frames(4)
	check(not tree.paused and tree.current_scene is RouterBoss, "reintento no regresa al jefe")
	retry_boss = tree.current_scene as RouterBoss
	check(retry_boss.health.current == 60 and retry_boss.player.health.current == 3, "reintento no restaura vida")
	check(is_equal_approx(retry_boss.player.global_position.x, 64), "reintento no reposiciona al inicio de la arena del jefe")
	tree.current_scene = null
	retry_boss.queue_free()
	await tree.process_frame
	# Offscreen enemies cannot fire; worms only telegraph after damage.
	var arena: Node2D = Node2D.new()
	tree.root.add_child(arena)
	pool = ProjectilePool.new()
	arena.add_child(pool)
	byte = StageBuilder.player(arena, Vector2(64, 296), 640)
	byte.set_physics_process(false)
	var popup: PopUp = PopUp.new()
	popup.position = Vector2(1200, 200)
	arena.add_child(popup)
	await frames(150)
	check(_count_active(pool.enemy_bullets) == 0, "Pop-up dispara fuera de pantalla")
	var worm: NetworkWorm = NetworkWorm.new()
	worm.position = Vector2(200, 280)
	arena.add_child(worm)
	await frames(30)
	check(worm.state == EnemyBase.State.IDLE, "Gusano dispara sin recibir daño")
	worm.take_damage(1, Vector2.ZERO)
	await frames(2)
	check(worm.state == EnemyBase.State.TELEGRAPH, "Gusano no avisa tras daño")
	await frames(20)
	check(_count_active(pool.enemy_bullets) == 2, "Gusano no suelta dos paquetes")
	arena.queue_free()
	await tree.process_frame
	# A single enemy bullet removes exactly 1 PV through the body raycast.
	var hit_arena: Node2D = Node2D.new()
	tree.root.add_child(hit_arena)
	pool = ProjectilePool.new()
	hit_arena.add_child(pool)
	byte = StageBuilder.player(hit_arena, Vector2(64, 296), 640)
	byte.set_physics_process(false)
	byte.shield_active = false
	byte.invulnerability = 0
	byte.hurt_left = 0
	await frames(2)
	check(byte.health.current == 3, "vida de partida antes de la bala")
	pool.fire(true, byte.global_position + Vector2(16, 0), Vector2(-300, 0))
	await frames(8)
	check(byte.health.current == 2, "bala enemiga no resta exactamente 1 PV")
	hit_arena.queue_free()
	await tree.process_frame
	# All boss attacks run in deterministic steps, including second ring delay.
	var boss: RouterBoss = RouterBoss.new()
	tree.root.add_child(boss)
	boss.process_mode = Node.PROCESS_MODE_DISABLED
	boss.player.position = boss.body.position
	boss.invulnerable = false
	boss.state = RouterBoss.State.IDLE
	boss._physics_process(1.0 / 60.0)
	check(boss.player.health.current == 2, "jefe no daña por contacto")
	boss.player.health.reset()
	boss.player.invulnerability = 0
	boss.player.position = Vector2(64, 296)
	boss.state = RouterBoss.State.IDLE
	boss.invulnerable = false
	boss.timer = 0
	boss.advance(0.01)
	check(boss.attack == &"A" and boss.timer == 0.6, "aviso anillo")
	boss.advance(0.61)
	check(_count_active(boss.pool.enemy_bullets) == 12, "anillo de 12")
	boss.pool.clear_enemy()
	boss.phase = 1
	boss.state = RouterBoss.State.TELEGRAPH
	boss.timer = 0
	boss.advance(0.01)
	boss.advance(0.34)
	check(_count_active(boss.pool.enemy_bullets) == 12, "segundo anillo prematuro")
	boss.advance(0.02)
	check(_count_active(boss.pool.enemy_bullets) == 24, "anillo doble a 0,35")
	boss.pool.clear_enemy()
	boss.state = RouterBoss.State.IDLE
	boss.sequence_index = 1
	boss.timer = 0
	boss.advance(0.01)
	check(boss.attack == &"C" and boss.timer == 1.0, "aviso láser")
	boss.advance(1.01)
	boss.advance(0.01)
	check(boss.player.health.current == 2, "láser no daña")
	boss.pool.clear_enemy()
	boss.state = RouterBoss.State.IDLE
	boss.sequence_index = 2
	boss.timer = 0
	boss.advance(0.01)
	check(boss.attack == &"B" and boss.timer == 0.8, "aviso estampida")
	boss.advance(0.81)
	for index: int in range(4):
		boss.advance(0.28)
	check(_count_active(boss.pool.enemy_bullets) == 4, "estampida de cuatro")
	check(boss.pool.enemy_bullets[0].velocity.x > 0 and boss.pool.enemy_bullets[1].velocity.x < 0 and boss.pool.enemy_bullets[3].can_hop, "estampida alternada y salto final")
	# Ring-to-ring period in phase one remains three seconds at 60 Hz.
	boss.pool.clear_enemy()
	boss.player.health.reset()
	boss.player.invulnerability = 100
	boss.phase = 0
	boss.state = RouterBoss.State.IDLE
	boss.sequence_index = 0
	boss.ring_wait = 0
	boss.timer = 0
	var ring_ticks: Array[int] = []
	var previous_state: RouterBoss.State = boss.state
	for tick: int in range(600):
		boss._physics_process(1.0 / 60.0)
		if boss.state == RouterBoss.State.ACTIVE and previous_state == RouterBoss.State.TELEGRAPH and boss.attack == &"A":
			ring_ticks.append(tick)
			check(_count_active(boss.pool.enemy_bullets) == 12, "cada anillo debe emitir 12 balas")
			boss.pool.clear_enemy()
		elif boss.attack == &"B":
			boss.pool.clear_enemy()
		previous_state = boss.state
	check(ring_ticks.size() == 4, "se esperaban cuatro anillos F1: %s" % str(ring_ticks))
	for index: int in range(1, ring_ticks.size()):
		check(ring_ticks[index] - ring_ticks[index - 1] == 180, "anillo F1: deben transcurrir 180 ticks entre emisiones: %s" % str(ring_ticks))
	# Defeat -> spawned core -> real Area2D pickup -> saved victory.
	boss.health.current = 1
	boss.invulnerable = false
	boss.take_damage(1)
	boss.advance(0.61)
	boss.player.global_position = Vector2(320, 296)
	boss.process_mode = Node.PROCESS_MODE_INHERIT
	await frames(4)
	check(tree.paused and "w1_l1" in state.get("data")["completed_levels"], "derrota y pickup no llegan a victoria")
	tree.paused = false
	boss.queue_free()
	await tree.process_frame
	# Persistent core IDs prevent farming on retries.
	check(not bool(state.call("collect_core", &"w1_router")), "núcleo duplicado")
	state.call("win")
	var saved: Dictionary = manager.call("load_game")
	check(saved["data_cores"] == 1 and "w1_l1" in saved["completed_levels"], "victoria no persiste")
	DirAccess.remove_absolute("user://test_integration.json")
	for message: String in errors:
		print("FAIL integration: " + message)
	if errors.is_empty(): print("PASS integration: física, controles, escudo, vacío, pools, puzle, enemigos, ataques y persistencia")
	return errors

func _count_active(bullets: Array[Projectile]) -> int:
	var count: int = 0
	for bullet: Projectile in bullets:
		if bullet.active: count += 1
	return count
