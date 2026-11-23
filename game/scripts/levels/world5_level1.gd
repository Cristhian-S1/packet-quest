class_name World5Level1
extends Node2D

const WIDTH: int = 3600
const EXIT_X: float = 3590.0
const FLOOR: float = 304.0
const COVERAGE_PIT: Vector2 = Vector2(800, 1040)
const PORT_PIT: Vector2 = Vector2(1600, 1696)
const CLOUD_PIT: Vector2 = Vector2(2640, 2920)
const ROUTER_POSITION: Vector2 = Vector2(920, 270)
const PUZZLE_START: float = 3040.0
const TROJAN: PackedScene = preload("res://scenes/enemies/Trojan.tscn")
const SPYWARE: PackedScene = preload("res://scenes/enemies/Spyware.tscn")
const BOT: PackedScene = preload("res://scenes/enemies/BotDDoS.tscn")
const QOS: PackedScene = preload("res://scenes/puzzles/QoSPuzzle.tscn")

var player: PacketPlayer
var puzzle: QosRoom
var clouds: Array[CloudPlatform] = []

var _hidden_core: DataCore
var _transitioning: bool = false

func _ready() -> void:
	AudioManager.play_music(&"world_5")
	GameState.current_world = 5
	GameState.in_boss = false
	GameState.death_cause = "nivel_5_1"
	var backdrop: DataCenterBackdrop = DataCenterBackdrop.new()
	backdrop.width = WIDTH
	StageBuilder.parallax(self, backdrop, DataCenterBackdrop.COLD, PQStyle.MAGENTA)
	add_child(ProjectilePool.new())
	_build_floor()
	player = StageBuilder.player(self, GameState.checkpoint, WIDTH)
	player.fatal_pits = true
	_build_vents()
	_build_coverage()
	_build_ports()
	_build_clouds()
	_spawn_enemies()
	for x: float in [2560.0, PUZZLE_START]:
		var checkpoint: PacketCheckpoint = PacketCheckpoint.new()
		checkpoint.position = Vector2(x, 296)
		checkpoint.trigger_height = FLOOR
		add_child(checkpoint)
	puzzle = QOS.instantiate() as QosRoom
	puzzle.position.x = PUZZLE_START
	add_child(puzzle)
	_signs()
	StageBuilder.hud(self, EXIT_X)

func _build_floor() -> void:
	StageBuilder.platform(self, Vector2(-16, 0), Vector2(16, 360))
	StageBuilder.platform(self, Vector2(WIDTH, 0), Vector2(16, 360))
	var start_x: float = 0.0
	for pit: Vector2 in [COVERAGE_PIT, PORT_PIT, CLOUD_PIT]:
		StageBuilder.platform(self, Vector2(start_x, FLOOR), Vector2(pit.x - start_x, 56))
		start_x = pit.y
	StageBuilder.platform(self, Vector2(start_x, FLOOR), Vector2(WIDTH - start_x, 56))

func _build_vents() -> void:
	var landing: ChipPlatform = StageBuilder.platform(self, Vector2(128, 184), Vector2(392, 12), 0.0, true)
	landing.name = &"VentLanding"
	StageBuilder.platform(self, Vector2(520, 184), Vector2(40, 120))
	var wave: WaveZone = WaveZone.new()
	wave.position = Vector2(290, 244)
	wave.push = 70.0
	add_child(wave)
	for center: Vector2 in [Vector2(168, 0), Vector2(431, 1.25)]:
		var vent: AirVent = AirVent.new()
		vent.position = Vector2(center.x, 244)
		vent.phase_offset = center.y
		add_child(vent)

func _build_coverage() -> void:
	var router: Marker2D = Marker2D.new()
	router.name = &"Router"
	router.position = ROUTER_POSITION
	add_child(router)
	for x: float in [822.0, 886.0, 950.0, 1014.0]:
		var platform: CoveragePlatform = CoveragePlatform.new()
		platform.position = Vector2(x, 298)
		platform.router = NodePath("../Router")
		add_child(platform)

func _build_ports() -> void:
	for placement: Vector2 in [Vector2(1376, 0), Vector2(1512, 1.0), Vector2(1848, 2.0)]:
		_add_laser(placement.x, placement.y)
	StageBuilder.platform(self, Vector2(1710, 256), Vector2(136, 12), 0.0, true)
	_add_core(&"w5_core_a", Vector2(1751, 246))

