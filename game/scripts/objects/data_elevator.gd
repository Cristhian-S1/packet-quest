class_name DataElevator
extends ChipPlatform

func _init() -> void:
	size = Vector2(80, 12)
	one_way = true
	vertical_travel = 64.0

static func top_y(anchor_y: float, travel: float, duration: float, t: float) -> float:
	return ChipPlatform.oscillating_top(anchor_y, travel, duration, t)

func _draw() -> void:
	var rail_top: float = anchor.y - vertical_travel - position.y
	var rail_end: float = anchor.y + size.y - position.y
	for x: float in [2.0, size.x - 2.0]:
		draw_line(Vector2(x, rail_top), Vector2(x, rail_end), PQStyle.EDGE, 2.0)
		draw_rect(Rect2(x - 2.0, rail_top, 4.0, 4.0), PQStyle.AMBER)
	super._draw()
