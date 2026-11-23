class_name LevelParallax
extends CanvasLayer

const GRID_SPEED: float = 0.12
const RACK_SPEED: float = 0.36
const LED_SPEED: float = 0.64
const GRID_TILE: int = 32
const LED_TILE: int = 160

var middle: Node2D
var base: Color
var tint: Color
var _grid: Grid
var _leds: Leds

func _ready() -> void:
	layer = -10
	_grid = Grid.new()
	_grid.name = "Grid"
	_grid.z_index = -20
	_grid.base = base
	add_child(_grid)
	middle.name = "CablesAndRacks"
	add_child(middle)
	_leds = Leds.new()
	_leds.name = "LEDs"
	_leds.tint = tint
	add_child(_leds)

func _process(_delta: float) -> void:
	var camera: Camera2D = get_viewport().get_camera_2d()
	if camera == null:
		return
	var scroll: float = camera.get_screen_center_position().x - 320.0
	_grid.position.x = -floorf(fposmod(scroll * GRID_SPEED, GRID_TILE))
	middle.position.x = -floorf(scroll * RACK_SPEED)
	_leds.position.x = -floorf(fposmod(scroll * LED_SPEED, LED_TILE))

class Grid extends Node2D:
	var base: Color

	func _draw() -> void:
		draw_rect(Rect2(-GRID_TILE, 0, 640 + GRID_TILE * 3, 360), base)
		var trace: Color = Color(PQStyle.EDGE, 0.16)
		for x: int in range(0, 640 + GRID_TILE, GRID_TILE):
			draw_line(Vector2(x, 0), Vector2(x, 360), trace)
		for y: int in range(0, 360, GRID_TILE):
			draw_line(Vector2(0, y), Vector2(640 + GRID_TILE, y), trace)

class Leds extends Node2D:
	var tint: Color

	func _draw() -> void:
		for x: int in range(0, 640 + LED_TILE, LED_TILE):
			_rail(x + 20, 61)
			_rail(x + 98, 286)

	func _rail(x: int, y: int) -> void:
		draw_rect(Rect2(x, y, 35, 7), Color(PQStyle.NIGHT, 0.66))
		draw_rect(Rect2(x + 3, y + 2, 9, 2), Color(tint, 0.36))
		draw_rect(Rect2(x + 17, y + 2, 3, 2), Color(tint, 0.25))
		draw_rect(Rect2(x + 23, y + 2, 3, 2), Color(PQStyle.GREEN, 0.29))
		draw_line(Vector2(x + 35, y + 3), Vector2(x + 58, y + 3), Color(PQStyle.EDGE, 0.25))
