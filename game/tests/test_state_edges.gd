extends RefCounted

class StateProbe extends "res://scripts/autoload/game_state.gd":
	var last_scene: String = ""
	func _ready() -> void:
		pass
	func change_scene(path: String) -> void:
		last_scene = path

var finished: bool = false
var errors: PackedStringArray = []

func check(ok: bool, message: String) -> void:
	if not ok:
		errors.append(message)

func run(tree: SceneTree) -> PackedStringArray:
	var state: StateProbe = StateProbe.new()
	tree.root.add_child(state)
	state.data = SaveManager.defaults()
	state.data["unlocked_worlds"] = [1, 2, 3, 4]
	for world: int in range(1, 5):
		state.in_boss = true
		state.checkpoint = Vector2.ZERO
		state.puzzle_complete = true
		state.start_run(world)
		check(state.current_world == world and state.playing and not state.in_boss, "iniciar mundo %d" % world)
		check(state.checkpoint == Vector2(48, 296) and not state.puzzle_complete, "reinicio de mundo %d" % world)
		check(state.last_scene == state.WORLDS[world - 1]["level"], "escena nivel %d" % world)
		state.enter_boss()
		check(state.in_boss and state.checkpoint == Vector2(64, 296), "entrada al jefe %d" % world)
		check(state.last_scene == state.WORLDS[world - 1]["boss"], "escena jefe %d" % world)
		state.playing = false
		state.boss_progress = 0.8
		state.retry()
		check(state.playing and state.boss_progress == 0 and state.last_scene == state.WORLDS[world - 1]["boss"], "reintento jefe %d" % world)
		state.win()
		state.win()
		check(state.data["completed_levels"].count("w%d_boss" % world) == 1, "victoria idempotente %d" % world)
		if world < 4:
			check(state.data["unlocked_worlds"].count(world + 1) == 1, "desbloqueo idempotente %d" % world)
	state.data = SaveManager.defaults()
	state.current_world = 1
	state.start_run(2)
	check(state.current_world == 1, "mundo bloqueado no inicia")
	state.start_run(0)
	check(state.current_world == 1, "mundo cero no inicia")
	check(state.collect_core(&"test_core"), "primera recogida")
	check(not state.collect_core(&"test_core"), "recogida duplicada rechazada")
	check(state.data["data_cores"] == 1 and state.data["collected_cores"].size() == 1, "núcleo contado una vez")
	state.death_cause = "prueba"
	state.record_death()
	state.record_death()
	check(not state.playing and state.data["stats"]["deaths"]["prueba"] == 2, "registro de muertes")
	state.free()
	finished = true
	return errors
