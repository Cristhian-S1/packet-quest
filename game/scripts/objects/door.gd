class_name PacketDoor
extends StaticBody2D

@export var size: Vector2 = Vector2(16, 160)
var opened: bool = false
var shape: CollisionShape2D

func _ready() -> void:
	collision_layer = 1
	collision_mask = 0
	shape = PQStyle.box_shape(size)
	shape.position = Vector2(0, -size.y / 2)
	add_child(shape)
	set_open(opened)

func set_open(value: bool = true) -> void:
	opened = value
	if shape != null:
		shape.set_deferred("disabled", opened)
	queue_redraw()

func activate() -> void:
	set_open(true)

func _draw() -> void:
	if opened:
		draw_rect(Rect2(-10, -5, 20, 5), PQStyle.GREEN)
		return
	draw_rect(Rect2(-size.x / 2, -size.y, size.x, size.y), PQStyle.CHIP)
	for y: int in range(0, int(size.y), 12):
		draw_line(Vector2(-6, -y), Vector2(6, -y - 8), PQStyle.RED, 2)
