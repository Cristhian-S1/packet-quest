extends RefCounted

const EXITS: Array[float] = [2710.0, 2880.0, 3040.0, 3200.0, 3590.0]
var errors: PackedStringArray = []
var finished: bool = false

func run(tree: SceneTree) -> PackedStringArray:
	for index: int in range(EXITS.size()):
		GameState.current_world = index + 1
		GameState.in_boss = false
		GameState.puzzle_complete = false
		GameState.boss_progress = 0.37
		var scene: Node = (load(GameState.current_level) as PackedScene).instantiate()
		tree.root.add_child(scene)
		var player: PacketPlayer = scene.get("player") as PacketPlayer
		player.position = Vector2(EXITS[index] / 2.0, 110)
		await tree.physics_frame
		await tree.physics_frame
		_check("level_progress" in GameState and is_equal_approx(float(GameState.get("level_progress")), 0.5),
			"mundo %d registra el avance durante el recorrido" % (index + 1))
		_check(is_equal_approx(GameState.boss_progress, 0.37), "mundo %d conserva el progreso del jefe" % (index + 1))
		# La muerte puede ocurrir antes de que el HUD reciba otro fotograma físico.
		player.position.x = EXITS[index] * 0.75
		player._die()
		_check(tree.paused and _has_progress(scene, "Progreso del nivel: 75 %"),
			"mundo %d muestra la posición al morir respecto a su salida" % (index + 1))
		scene.free()
		tree.paused = false

	GameState.in_boss = true
	GameState.current_world = 1
	var boss: RouterBoss = (load(GameState.current_level) as PackedScene).instantiate() as RouterBoss
	tree.root.add_child(boss)
	boss.invulnerable = false
	boss.take_damage(boss.max_health * 0.25)
	boss.player._die()
	_check(tree.paused and _has_progress(boss, "Progreso del jefe: 25 %"),
		"la muerte en jefe sigue mostrando la proporción de vida quitada")
	boss.free()
	tree.paused = false
	finished = true
	return errors

func _has_progress(scene: Node, caption: String) -> bool:
	var screen: Node = scene.find_child("DeathScreen", true, false)
	if screen == null:
		return false
	for label: Node in screen.find_children("*", "Label", true, false):
		if (label as Label).text == caption:
			return true
	return false

func _check(condition: bool, message: String) -> void:
	if not condition:
		errors.append(message)
