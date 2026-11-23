class_name CelebrationBurst
extends Node2D

const CORE_TIME: float = 0.36
const BOSS_TIME: float = 0.56

var _age: float = 0.0
var _duration: float
var _boss: bool

static func spawn(parent: Node, origin: Vector2, boss: bool = false) -> void:
	var burst: CelebrationBurst = CelebrationBurst.new()
	burst.name = "BossBurst" if boss else "CoreBurst"
	burst._boss = boss
	burst._duration = BOSS_TIME if boss else CORE_TIME
	burst.top_level = true
	burst.position = origin
	burst.z_index = 1
	burst.process_mode = Node.PROCESS_MODE_ALWAYS
	parent.add_child(burst)
	Events.impact.emit(0.0, 3.0 if boss else 1.0)

func _process(delta: float) -> void:
	_age += delta
	if _age >= _duration:
		queue_free()
		return
	queue_redraw()

func flash_alpha() -> float:
	return 0.0 if GameState.reduce_flashes else 0.58 * maxf(0.0, 1.0 - _age / 0.16)

func _draw() -> void:
	var progress: float = _age / _duration
	var spread: float = 74.0 if _boss else 34.0
	var count: int = 24 if _boss else 12
	var strength: float = 0.83
	if GameState.reduce_flashes:
		count = 12 if _boss else 7
		strength = 0.43
	var color: Color = PQStyle.GREEN if _boss else PQStyle.AMBER
	var alpha: float = strength * (1.0 - progress)
	for index: int in range(count):
		var angle: float = TAU * index / count
		var distance: float = spread * (0.6 + (index * 7 % 5) * 0.1)
		var direction: Vector2 = Vector2.from_angle(angle)
		var point: Vector2 = (direction * lerpf(6.0, distance, progress)).round()
		var pixel: Vector2 = Vector2(3, 3) if index % 3 == 0 else Vector2(2, 2)
		var tint: Color = PQStyle.CYAN if _boss and index % 3 == 0 else color
		draw_rect(Rect2(point - pixel * 0.5, pixel), Color(tint, alpha))
	var flash: float = flash_alpha()
	if flash > 0.0:
		draw_arc(Vector2.ZERO, lerpf(9.0, spread, progress), 0.0, TAU, 24, Color(color, flash), 2.0)
