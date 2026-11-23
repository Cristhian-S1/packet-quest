extends RefCounted

const ENEMIES: Array[String] = ["PopUp", "NetworkWorm", "Spyware", "ArmoredPopUp", "ArmoredWorm", "Trojan", "BotDDoS"]
var errors: PackedStringArray = []
var finished: bool = false

func run(tree: SceneTree) -> PackedStringArray:
	var stage: Node2D = Node2D.new()
	tree.root.add_child(stage)
	var pool: ProjectilePool = ProjectilePool.new()
	stage.add_child(pool)
	var byte: PacketPlayer = StageBuilder.player(stage, Vector2(100, 100))
	byte.set_physics_process(false)
	_box(byte, Vector2(10, 14), Vector2.ZERO)
	_box(byte.hurtbox, Vector2(10, 14), Vector2.ZERO)
	_box(byte.shield_area, Vector2(5, 24), Vector2.ZERO)
	byte._update_aim(-1, 0, false)
	_check(byte.shield_area.position == Vector2(-12, 0), "posición del escudo izquierdo")
	_check(byte.muzzle.position == Vector2(-13, 0), "posición de la boca del cañón")
	_check(byte.collision_layer == 2 and byte.collision_mask == 1, "capas de Byte")
	_check(byte.hurtbox.collision_layer == 2 and byte.shield_area.collision_mask == 16, "capas de protección")
	_test_byte(byte)

	for scene_name: String in ENEMIES:
		var scene: PackedScene = load("res://scenes/enemies/%s.tscn" % scene_name)
		var enemy: EnemyBase = scene.instantiate() as EnemyBase
		enemy.position = Vector2(220, 110)
		stage.add_child(enemy)
		enemy.set_physics_process(false)
		_box(enemy, Vector2(20, 16), Vector2.ZERO)
		_check(enemy.collision_layer == (0 if scene_name == "Spyware" else 4), "capa de " + scene_name)
		_test_enemy(enemy)
	var motion_path: String = "res://scripts/art/art_motion.gd"
	if ResourceLoader.exists(motion_path):
		var motion: Script = load(motion_path)
		_check(float(motion.call("hit_strength", 0.03, false)) > 0.0, "tinte de daño visible")
		_check(float(motion.call("hit_strength", 0.03, true)) == 0.0, "reduce_flashes suprime el destello")
		_check(motion.call("warning_strength", 0.0, true) == motion.call("warning_strength", 0.35, true),
			"el aviso conserva una intensidad fija con reduce_flashes")
		_check(motion.call("warning_strength", 0.0, false) != motion.call("warning_strength", 0.35, false),
			"el aviso admite modulación en el modo normal")
	else:
		errors.append("falta la modulación accesible del arte")
	stage.queue_free()
	await tree.process_frame
	finished = true
	return errors

func _test_byte(byte: PacketPlayer) -> void:
	if not byte.has_method("visual_pose") or not byte.has_method("visual_frame"):
		errors.append("faltan las poses y fotogramas de Byte")
		return
	var poses: Array[StringName] = [&"idle", &"run", &"jump", &"fall", &"dash", &"shield", &"hurt", &"dead"]
	for index: int in range(poses.size()):
		byte.state = index as PacketPlayer.State
		_check(byte.call("visual_pose") == poses[index], "pose de Byte: " + String(poses[index]))
	for count: int in [2, 6]:
		byte.state = PacketPlayer.State.IDLE if count == 2 else PacketPlayer.State.RUN
		var step: float = 0.5 if count == 2 else 0.1
		for index: int in range(count + 1):
			byte.animation_time = step * index + 0.01
			_check(byte.call("visual_frame") == index % count, "ciclo de Byte de %d fotogramas" % count)
	byte.state = PacketPlayer.State.IDLE
	byte.shoot()
	_check(byte.call("visual_pose") == &"fire", "un disparo real activa el retroceso")
	byte.take_damage(1.0, Vector2.ZERO)
	_check(byte.call("visual_pose") == &"hurt", "el daño prevalece sobre el disparo")
	byte.invulnerability = 0.0
	byte.take_damage(3.0, Vector2.ZERO)
	_check(byte.call("visual_pose") == &"dead", "la muerte prevalece sobre el daño")

func _test_enemy(enemy: EnemyBase) -> void:
	if not enemy.has_method("visual_pose") or not enemy.has_method("visual_frame"):
		errors.append("faltan las poses de " + enemy.name)
		return
	var poses: Array[StringName] = [&"idle", &"warning", &"active", &"recovery", &"dead"]
	for index: int in range(poses.size()):
		if "spy_state" in enemy:
			enemy.set("spy_state", index)
			enemy.state = EnemyBase.State.DEAD if index == 4 else EnemyBase.State.IDLE
		else:
			enemy.state = index as EnemyBase.State
		var expected: StringName = &"disguised" if index == 0 and "spy_state" in enemy else poses[index]
		_check(enemy.call("visual_pose") == expected, "%s: pose %s" % [enemy.name, expected])
	enemy.state = EnemyBase.State.IDLE
	if "spy_state" in enemy:
		enemy.set("spy_state", 3)
	for index: int in range(5):
		enemy.age = 0.25 * index + 0.01
		_check(enemy.call("visual_frame") == index % 4, "%s: ciclo de cuatro fotogramas" % enemy.name)

func _box(parent: Node, size: Vector2, offset: Vector2) -> void:
	for child: Node in parent.get_children():
		if child is CollisionShape2D:
			var collision: CollisionShape2D = child as CollisionShape2D
			var rectangle: RectangleShape2D = collision.shape as RectangleShape2D
			_check(rectangle != null and rectangle.size == size and collision.position == offset,
				"geometría de " + parent.name)
			return
	errors.append("falta la forma de " + parent.name)

func _check(condition: bool, message: String) -> void:
	if not condition:
		errors.append(message)
