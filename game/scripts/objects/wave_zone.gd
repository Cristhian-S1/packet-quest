class_name WaveZone
extends Area2D

@export var size: Vector2 = Vector2(160, 120)
@export var push: float = 90.0
@export var phase_offset: float = 0.0

var _age: float = 0.0
var _player: PacketPlayer
var _reduce_flashes: bool = false

static func state_at(t: float) -> StringName:
	var cycle: float = fposmod(t, 3.0)
	if cycle < 2.0:
		return &"active"
	return &"inactive" if cycle < 2.5 else &"warning"

func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	monitorable = false
	process_physics_priority = -10
	_age = phase_offset
	_reduce_flashes = bool(GameState.data.get("settings", {}).get("reduce_flashes", false))
	add_child(PQStyle.box_shape(size))
	body_entered.connect(_track_player)
	body_exited.connect(_release_player)

func _track_player(body: Node2D) -> void:
	if body is PacketPlayer:
		_player = body as PacketPlayer

func _release_player(body: Node2D) -> void:
	if body == _player:
		_player = null

func _physics_process(delta: float) -> void:
	_age += delta
	if state_at(_age) == &"active" and is_instance_valid(_player):
		_player.external_push.x += push
	queue_redraw()

func _draw() -> void:
	var phase: StringName = state_at(_age)
	var color: Color = Color(PQStyle.CYAN, 0.5)
	if phase == &"inactive":
		color.a = 0.14
	elif phase == &"warning":
		color = Color(PQStyle.AMBER, 0.75 if _reduce_flashes or sin(_age * 28) > 0 else 0.24)
	draw_rect(Rect2(-size / 2, size), Color(color, color.a * 0.12))
	var direction: float = -1.0 if push < 0 else 1.0
	var heading: float = PI if push < 0 else 0.0
	var spacing: float = size.x / 4.0
	for index: int in range(4):
		var offset: float = fposmod(index * spacing + _age * 30, size.x - 12) - size.x / 2
		draw_arc(Vector2(offset * direction, 0), size.y * 0.36, heading - 0.88, heading + 0.88, 12, color, 2.0)
