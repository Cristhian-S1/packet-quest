extends RefCounted

const SCENES: Array[String] = [
	"res://scenes/levels/World1Level1.tscn", "res://scenes/bosses/RouterBoss.tscn",
	"res://scenes/levels/World2Level1.tscn", "res://scenes/bosses/WifiQueenBoss.tscn",
	"res://scenes/levels/World3Level1.tscn", "res://scenes/bosses/FirewallBoss.tscn",
	"res://scenes/levels/World4Level1.tscn", "res://scenes/bosses/TrojanBoss.tscn",
	"res://scenes/levels/World5Level1.tscn", "res://scenes/bosses/MalwarexBoss.tscn", "res://scenes/ui/CreditsScreen.tscn",
	"res://scenes/main/NetworkMap.tscn", "res://scenes/ui/Workshop.tscn", "res://scenes/main/Main.tscn",
]
const ACTIONS: Array[StringName] = [&"move_left", &"move_right", &"jump", &"dash", &"shoot", &"shield", &"aim_up", &"aim_down", &"lock_aim", &"swap_weapon", &"interact", &"pause"]
var errors: PackedStringArray = []
var finished: bool = false

func run(tree: SceneTree) -> PackedStringArray:
	if is_instance_valid(tree.current_scene):
		tree.current_scene.queue_free()
		await tree.process_frame
	tree.paused = false
	var frames: int = 1200 if OS.has_environment("PACKET_FUZZ_LONG") else 200
	for index: int in range(SCENES.size()):
		await _exercise(tree, SCENES[index], index, frames)
		await _transitions(tree, SCENES[index], index)
	finished = true
	return errors

func _setup(index: int) -> void:
	GameState.data = SaveManager.defaults()
	GameState.current_world = mini(index / 2 + 1, 4) if index < 8 else 1
	GameState.in_boss = index < 8 and index % 2 == 1
	GameState.checkpoint = Vector2(64, 296) if GameState.in_boss else Vector2(48, 296)
	GameState.puzzle_complete = false
	GameState.playing = false

func _exercise(tree: SceneTree, path: String, index: int, frames: int) -> void:
	_setup(index)
	var baseline: int = int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))
	var scene: Node = (load(path) as PackedScene).instantiate()
	tree.root.add_child(scene)
	await tree.physics_frame
	var player: PacketPlayer = tree.get_first_node_in_group(&"player") as PacketPlayer
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 0x51f00d + index
	var inside: int = 0
	for frame: int in range(frames):
		var action: StringName = ACTIONS[rng.randi_range(0, ACTIONS.size() - 1)]
		if action == &"pause":
			if is_instance_valid(player) and player.state != PacketPlayer.State.DEAD:
				await _pause_roundtrip(tree, player, path, frame)
		elif rng.randi_range(0, 1) == 0:
			Input.action_press(action)
		else:
			Input.action_release(action)
		await tree.physics_frame
		if is_instance_valid(player):
			if not player.global_position.is_finite() or not player.velocity.is_finite():
				errors.append("%s frame %d: posición o velocidad no finita" % [path, frame])
				break
			if player.health.current < 0.0 or player.health.current > player.health.max_health:
				errors.append("%s frame %d: PV fuera de rango" % [path, frame])
				break
			if player.shield_meter < 0.0 or player.shield_meter > player.shield_max:
				errors.append("%s frame %d: escudo fuera de rango" % [path, frame])
				break
			inside = inside + 1 if _inside_solid(player) else 0
			if inside > 3:
				errors.append("%s frame %d: Byte dentro de geometría sólida durante %d frames" % [path, frame, inside])
				break
		for node: Node in tree.get_nodes_in_group(&"projectile_pool"):
			var pool: ProjectilePool = node as ProjectilePool
			if pool.player_bullets.size() > pool.player_capacity or pool.enemy_bullets.size() > pool.enemy_capacity:
				errors.append("%s frame %d: pool excede su capacidad" % [path, frame])
		if is_instance_valid(player) and player.state == PacketPlayer.State.DEAD:
			_release()
			tree.paused = false
			scene.queue_free()
			await tree.process_frame
			_setup(index)
			scene = (load(path) as PackedScene).instantiate()
			tree.root.add_child(scene)
			await tree.physics_frame
			player = tree.get_first_node_in_group(&"player") as PacketPlayer
	_release()
	if is_instance_valid(scene):
		scene.queue_free()
	await tree.process_frame
	if Projectile.enemy_time_scale != 1.0:
		errors.append("%s: escala de proyectiles no restablecida" % path)
	var after: int = int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))
	if after > baseline:
		errors.append("%s: nodos tras liberar %d > %d" % [path, after, baseline])

func _inside_solid(player: PacketPlayer) -> bool:
	var shape: RectangleShape2D = RectangleShape2D.new()
	shape.size = Vector2(8, 12)
	var query: PhysicsShapeQueryParameters2D = PhysicsShapeQueryParameters2D.new()
	query.shape = shape
	query.transform = player.global_transform
	query.collision_mask = 1
	query.exclude = [player.get_rid()]
	# Una plataforma unidireccional permite atravesarla desde abajo.
	for hit: Dictionary in player.get_world_2d().direct_space_state.intersect_shape(query, 32):
		var body: CollisionObject2D = hit.collider as CollisionObject2D
		var owner_id: int = body.shape_find_owner(int(hit.shape))
		var owner: CollisionShape2D = body.shape_owner_get_owner(owner_id) as CollisionShape2D
		if owner == null or not owner.one_way_collision:
			return true
	return false

func _pause_roundtrip(tree: SceneTree, player: PacketPlayer, path: String, frame: int) -> void:
	if tree.paused:
		return
	_send_pause(true)
	await tree.process_frame
	await tree.process_frame
	_send_pause(false)
	await tree.process_frame
	if not tree.paused:
		errors.append("%s frame %d: no se activó la pausa" % [path, frame])
		return
	var pos: Vector2 = player.global_position
	var hp: float = player.health.current
	var shield: float = player.shield_meter
	await tree.process_frame
	if player.global_position != pos or player.health.current != hp or player.shield_meter != shield:
		errors.append("%s frame %d: estado cambió durante pausa" % [path, frame])
	_send_pause(true)
	await tree.process_frame
	await tree.process_frame
	_send_pause(false)
	await tree.process_frame
	if tree.paused and player.state != PacketPlayer.State.DEAD:
		errors.append("%s frame %d: no se reanudó" % [path, frame])
		tree.paused = false

func _send_pause(pressed: bool) -> void:
	var event: InputEventAction = InputEventAction.new()
	event.action = &"pause"
	event.pressed = pressed
	Input.parse_input_event(event)

func _release() -> void:
	for action: StringName in ACTIONS:
		Input.action_release(action)

func _transitions(tree: SceneTree, path: String, index: int) -> void:
	var baseline: int = int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))
	var connections: int = Events.impact.get_connections().size()
	for iteration: int in range(20):
		_setup(index)
		var scene: Node = (load(path) as PackedScene).instantiate()
		tree.root.add_child(scene)
		await tree.process_frame
		scene.queue_free()
		await tree.process_frame
		tree.paused = false
		if Projectile.enemy_time_scale != 1.0:
			errors.append("%s ciclo %d: escala de proyectiles no restablecida" % [path, iteration])
	if int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)) > baseline:
		errors.append("%s: fuga de nodos tras 20 entradas" % path)
	if Events.impact.get_connections().size() != connections:
		errors.append("%s: conexiones de impacto acumuladas" % path)
