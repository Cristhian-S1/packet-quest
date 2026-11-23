class_name PortLaser
extends Area2D

@export var size: Vector2 = Vector2(16, 96)
@export var phase_offset: float = 0.0

var _age: float = 0.0
var _state: StringName

static func state_at(t: float) -> StringName:
	var cycle: float = fposmod(t, 3.0)
	if cycle < 1.6:
		return &"blocked"
	return &"open" if cycle < 2.5 else &"warning"

func _ready() -> void:
	collision_layer = 64
	collision_mask = 2
	monitorable = false
	var shape: CollisionShape2D = PQStyle.box_shape(size)
	shape.position.y = -size.y / 2.0
	add_child(shape)
	_age = phase_offset
	_state = state_at(_age)

func _physics_process(delta: float) -> void:
	_age += delta
	var next_state: StringName = state_at(_age)
	if next_state != _state or next_state == &"warning":
		_state = next_state
		queue_redraw()
	if _state == &"blocked":
		for body: Node2D in get_overlapping_bodies():
			if body is PacketPlayer:
				(body as PacketPlayer).take_damage(1.0, global_position)

func _draw() -> void:
	var top: Vector2 = Vector2(0, -size.y)
	var color: Color = PQStyle.GREEN
	if _state == &"blocked":
		color = PQStyle.RED
		draw_rect(Rect2(-size.x / 2.0, top.y, size.x, size.y), Color(color, 0.35))
		draw_line(top, Vector2.ZERO, color, 5.0)
		draw_line(top, Vector2.ZERO, Color.WHITE, 1.0)
	elif _state == &"warning":
		color = PQStyle.RED
		draw_dashed_line(top, Vector2.ZERO, color, 2.0, 6.0)
	for y: float in [top.y, -4.0]:
		draw_rect(Rect2(-size.x / 2.0 - 3.0, y - 2.0, size.x + 6.0, 6.0), PQStyle.CHIP)
		draw_line(Vector2(-size.x / 2.0, y), Vector2(size.x / 2.0, y), color, 2.0)
