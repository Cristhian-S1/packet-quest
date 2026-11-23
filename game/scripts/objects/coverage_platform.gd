class_name CoveragePlatform
extends StaticBody2D

const SIZE: Vector2 = Vector2(64, 12)
const WARNING_TIME: float = 0.3

@export var router: NodePath
@export_range(0.0, 1000.0, 1.0) var range_px: float = 160.0

var _shape: CollisionShape2D
var _player: PacketPlayer
var _router: Node2D
var _time_outside: float = WARNING_TIME
var _solid: bool = false

static func is_covered(player_pos: Vector2, router_pos: Vector2, radius: float) -> bool:
	return player_pos.distance_squared_to(router_pos) <= radius * radius

func _ready() -> void:
	collision_layer = 1
	collision_mask = 0
	_router = get_node_or_null(router) as Node2D if not router.is_empty() else null
	_player = get_tree().get_first_node_in_group(&"player") as PacketPlayer
	_shape = PQStyle.box_shape(SIZE)
	_shape.one_way_collision = true
	_solid = _has_coverage()
	_time_outside = 0.0 if _solid else WARNING_TIME
	_shape.disabled = not _solid
	add_child(_shape)

func _has_coverage() -> bool:
	return is_instance_valid(_player) and is_instance_valid(_router) and is_covered(
		_player.global_position, _router.global_position, range_px)

func _physics_process(delta: float) -> void:
	var previous: float = _time_outside
	if _has_coverage():
		_time_outside = 0.0
	else:
		_time_outside = minf(WARNING_TIME, _time_outside + delta)
	var solid: bool = _time_outside < WARNING_TIME
	if solid != _solid:
		_solid = solid
		_shape.set_deferred(&"disabled", not _solid)
	if previous != _time_outside:
		queue_redraw()

func _draw() -> void:
	var color: Color = PQStyle.CYAN
	if not _solid:
		color.a = 0.35
	elif _time_outside > 0.0:
		color = Color(PQStyle.AMBER, 0.8 if GameState.reduce_flashes or sin(_time_outside * 55) > 0 else 0.38)
	draw_rect(Rect2(-SIZE / 2, SIZE), Color(PQStyle.CHIP, color.a))
	draw_line(Vector2(-32, -6), Vector2(32, -6), color, 2)
	for x: int in range(-26, 29, 10):
		draw_line(Vector2(x, 0), Vector2(x + 4, 0), color, 2)