func _build_clouds() -> void:
	var centers: Array[Vector2] = [Vector2(2708, 302), Vector2(2780, 288), Vector2(2852, 302)]
	for index: int in range(centers.size()):
		var cloud: CloudPlatform = CloudPlatform.new()
		cloud.position = centers[index]
		cloud.phase_offset = (centers.size() - 1 - index) * 0.6
		clouds.append(cloud)
		add_child(cloud)
	_add_laser(2976.0, 1.5)
	_hidden_core = _add_core(&"w5_core_b", Vector2(2852, 282))
	_hidden_core.hide()

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

func _spawn_enemies() -> void:
	var worm: NetworkWorm = NetworkWorm.new()
	worm.position = Vector2(2010, 296)
	add_child(worm)
	for x: float in [2120.0, 2300.0]:
		var popup: PopUp = PopUp.new()
		popup.position = Vector2(x, 296)
		add_child(popup)
	var spyware: EnemyBase = SPYWARE.instantiate() as EnemyBase
	spyware.position = Vector2(2235, 296)
	add_child(spyware)
	var trojan: Trojan = TROJAN.instantiate() as Trojan
	trojan.position = Vector2(2460, 296)
	add_child(trojan)
	for center: Vector2 in [Vector2(2072, 239), Vector2(2398, 231), Vector2(2940, 222)]:
		var bot: BotDDoS = BOT.instantiate() as BotDDoS
		bot.position = center
		add_child(bot)

func _signs() -> void:
	_sign("05-1  /  CENTRO DE DATOS", Vector2(38, 87), 22, PQStyle.CYAN)
	_sign("Ondas y corrientes de aire", Vector2(40, 121), 14, PQStyle.AMBER)
	_sign("Mantente cerca del router", Vector2(650, 111), 16, PQStyle.CYAN)
	_sign("Los puertos se abren y se cierran", Vector2(1284, 111), 15, PQStyle.AMBER)
	_sign("Salto + dash →", Vector2(1470, 233), 13, PQStyle.AMBER)
	_sign("Las nubes parpadean antes de caer", Vector2(2578, 115), 14, PQStyle.CYAN)

func _sign(message: String, at: Vector2, font_size: int, color: Color) -> void:
	var label: Label = PQStyle.label_at(self, message, at, font_size, color)
	label.add_theme_color_override(&"font_outline_color", PQStyle.NIGHT)
	label.add_theme_constant_override(&"outline_size", 5)

func _physics_process(_delta: float) -> void:
	if is_instance_valid(_hidden_core) and not _hidden_core.visible:
		if player.global_position.distance_squared_to(_hidden_core.global_position) <= 48.0 * 48.0:
			_hidden_core.show()
	if not _transitioning and player.state != PacketPlayer.State.DEAD and puzzle.is_solved and player.position.x >= EXIT_X:
		_transitioning = true
		GameState.enter_boss()

func _draw() -> void:
	for pit: Vector2 in [COVERAGE_PIT, PORT_PIT, CLOUD_PIT]:
		draw_rect(Rect2(pit.x, FLOOR, pit.y - pit.x, 56), PQStyle.NIGHT)
		for x: int in range(int(pit.x) + 12, int(pit.y) - 4, 14):
			draw_line(Vector2(x - 5, 357), Vector2(x + 2, 349), Color(PQStyle.AMBER, 0.55), 2)
		for x: float in [pit.x - 10, pit.y + 10]:
			draw_line(Vector2(x - 6, 301), Vector2(x + 6, 301), PQStyle.AMBER, 2)
	var antenna: Vector2 = ROUTER_POSITION - Vector2(0, 12)
	for ring: int in range(3):
		draw_arc(antenna, 23 + ring * 12, -2.57, -0.57, 20, Color(PQStyle.CYAN, 0.6), 1)
	draw_rect(Rect2(ROUTER_POSITION - Vector2(16, 6), Vector2(32, 13)), PQStyle.CHIP)
	draw_rect(Rect2(ROUTER_POSITION - Vector2(16, 6), Vector2(32, 13)), PQStyle.CYAN, false)
	draw_line(antenna - Vector2(0, 4), ROUTER_POSITION, PQStyle.CYAN, 2)
	for x: int in range(-9, 11, 6):
		draw_rect(Rect2(ROUTER_POSITION + Vector2(x, -1), Vector2(3, 3)), PQStyle.GREEN)
