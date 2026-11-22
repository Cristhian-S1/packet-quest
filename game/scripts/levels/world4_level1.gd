class_name World4Level1
extends Node2D

const WIDTH: int = 3200
const FLOOR: float = 304.0
const PIT_LEFT: float = 1568.0
const PIT_RIGHT: float = 1664.0
const PUZZLE_START: float = 2560.0
const TROJAN: PackedScene = preload("res://scenes/enemies/Trojan.tscn")
const PUZZLE: PackedScene = preload("res://scenes/puzzles/PasswordPuzzle.tscn")

var player: PacketPlayer
var puzzle: PasswordPuzzle
var _hidden_core: DataCore
var _transitioning: bool = false

func _ready() -> void:
	GameState.current_world = 4
	GameState.in_boss = false
	GameState.death_cause = "nivel_4_1"
	var backdrop: ServerBackdrop = ServerBackdrop.new()
	backdrop.width = WIDTH
	add_child(backdrop)
	add_child(ProjectilePool.new())
	StageBuilder.platform(self, Vector2(-16, 0), Vector2(16, 360))
	StageBuilder.platform(self, Vector2(0, FLOOR), Vector2(800, 56))
	StageBuilder.platform(self, Vector2(800, 176), Vector2(320, 184))
	StageBuilder.platform(self, Vector2(1120, FLOOR), Vector2(PIT_LEFT - 1120.0, 56))
	StageBuilder.platform(self, Vector2(PIT_RIGHT, FLOOR), Vector2(WIDTH - PIT_RIGHT, 56))
	StageBuilder.platform(self, Vector2(128, 208), Vector2(112, 12), 0.0, true)
	StageBuilder.platform(self, Vector2(2200, 176), Vector2(160, 12), 0.0, true)
	_add_elevator(&"ElevatorS2", 760.0)
	_add_elevator(&"ElevatorS4", 2160.0)
	player = StageBuilder.player(self, GameState.checkpoint, WIDTH)
	player.fatal_pits = true
	_add_vent(176.0, 0.0)
	_add_vent(480.0, 1.35)
	for x: float in [1400.0, 1800.0, 2000.0]:
		var trojan: Trojan = TROJAN.instantiate() as Trojan
		trojan.position = Vector2(x, 296)
		add_child(trojan)
	_add_core(&"w4_core_a", Vector2(176, 196))
	_hidden_core = _add_core(&"w4_core_b", Vector2(2280, 164))
	_hidden_core.hide()
	for x: float in [1920.0, PUZZLE_START]:
		var checkpoint: PacketCheckpoint = PacketCheckpoint.new()
		checkpoint.position = Vector2(x, 296)
		checkpoint.trigger_height = FLOOR
		add_child(checkpoint)
	puzzle = PUZZLE.instantiate() as PasswordPuzzle
	puzzle.position.x = PUZZLE_START
	add_child(puzzle)
	_signs()
	StageBuilder.hud(self)

func _add_vent(x: float, phase_offset: float) -> void:
	var vent: AirVent = AirVent.new()
	vent.position = Vector2(x, 244)
	vent.phase_offset = phase_offset
	add_child(vent)

func _add_elevator(node_name: StringName, center_x: float) -> void:
	var elevator: DataElevator = DataElevator.new()
	elevator.name = node_name
	elevator.position = Vector2(center_x - elevator.size.x / 2.0, 280)
	add_child(elevator)

func _add_core(id: StringName, center: Vector2) -> DataCore:
	var core: DataCore = DataCore.new()
	core.core_id = id
	core.position = center
	add_child(core)
	return core

func _signs() -> void:
	PQStyle.label_at(self, "04-1  /  SALA DE SERVIDORES", Vector2(38, 84), 22, PQStyle.CYAN)
	PQStyle.label_at(self, "Las corrientes de aire te elevan", Vector2(38, 118), 14, PQStyle.AMBER)
	PQStyle.label_at(self, "Salta al ascensor cuando baje", Vector2(661, 132), 14, PQStyle.CYAN)
	PQStyle.label_at(self, "Elimina al Troyano para cerrar su portal", Vector2(1294, 106), 14, PQStyle.AMBER)
	PQStyle.label_at(self, "Salto + dash", Vector2(1471, 229), 13, PQStyle.AMBER)
	PQStyle.label_at(self, "Punto de restauración", Vector2(1934, 180), 11, PQStyle.GREEN)

func _physics_process(_delta: float) -> void:
	if is_instance_valid(_hidden_core) and not _hidden_core.visible:
		if player.global_position.distance_squared_to(_hidden_core.global_position) <= 42.0 * 42.0:
			_hidden_core.show()
	if not _transitioning and puzzle.is_solved and player.state != PacketPlayer.State.DEAD and player.position.x >= WIDTH:
		_transitioning = true
		GameState.enter_boss()

func _draw() -> void:
	draw_rect(Rect2(PIT_LEFT, FLOOR, PIT_RIGHT - PIT_LEFT, 56), PQStyle.NIGHT)
	for x: int in range(int(PIT_LEFT) + 9, int(PIT_RIGHT), 14):
		draw_line(Vector2(x - 4, 358), Vector2(x + 4, 349), PQStyle.AMBER, 2.0)
	for x: float in [PIT_LEFT - 12.0, PIT_RIGHT + 12.0]:
		draw_rect(Rect2(x - 7.0, FLOOR - 4.0, 14.0, 3.0), PQStyle.AMBER)
