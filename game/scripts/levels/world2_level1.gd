class_name World2Level1
extends Node2D

const WIDTH: int = 2880
const FLOOR: float = 304.0
const PIT_LEFT: float = 800.0
const PIT_RIGHT: float = 1040.0
const PUZZLE_START: float = 2400.0
const SPYWARE: PackedScene = preload("res://scenes/enemies/Spyware.tscn")
const CABLE_PUZZLE: PackedScene = preload("res://scenes/puzzles/CablePuzzle.tscn")

var player: PacketPlayer
var puzzle: CablePuzzle
var _transitioning: bool = false
var _hidden_core: DataCore

func _ready() -> void:
	AudioManager.play_music(&"world_2")
	GameState.current_world = 2
	GameState.in_boss = false
	GameState.death_cause = "nivel_2_1"
	var backdrop: WifiBackdrop = WifiBackdrop.new()
	backdrop.width = WIDTH
	backdrop.draw_base = false
	StageBuilder.parallax(self, backdrop, WifiBackdrop.SKY, PQStyle.CYAN)
	add_child(ProjectilePool.new())
	StageBuilder.platform(self, Vector2(0, FLOOR), Vector2(PIT_LEFT, 56))
	StageBuilder.platform(self, Vector2(PIT_RIGHT, FLOOR), Vector2(WIDTH - PIT_RIGHT, 56))
	StageBuilder.platform(self, Vector2(-16, 0), Vector2(16, 360))
	player = StageBuilder.player(self, GameState.checkpoint, WIDTH)
	player.fatal_pits = true
	_build_waves()
	_build_coverage()
	_spawn_enemies()
	for x: float in [1920.0, PUZZLE_START]:
		var checkpoint: PacketCheckpoint = PacketCheckpoint.new()
		checkpoint.position = Vector2(x, 296)
		checkpoint.trigger_height = 304.0
		add_child(checkpoint)
	puzzle = CABLE_PUZZLE.instantiate() as CablePuzzle
	puzzle.position.x = PUZZLE_START
	add_child(puzzle)
	_signs()
	StageBuilder.hud(self, WIDTH)

func _build_waves() -> void:
	_wave(Vector2(240, 244), 90.0, 0.0)
	_wave(Vector2(456, 244), -90.0, 1.15)
	_wave(Vector2(1728, 244), 90.0, 0.7)
	_wave(Vector2(2340, 244), -90.0, 1.4)

func _wave(center: Vector2, push: float, offset: float) -> void:
	var zone: WaveZone = WaveZone.new()
	zone.position = center
	zone.push = push
	zone.phase_offset = offset
	add_child(zone)

func _build_coverage() -> void:
	var pit_router: Marker2D = _router(&"RouterDelFoso", Vector2(920, 271))
	for center: Vector2 in [Vector2(810, 280), Vector2(880, 254), Vector2(950, 230), Vector2(1020, 262)]:
		_coverage_platform(center, pit_router)
	_add_core(&"w2_core_a", Vector2(950, 196))
	var east_router: Marker2D = _router(&"RouterEste", Vector2(2200, 257))
	_coverage_platform(Vector2(2136, 260), east_router)
	_coverage_platform(Vector2(2232, 223), east_router)
	_hidden_core = _add_core(&"w2_core_b", Vector2(2232, 196))
	_hidden_core.hide()

func _router(node_name: StringName, center: Vector2) -> Marker2D:
	var router: Marker2D = Marker2D.new()
	router.name = node_name
	router.position = center
	add_child(router)
	return router

func _coverage_platform(center: Vector2, router: Node2D) -> void:
	var platform: CoveragePlatform = CoveragePlatform.new()
	platform.position = center
	platform.router = NodePath("../" + String(router.name))
	add_child(platform)

func _add_core(core_id: StringName, center: Vector2) -> DataCore:
	var core: DataCore = DataCore.new()
	core.position = center
	core.core_id = core_id
	add_child(core)
	return core

func _spawn_enemies() -> void:
	for x: float in [1336.0, 1516.0, 1824.0, 2326.0]:
		var spy: EnemyBase = SPYWARE.instantiate() as EnemyBase
		spy.position = Vector2(x, 296)
		add_child(spy)
	for x: float in [1432.0, 1752.0]:
		var popup: PopUp = PopUp.new()
		popup.position = Vector2(x, 296)
		add_child(popup)
	var worm: NetworkWorm = NetworkWorm.new()
	worm.position = Vector2(1624, 288)
	add_child(worm)

func _signs() -> void:
	PQStyle.label_at(self, "02-1  /  ZONA DE COBERTURA", Vector2(42, 84), 22, PQStyle.CYAN)
	PQStyle.label_at(self, "Las ondas te empujan", Vector2(42, 123), 14)
	PQStyle.label_at(self, "PLATAFORMAS DE COBERTURA", Vector2(690, 105), 16, PQStyle.CYAN)
	PQStyle.label_at(self, "Mantente cerca del router para cruzar el foso.", Vector2(690, 130), 12)
	PQStyle.label_at(self, "SEÑUELOS EN LA RED", Vector2(1300, 132), 16, PQStyle.MAGENTA)
	PQStyle.label_at(self, "Punto de restauración", Vector2(1936, 174), 11, PQStyle.GREEN)
	PQStyle.label_at(self, "Reina Wi-Fi →", Vector2(2760, 271), 11, PQStyle.AMBER)

func _physics_process(_delta: float) -> void:
	if is_instance_valid(_hidden_core) and not _hidden_core.visible:
		if _hidden_core.global_position.distance_squared_to(player.global_position) <= 48.0 * 48.0:
			_hidden_core.show()
	if not _transitioning and puzzle.is_solved and player.global_position.x >= WIDTH:
		_transitioning = true
		GameState.enter_boss()

func _draw() -> void:
	_draw_router(Vector2(920, 271))
	_draw_router(Vector2(2200, 257))
	draw_rect(Rect2(PIT_LEFT, FLOOR, PIT_RIGHT - PIT_LEFT, 56), PQStyle.NIGHT)
	for x: int in range(int(PIT_LEFT) + 16, int(PIT_RIGHT), 16):
		draw_line(Vector2(x - 12, 355), Vector2(x, 346), Color(PQStyle.RED, 0.55), 2)
	for x: float in [PIT_LEFT - 12, PIT_RIGHT + 12]:
		draw_line(Vector2(x - 7, 298), Vector2(x + 7, 298), PQStyle.AMBER, 3)

func _draw_router(center: Vector2) -> void:
	for ring: int in range(3):
		draw_arc(center + Vector2(0, -12), 24 + ring * 14, -2.57, -0.57, 20, Color(PQStyle.CYAN, 0.3), 1)
	draw_rect(Rect2(center - Vector2(15, 5), Vector2(30, 13)), PQStyle.CHIP)
	draw_rect(Rect2(center - Vector2(15, 5), Vector2(30, 13)), PQStyle.CYAN, false)
	draw_line(center + Vector2(0, -5), center + Vector2(0, -17), PQStyle.CYAN, 2)
	for x: int in range(-9, 11, 6):
		draw_rect(Rect2(center + Vector2(x, 1), Vector2(3, 3)), PQStyle.GREEN)
