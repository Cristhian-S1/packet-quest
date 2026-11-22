class_name RuleBar
extends Area2D

const LANES_Y: Array[float] = [288.0, 240.0, 184.0]
const GAP_HEIGHT: float = 64.0
const SIZE: Vector2 = Vector2(16, 360)
const LANE_TIME: float = 1.5
const FIXED_WARNING: float = 0.4
const SWEEP_WARNING: float = 0.7

@export var phase_offset: float = 0.0
@export var swept: bool = false

var _age: float = 0.0
var _lanes: Array[int] = []
var _solids: Array[Rect2] = []
var _shapes: Array[CollisionShape2D] = []
var _speed: float = 0.0
var _warning: bool = false
var _reduce_flashes: bool = false

static func gap_lane(t: float) -> int:
	return int(fposmod(t / LANE_TIME, 3.0))

func _ready() -> void:
	collision_layer = 64
	collision_mask = 2
	monitorable = false
	_reduce_flashes = bool(GameState.data.get("settings", {}).get("reduce_flashes", false))
	for _index: int in range(LANES_Y.size() + 1):
		var shape: CollisionShape2D = PQStyle.box_shape(Vector2.ONE)
		shape.disabled = true
		_shapes.append(shape)
		add_child(shape)
	if swept:
		stop_sweep()
	else:
		_age = phase_offset
		_set_gaps([gap_lane(_age)])

func start_sweep(x: float, speed: float, lanes: Array[int]) -> void:
	position.x = x
	_speed = speed
	_age = 0.0
	_warning = true
	_set_gaps(lanes)
	show()
	set_physics_process(true)

func stop_sweep() -> void:
	for shape: CollisionShape2D in _shapes:
		shape.disabled = true
	hide()
	set_physics_process(false)

func _physics_process(delta: float) -> void:
	_age += delta
	if swept:
		if _warning and _age >= SWEEP_WARNING - 0.00001:
			_warning = false
			_update_shapes()
		elif not _warning:
			position.x -= _speed * delta
			if position.x <= -SIZE.x:
				stop_sweep()
				return
	else:
		var lane: int = gap_lane(_age)
		_warning = fposmod(_age, LANE_TIME) >= LANE_TIME - FIXED_WARNING
		if lane != _lanes[0]:
			_set_gaps([lane])
	if not swept or not _warning:
		for body: Node2D in get_overlapping_bodies():
			if body is PacketPlayer:
				(body as PacketPlayer).take_damage(1.0, Vector2(global_position.x, body.global_position.y))
	queue_redraw()

func _set_gaps(lanes: Array[int]) -> void:
	_lanes = lanes
	_solids.clear()
	var top: float = 0.0
	# De arriba abajo para unir las aberturas cuando dos carriles se solapan.
	for lane: int in range(LANES_Y.size() - 1, -1, -1):
		if lane not in _lanes:
			continue
		var center: float = LANES_Y[lane]
		var end: float = center - GAP_HEIGHT / 2.0
		if end > top:
			_solids.append(Rect2(-SIZE.x / 2.0, top, SIZE.x, end - top))
		top = center + GAP_HEIGHT / 2.0
	_solids.append(Rect2(-SIZE.x / 2.0, top, SIZE.x, SIZE.y - top))
	_update_shapes()
	queue_redraw()

func _update_shapes() -> void:
	for index: int in range(_shapes.size()):
		var shape: CollisionShape2D = _shapes[index]
		shape.disabled = (swept and _warning) or index >= _solids.size()
		if not shape.disabled:
			var solid: Rect2 = _solids[index]
			(shape.shape as RectangleShape2D).size = solid.size
			shape.position = solid.get_center()

func _draw() -> void:
	var preview: bool = swept and _warning
	for solid: Rect2 in _solids:
		draw_rect(solid, Color(PQStyle.RED, 0.12 if preview else 0.75))
		draw_rect(solid, Color(PQStyle.RED, 0.6 if preview else 1.0), false)
		for y: int in range(int(solid.position.y) + 8, int(solid.end.y), 16):
			draw_line(Vector2(-4, y), Vector2(4, y - 4), Color(PQStyle.AMBER, 0.45))
	if _warning and (_reduce_flashes or int(_age * 14.0) % 2 == 0):
		var lanes: Array[int] = _lanes
		if not swept:
			lanes = [gap_lane(_age + FIXED_WARNING)]
		for lane: int in lanes:
			draw_rect(Rect2(-SIZE.x / 2.0, LANES_Y[lane] - GAP_HEIGHT / 2.0, SIZE.x, GAP_HEIGHT), Color.WHITE, false)
