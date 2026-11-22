class_name FirewallBackdrop
extends Node2D

const INTERIOR: Color = Color("2a0f3a")
const FRAME: Color = Color("471a43")
const TRACE: Color = Color("5f2851")
const PANEL: Color = Color("23102f")

@export var width: int = 640

func _ready() -> void:
	z_index = -10

func _draw() -> void:
	draw_rect(Rect2(0, 0, width, 360), INTERIOR)
	draw_rect(Rect2(0, 0, width, 36), PANEL)
	draw_rect(Rect2(0, 38, width, 2), TRACE)
	draw_rect(Rect2(0, 300, width, 60), PANEL)
	for x: int in range(0, width, 160):
		var section: float = minf(160.0, width - x)
		draw_rect(Rect2(x + 3, 56, section - 6.0, 234), FRAME, false)
		draw_line(Vector2(x + 16, 170), Vector2(x + section - 13, 170), FRAME)
		draw_line(Vector2(x + 16, 171), Vector2(x + 16, 229), FRAME)
		for y: int in [69, 273]:
			draw_rect(Rect2(x + 12, y, 4, 4), TRACE)
			draw_rect(Rect2(x + section - 16.0, y, 4, 4), TRACE)
		for slot: int in range(8, int(section) - 8, 12):
			draw_line(Vector2(x + slot, 49), Vector2(x + slot + 6, 44), Color(PQStyle.AMBER, 0.37), 2.0)
