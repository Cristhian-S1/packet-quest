class_name ServerBackdrop
extends Node2D

const RACK_SPACING: int = 96
const RACK_START: int = 24

@export var width: int = 640

func _ready() -> void:
	z_index = -10
	var leds: RackLeds = RackLeds.new()
	leds.width = width
	add_child(leds)

func _draw() -> void:
	draw_rect(Rect2(0, 0, width, 360), PQStyle.NIGHT)
	draw_rect(Rect2(0, 62, width, 13), PQStyle.CHIP)
	draw_rect(Rect2(0, 282, width, 24), PQStyle.CHIP)
	for y: float in [66.0, 71.0, 287.0, 294.0]:
		draw_line(Vector2(0, y), Vector2(width, y), Color(PQStyle.EDGE, 0.55), 1.0)
	for x: int in range(RACK_START, width - 60, RACK_SPACING):
		var rack: Rect2 = Rect2(x, 96, 66, 177)
		draw_rect(rack, PQStyle.CHIP)
		draw_rect(rack, Color(PQStyle.EDGE, 0.56), false)
		draw_rect(Rect2(x + 5, 104, 56, 9), Color(PQStyle.EDGE, 0.42))
		draw_rect(Rect2(x + 6, 266, 54, 3), Color(PQStyle.EDGE, 0.45))
		for y: int in range(121, 255, 18):
			draw_rect(Rect2(x + 5, y, 56, 14), PQStyle.NIGHT)
			for slot: int in range(3):
				draw_rect(Rect2(x + 10 + 10 * slot, y + 4, 7, 6), Color(PQStyle.EDGE, 0.46))
		draw_line(Vector2(x + 82, 78), Vector2(x + 82, 276), Color(PQStyle.EDGE, 0.43), 2.0)

class RackLeds extends Node2D:
	var width: int
	var _age: float = 0.0
	var _tick: int = 0

	func _ready() -> void:
		set_process(not bool(GameState.data.get("settings", {}).get("reduce_flashes", false)))

	func _process(delta: float) -> void:
		_age += delta
		var tick: int = floori(_age * 4.0)
		if tick != _tick:
			_tick = tick
			queue_redraw()

	func _draw() -> void:
		for x: int in range(RACK_START, width - 60, RACK_SPACING):
			for y: int in range(121, 255, 18):
				var cyan: float = 0.7 if (x + y + _tick) % 6 < 4 else 0.26
				var amber: float = 0.55 if (y + _tick) % 7 < 3 else 0.18
				draw_rect(Rect2(x + 47, y + 6, 3, 2), Color(PQStyle.CYAN, cyan))
				draw_rect(Rect2(x + 53, y + 6, 3, 2), Color(PQStyle.AMBER, amber))
