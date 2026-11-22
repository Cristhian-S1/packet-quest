class_name CableCell
extends Area2D

signal rotated(cell: Vector2i)

var cell: Vector2i
var openings: int = 0
var connected: bool = false

func _ready() -> void:
	collision_layer = 32
	collision_mask = 0
	monitoring = false
	add_child(PQStyle.box_shape(Vector2(16, 16)))

func receive_projectile(_amount: float, _origin: Vector2, _incoming: Vector2) -> void:
	rotated.emit(cell)

func _draw() -> void:
	var color: Color = PQStyle.CYAN if connected else PQStyle.EDGE
	draw_rect(Rect2(-15, -15, 30, 30), PQStyle.NIGHT)
	draw_rect(Rect2(-15, -15, 30, 30), Color(color, 0.55), false, 1)
	for index: int in range(CableGrid.STEPS.size()):
		if openings & CableGrid.SIDES[index]:
			draw_line(Vector2.ZERO, Vector2(CableGrid.STEPS[index]) * 16, color, 4)
	draw_circle(Vector2.ZERO, 4, color)
