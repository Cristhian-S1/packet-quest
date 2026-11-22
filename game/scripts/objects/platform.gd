class_name ChipPlatform
extends AnimatableBody2D

@export var size: Vector2 = Vector2(96, 16)
@export var vertical_travel: float = 0.0
@export var period: float = 3.2
@export var one_way: bool = false
var anchor: Vector2
var age: float = 0.0

func _ready() -> void:
	collision_layer = 1
	collision_mask = 0
	anchor = position
	var shape: CollisionShape2D = PQStyle.box_shape(size)
	shape.position = size / 2
	shape.one_way_collision = one_way
	add_child(shape)
	sync_to_physics = true

func _physics_process(delta: float) -> void:
	if vertical_travel != 0:
		age += delta
		position.y = anchor.y - (1 - cos(age * TAU / period)) * vertical_travel / 2
		queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), PQStyle.CHIP)
	draw_line(Vector2.ZERO, Vector2(size.x, 0), PQStyle.EDGE, 2)
	for x: int in range(8, int(size.x), 16):
		draw_line(Vector2(x, 5), Vector2(x + 6, 5), PQStyle.BOARD, 2)
	if vertical_travel > 0:
		draw_line(Vector2(size.x / 2, 0), Vector2(size.x / 2, -160), PQStyle.EDGE, 1)
		draw_line(Vector2.ZERO, Vector2(size.x, 0), PQStyle.CYAN, 2)
