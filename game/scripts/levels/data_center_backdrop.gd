class_name DataCenterBackdrop
extends Node2D

const COLD: Color = Color("0b1a2e")
const RACK_BLUE: Color = Color("1b3a5c")
const HOT: Color = Color("2a0f3a")
const AISLE_WIDTH: int = 360

@export var width: int = 640

func _ready() -> void:
	z_index = -10

func _draw() -> void:
	for x: int in range(0, width, AISLE_WIDTH):
		var hot: bool = floori(x / float(AISLE_WIDTH)) % 2 == 1
		var tint: Color = PQStyle.MAGENTA if hot else PQStyle.CYAN
		var aisle: Rect2 = Rect2(x, 58, minf(AISLE_WIDTH, width - x), 246)
		draw_rect(aisle, Color(HOT if hot else COLD, 0.52))
		draw_rect(Rect2(x, 68, aisle.size.x, 5), Color(tint, 0.24))
		draw_rect(Rect2(x, 277, aisle.size.x, 27), Color(tint, 0.065))
		draw_line(Vector2(x + 2, 71), Vector2(x + 2, 302), Color(tint, 0.2), 3)
		for index: int in range(4):
			var rack_x: float = x + 24 + index * 84
			if rack_x + 64 >= width:
				break
			_draw_rack(rack_x, tint, hot)
		for stripe: int in range(x + 8, int(aisle.end.x) - 10, 16):
			draw_line(Vector2(stripe, 282), Vector2(stripe + 6, 277), Color(PQStyle.AMBER, 0.33), 2)
	for y: float in [77.0, 269.0, 292.0]:
		draw_line(Vector2(0, y), Vector2(width, y), Color(PQStyle.EDGE, 0.3))

func _draw_rack(x: float, tint: Color, hot: bool) -> void:
	var rack: Rect2 = Rect2(x, 91, 64, 170)
	draw_rect(rack, HOT.lerp(PQStyle.EDGE, 0.17) if hot else RACK_BLUE)
	draw_rect(rack, Color(tint, 0.22), false)
	draw_rect(Rect2(x + 5, 98, 54, 7), Color(tint, 0.19))
	for y: int in range(114, 249, 17):
		draw_rect(Rect2(x + 5, y, 54, 12), Color(PQStyle.NIGHT, 0.7))
		draw_line(Vector2(x + 10, y + 5), Vector2(x + 37, y + 5), Color(PQStyle.EDGE, 0.52), 2)
		draw_rect(Rect2(x + 47, y + 4, 3, 3), Color(tint, 0.56))
		draw_rect(Rect2(x + 53, y + 4, 2, 3), Color(PQStyle.AMBER, 0.43))
