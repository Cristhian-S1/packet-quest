class_name CircuitBackground
extends Node2D

var age: float = 0.0

func _process(delta: float) -> void:
	age += delta
	queue_redraw()

func _draw() -> void:
	var camera: Camera2D = get_viewport().get_camera_2d()
	var scroll: float = camera.get_screen_center_position().x - 320 if camera != null else age * 8
	draw_rect(Rect2(0, 0, 640, 360), PQStyle.NIGHT)
	for index: int in range(-1, 23):
		var x: float = index * 32 - fposmod(scroll * 0.12, 32)
		draw_line(Vector2(x, 0), Vector2(x, 360), Color(PQStyle.EDGE, 0.12))
	for y: int in range(0, 360, 32):
		draw_line(Vector2(0, y), Vector2(640, y), Color(PQStyle.EDGE, 0.12))
	for index: int in range(-1, 7):
		var x: float = index * 144 - fposmod(scroll * 0.3, 144)
		draw_rect(Rect2(x, 96, 96, 216), Color(PQStyle.BOARD, 0.5))
		draw_rect(Rect2(x + 1, 96, 94, 2), Color(PQStyle.EDGE, 0.22))
		for y: int in range(112, 304, 24):
			draw_rect(Rect2(x + 8, y, 80, 12), Color(PQStyle.CHIP, 0.28))
			draw_rect(Rect2(x + 12, y + 2, 18, 8), Color(PQStyle.NIGHT, 0.6))
			draw_rect(Rect2(x + 35, y + 5, 25, 1), Color("3e2d32"))
			draw_circle(Vector2(x + 77, y + 6), 1, Color(PQStyle.GREEN, 0.3))
	for index: int in range(-1, 9):
		var x: float = index * 96 - fposmod(scroll * 0.55, 96)
		draw_polyline(PackedVector2Array([Vector2(x, 0), Vector2(x, 56), Vector2(x + 32, 88), Vector2(x + 32, 144)]), Color(PQStyle.CYAN, 0.18), 2)
		draw_circle(Vector2(x + 32, 144), 2, Color(PQStyle.CYAN, 0.35 + sin(age * 2 + index) * 0.15))
	draw_rect(Rect2(0, 338, 640, 22), PQStyle.BOARD)
	for index: int in range(40):
		draw_rect(Rect2(index * 16, 344, 3, 2), Color(PQStyle.GREEN, 0.4))
