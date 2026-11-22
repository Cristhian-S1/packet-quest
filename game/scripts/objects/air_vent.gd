class_name AirVent
extends Area2D

const PERIOD: float = 3.0
const ACTIVE_TIME: float = 2.0
const WARNING_START: float = 2.5

@export var size: Vector2 = Vector2(96, 120)
@export var push_up: float = 240.0
@export_range(0.0, 3.0) var phase_offset: float = 0.0

var _age: float = 0.0
var _player: PacketPlayer
var _reduce_flashes: bool = false

static func state_at(t: float) -> StringName:
	var phase_time: float = fposmod(t, PERIOD)
	if phase_time < ACTIVE_TIME:
		return &"active"
	return &"inactive" if phase_time < WARNING_START else &"warning"

static func lift_velocity(fall: float, upward_speed: float) -> float:
	return minf(fall, -upward_speed)

func _ready() -> void:
	process_physics_priority = -10
	collision_layer = 0
	collision_mask = 2
	monitorable = false
	add_child(PQStyle.box_shape(size))
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_age = phase_offset
	_reduce_flashes = bool(GameState.data.get("settings", {}).get("reduce_flashes", false))

func _on_body_entered(body: Node2D) -> void:
	if body is PacketPlayer:
		_player = body as PacketPlayer

func _on_body_exited(body: Node2D) -> void:
	if body == _player:
		_player = null

func _physics_process(delta: float) -> void:
	_age += delta
	if state_at(_age) == &"active" and is_instance_valid(_player) and _player.state != PacketPlayer.State.DEAD:
		_player.velocity.y = lift_velocity(_player.velocity.y, push_up)
	queue_redraw()

func _draw() -> void:
	var phase_state: StringName = state_at(_age)
	var color: Color = PQStyle.CYAN if phase_state == &"active" else PQStyle.AMBER
	var grate_y: float = size.y / 2.0
	draw_rect(Rect2(-size.x / 2.0, grate_y - 6.0, size.x, 6.0), PQStyle.CHIP)
	draw_line(Vector2(-size.x / 2.0, grate_y), Vector2(size.x / 2.0, grate_y), color, 2.0)
	for x: int in range(8, int(size.x), 8):
		draw_line(Vector2(x - size.x / 2.0, grate_y - 5.0), Vector2(x - size.x / 2.0, grate_y - 2.0), PQStyle.EDGE)
	if phase_state == &"inactive" or (phase_state == &"warning" and not _reduce_flashes and int(_age * 12.0) % 2 != 0):
		return
	draw_rect(Rect2(-size / 2.0, size), Color(color, 0.07))
	for index: int in range(16):
		var x: float = (float((index * 37) % 97) / 97.0 - 0.5) * (size.x - 8.0)
		var y: float = grate_y - fposmod(_age * 105.0 + index * 19.0, size.y - 5.0)
		draw_line(Vector2(x, y), Vector2(x, y - 4.0), Color(color, 0.62))
