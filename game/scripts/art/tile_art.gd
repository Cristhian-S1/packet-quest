extends RefCounted

const COPPER: Color = Color("765548")
const MASK: Color = Color("1b283d")
const SOLDER: Color = Color("98766a")
const LED: Color = Color("45816c")

static func chip(canvas: Node2D, rect: Rect2, rim: Color = PQStyle.EDGE, opacity: float = 1.0) -> void:
	var origin: Vector2 = rect.position
	var width: float = rect.size.x
	var height: float = rect.size.y
	canvas.draw_rect(rect, Color(PQStyle.CHIP, opacity))
	canvas.draw_rect(Rect2(origin, Vector2(width, minf(height, 2))), Color(rim, opacity))
	if height < 7.0 or width < 12.0:
		return
	canvas.draw_rect(Rect2(origin + Vector2(0, 2), Vector2(width, 1)), Color(PQStyle.NIGHT, opacity))
	canvas.draw_rect(Rect2(origin + Vector2(0, height - 2), Vector2(width, 2)), Color(MASK, opacity))
	for tile: int in range(0, floori(width) - 11, 32):
		var length: float = minf(width - tile - 2, 31.0)
		var x: float = origin.x + tile
		var end_y: float = origin.y + minf(height - 4, 16.0)
		var y: float = origin.y + 5.0
		canvas.draw_rect(Rect2(x + 4, y - 1, 3, 3), Color(MASK, opacity))
		canvas.draw_rect(Rect2(x + 5, y, 1, 1), Color(LED, opacity))
		canvas.draw_rect(Rect2(x + 10, y, length - 10, 1), Color(COPPER, opacity))
		if height >= 13.0:
			canvas.draw_rect(Rect2(x + 10, y + 1, 1, end_y - y), Color(COPPER, opacity))
			canvas.draw_rect(Rect2(x + 9, end_y, 3, 2), Color(SOLDER, opacity))
		if height >= 24.0 and length >= 20.0:
			var pad: Vector2 = Vector2(x + 16, origin.y + 9)
			canvas.draw_rect(Rect2(pad, Vector2(length - 16, 9)), Color(MASK, opacity))
			canvas.draw_rect(Rect2(pad + Vector2(1, 2), Vector2(length - 18, 1)), Color(PQStyle.EDGE, opacity * 0.6))
			canvas.draw_rect(Rect2(pad + Vector2(2, 9), Vector2(2, 2)), Color(SOLDER, opacity * 0.8))
			if length >= 25.0:
				canvas.draw_rect(Rect2(pad + Vector2(6, 9), Vector2(2, 2)), Color(SOLDER, opacity * 0.8))
