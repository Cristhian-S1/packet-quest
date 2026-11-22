class_name World1Level1
extends Node2D

var player: PacketPlayer
var puzzle: RoutePuzzle
# La compuerta ocupa x 2712–2728 y el muro empieza en 2720; con el colisionador de 10 px Byte
# llega a x ≈ 2707 con la compuerta cerrada y a ≈ 2715 abierta. 2710 solo se alcanza tras abrirla.
const EXIT_X: float = 2710.0
var transitioning: bool = false

func _ready() -> void:
	StageBuilder.background(self)
	add_child(ProjectilePool.new())
	StageBuilder.platform(self, Vector2(0, 304), Vector2(752, 56))
	StageBuilder.platform(self, Vector2(848, 304), Vector2(1872, 56))
	StageBuilder.platform(self, Vector2(-16, 0), Vector2(16, 360))
	StageBuilder.platform(self, Vector2(2720, 0), Vector2(16, 360))
	StageBuilder.platform(self, Vector2(528, 256), Vector2(80, 16), 0, true)
	StageBuilder.platform(self, Vector2(624, 256), Vector2(80, 16), 0, true)
	# Raised landing and a clear approach prevent bypassing the dash lesson.
	StageBuilder.platform(self, Vector2(848, 256), Vector2(112, 48))
	StageBuilder.platform(self, Vector2(1008, 256), Vector2(80, 16), 0, true)
	StageBuilder.platform(self, Vector2(1936, 280), Vector2(96, 16), 64, true)
	StageBuilder.platform(self, Vector2(2440, 272), Vector2(64, 12), 0, true)
	player = StageBuilder.player(self, GameState.checkpoint, 2720)
	GameState.death_cause = "nivel_1_1"
	for pos: Vector2 in [Vector2(272, 296), Vector2(416, 296), Vector2(1200, 296), Vector2(1456, 296), Vector2(1664, 296), Vector2(1840, 296), Vector2(2176, 296)]:
		var enemy: PopUp = PopUp.new()
		enemy.position = pos
		add_child(enemy)
	for pos: Vector2 in [Vector2(1312, 280), Vector2(1568, 264), Vector2(2080, 264)]:
		var worm: NetworkWorm = NetworkWorm.new()
		worm.position = pos
		add_child(worm)
	for x: float in [1760.0, 2240.0]:
		var cp: PacketCheckpoint = PacketCheckpoint.new()
		cp.position = Vector2(x, 296)
		add_child(cp)
	var core: DataCore = DataCore.new()
	core.position = Vector2(912, 144)
	add_child(core)
	puzzle = RoutePuzzle.new()
	puzzle.position = Vector2(2240, 0)
	add_child(puzzle)
	_tutorial()
	StageBuilder.hud(self)

func _tutorial() -> void:
	PQStyle.label_at(self, "01 / PUERTO DE ENTRADA", Vector2(40, 144), 20, PQStyle.CYAN)
	PQStyle.label_at(self, "A / D mueve  ·  Espacio salta", Vector2(40, 176), 12)
	PQStyle.label_at(self, "J dispara", Vector2(224, 240), 14, PQStyle.CYAN)
	PQStyle.label_at(self, "K dash", Vector2(384, 240), 14, PQStyle.CYAN)
	PQStyle.label_at(self, "02 / SALTOS", Vector2(528, 192), 16, PQStyle.EDGE)
	PQStyle.label_at(self, "Salta + K en el aire", Vector2(672, 208), 12, PQStyle.CYAN)
	PQStyle.label_at(self, "Salta y ↑ + K", Vector2(880, 112), 10, PQStyle.AMBER)
	PQStyle.label_at(self, "03 / TRÁFICO HOSTIL", Vector2(1168, 160), 18, PQStyle.MAGENTA)
	PQStyle.label_at(self, "L escudo frontal  ·  I fija la mira", Vector2(1168, 192), 12)
	PQStyle.label_at(self, "PUNTO DE RESTAURACIÓN", Vector2(1712, 208), 12, PQStyle.GREEN)
	PQStyle.label_at(self, "04 / CABLE VIVO", Vector2(1920, 128), 18, PQStyle.CYAN)
	PQStyle.label_at(self, "ROUTER FURIOSO  →", Vector2(2720, 208), 18, PQStyle.RED)

func _physics_process(_delta: float) -> void:
	if not transitioning and player.global_position.x >= EXIT_X and puzzle.is_solved:
		transitioning = true
		GameState.enter_boss()

func _draw() -> void:
	for pos: Vector2 in [Vector2(1312, 280), Vector2(1568, 264), Vector2(2080, 264)]:
		draw_polyline(PackedVector2Array([pos + Vector2(-56, 0), pos + Vector2(0, -8), pos + Vector2(56, 0)]), PQStyle.EDGE, 2)
	draw_line(Vector2(912, 156), Vector2(912, 224), Color(PQStyle.AMBER, 0.25), 1)
