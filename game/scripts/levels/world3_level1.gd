class_name World3Level1
extends Node2D

const WIDTH: int = 3040
const FLOOR: float = 304.0
const PIT_LEFT: float = 976.0
const PIT_RIGHT: float = PIT_LEFT + 96.0
const PUZZLE_START: float = 2400.0
const BAR_X: float = 2288.0
const POPUP: PackedScene = preload("res://scenes/enemies/ArmoredPopUp.tscn")
const WORM: PackedScene = preload("res://scenes/enemies/ArmoredWorm.tscn")
const PUZZLE: PackedScene = preload("res://scenes/puzzles/FirewallPuzzle.tscn")

var player: PacketPlayer
var puzzle: FirewallPuzzle
var _transitioning: bool = false
var _hidden_core: DataCore

func _ready() -> void:
	GameState.current_world = 3
	GameState.in_boss = false
	GameState.death_cause = "nivel_3_1"
	var backdrop: FirewallBackdrop = FirewallBackdrop.new()
	backdrop.width = WIDTH
	add_child(backdrop)
	add_child(ProjectilePool.new())
	StageBuilder.platform(self, Vector2(0, FLOOR), Vector2(PIT_LEFT, 56))
	StageBuilder.platform(self, Vector2(PIT_RIGHT, FLOOR), Vector2(WIDTH - PIT_RIGHT, 56))
	StageBuilder.platform(self, Vector2(-16, 0), Vector2(16, 360))
	for x: float in [2064.0, 2198.0]:
		StageBuilder.platform(self, Vector2(x, 256), Vector2(86, 10), 0.0, true)
	player = StageBuilder.player(self, GameState.checkpoint, WIDTH)
	player.fatal_pits = true

	for x: float in [280.0, 444.0, 1440.0, 1856.0, 2352.0]:
		_spawn_enemy(POPUP, Vector2(x, 296))
	for x: float in [1336.0, 1772.0]:
		_spawn_enemy(WORM, Vector2(x, 289))
	_add_laser(664.0, 0.0)
	_add_laser(880.0, 1.05)
	_add_laser(1160.0, 2.15)
	_add_laser(1608.0, 0.65)
	var bar: RuleBar = RuleBar.new()
	bar.position.x = BAR_X
	add_child(bar)

	_add_core(&"w3_core_a", Vector2(793, 282))
	_hidden_core = _add_core(&"w3_core_b", Vector2(2249, 236))
	_hidden_core.hide()
	for x: float in [1920.0, PUZZLE_START]:
		var checkpoint: PacketCheckpoint = PacketCheckpoint.new()
		checkpoint.position = Vector2(x, 296)
		checkpoint.trigger_height = FLOOR
		add_child(checkpoint)

	puzzle = PUZZLE.instantiate() as FirewallPuzzle
	puzzle.position.x = PUZZLE_START
	add_child(puzzle)
	_signs()
	StageBuilder.hud(self)

func _spawn_enemy(scene: PackedScene, center: Vector2) -> void:
	var enemy: EnemyBase = scene.instantiate() as EnemyBase
	enemy.position = center
	add_child(enemy)

func _add_laser(x: float, offset: float) -> void:
	var laser: PortLaser = PortLaser.new()
	laser.position = Vector2(x, FLOOR)
	laser.phase_offset = offset
	add_child(laser)

func _add_core(id: StringName, center: Vector2) -> DataCore:
	var core: DataCore = DataCore.new()
	core.core_id = id
	core.position = center
	add_child(core)
	return core

func _signs() -> void:
	PQStyle.label_at(self, "03-1  /  MURO DE REGLAS", Vector2(42, 84), 22, PQStyle.CYAN)
	PQStyle.label_at(self, "Dispara por detrás", Vector2(42, 117), 15, PQStyle.AMBER)
	PQStyle.label_at(self, "Los puertos se abren y se cierran", Vector2(578, 88), 16)
	PQStyle.label_at(self, "Salta y haz dash para cruzar el foso.", Vector2(839, 145), 12, PQStyle.AMBER)
	PQStyle.label_at(self, "CABLES BLINDADOS", Vector2(1298, 91), 16, PQStyle.RED)
	PQStyle.label_at(self, "Punto de restauración", Vector2(1936, 180), 11, PQStyle.GREEN)
	PQStyle.label_at(self, "Sigue el hueco de la regla", Vector2(2080, 91), 15, PQStyle.AMBER)

func _physics_process(_delta: float) -> void:
	if is_instance_valid(_hidden_core) and not _hidden_core.visible:
		if player.global_position.distance_squared_to(_hidden_core.global_position) <= 42.0 * 42.0:
			_hidden_core.show()
	if not _transitioning and puzzle.is_solved and player.state != PacketPlayer.State.DEAD and player.position.x >= WIDTH:
		_transitioning = true
		GameState.enter_boss()

func _draw() -> void:
	draw_rect(Rect2(PIT_LEFT, FLOOR, PIT_RIGHT - PIT_LEFT, 56), PQStyle.NIGHT)
	for x: int in range(int(PIT_LEFT) + 8, int(PIT_RIGHT), 12):
		draw_line(Vector2(x - 4, 356), Vector2(x + 4, 347), PQStyle.AMBER, 2)
	for x: float in [PIT_LEFT - 12.0, PIT_RIGHT + 12.0]:
		draw_line(Vector2(x - 7, FLOOR - 4), Vector2(x + 7, FLOOR - 4), PQStyle.AMBER, 3)
	for x: float in [560.0, 1280.0, 1920.0, PUZZLE_START]:
		draw_line(Vector2(x, 58), Vector2(x, FLOOR - 8), Color(PQStyle.RED, 0.3))
		for y: float in [63.0, 291.0]:
			draw_rect(Rect2(x - 6, y, 12, 4), PQStyle.RED)
