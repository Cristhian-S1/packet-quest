class_name WifiBackdrop
extends Node2D

const SKY: Color = Color("0a152d")
const HORIZON: Color = Color("18314a")
const TOWER: Color = Color("233d59")

var width: int = 640

func _ready() -> void:
	z_index = -10

func _draw() -> void:
	draw_rect(Rect2(0, 0, width, 360), SKY)
	for strip: int in range(8):
		draw_rect(Rect2(0, 64 + strip * 34, width, 34), SKY.lerp(HORIZON, float(strip) / 9.0))
	var index: int = 0
	for x: int in range(9, width, 15):
		var point: Vector2 = Vector2(x, 48 + (index * 47) % 140)
		draw_rect(Rect2(point, Vector2.ONE), Color(PQStyle.CYAN, 0.16))
		index += 1
	index = -1
	for x: int in range(-80, width + 128, 128):
		var top: float = 157 + (index * 37) % 46
		var peak: Vector2 = Vector2(x, top)
		draw_line(peak, Vector2(x - 23, 309), TOWER, 2)
		draw_line(peak, Vector2(x + 23, 309), TOWER, 2)
		for rung: int in range(4):
			var y: float = lerpf(top, 309, (rung + 1) / 5.0)
			draw_line(Vector2(x - 4 * (rung + 1), y), Vector2(x + 4 * (rung + 1), y), TOWER, 2)
		draw_circle(peak, 2, Color(PQStyle.AMBER, 0.65))
		for ring: int in range(3):
			draw_arc(peak, 16 + ring * 13, -2.55, -0.59, 22, Color(PQStyle.CYAN, 0.13), 1)
		index += 1
	index = 0
	for x: int in range(0, width, 64):
		var top: float = 272 - (index * 19) % 24
		draw_rect(Rect2(x + 6, top, 46, 310 - top), Color("14263f"))
		draw_line(Vector2(x + 14, top + 7), Vector2(x + 30, top + 7), TOWER, 1)
		index += 1
