class_name PuzzleNode
extends NetworkNode

signal rotated(direction: int)
@export_range(0, 3) var direction: int = 1
var connected: bool = false
var hint: bool = false

func interact() -> void:
	direction = (direction + 1) % 4
	rotated.emit(direction)
	queue_redraw()

func _draw() -> void:
	var color: Color = PQStyle.CYAN if connected else PQStyle.EDGE
	draw_rect(Rect2(-11, -11, 22, 22), PQStyle.NIGHT)
	draw_rect(Rect2(-11, -11, 22, 22), color, false, 1)
	var arrow: Vector2 = Vector2.RIGHT.rotated(direction * PI / 2)
	draw_line(-arrow * 6, arrow * 6, color, 2)
	draw_line(arrow * 6, arrow * 2 + arrow.orthogonal() * 4, color, 2)
	draw_line(arrow * 6, arrow * 2 - arrow.orthogonal() * 4, color, 2)
	if nearby or hint:
		draw_arc(Vector2.ZERO, 16, 0, TAU, 16, PQStyle.GREEN, 1)
	if nearby:
		draw_string(ThemeDB.fallback_font, Vector2(-3, -20), "E", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color.WHITE)
