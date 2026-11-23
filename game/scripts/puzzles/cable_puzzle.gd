class_name CablePuzzle
extends Node2D

signal solved

const CELL_SIZE: int = 32
const GRID_ORIGIN: Vector2 = Vector2(192, 215)
const CAPTION: String = "Ponte bajo una pieza. Salta y dispara hacia arriba."
const FACT: String = "Dato: los cables y repetidores llevan la señal donde el Wi-Fi no llega."

var grid: CableGrid = CableGrid.new()
var cells: Array[CableCell] = []
var door: PacketDoor
var reset_node: NetworkNode
var is_solved: bool = false
var _caption: Label

func _ready() -> void:
	PQStyle.label_at(self, "REPARAR CABLES", Vector2(32, 100), 22, PQStyle.CYAN)
	PQStyle.label_at(self, "Cada disparo gira una pieza 90°", Vector2(32, 131), 13)
	_caption = PQStyle.label_at(self, CAPTION, Vector2(32, 154), 12, PQStyle.EDGE)
	PQStyle.label_at(self, "ANTENA", Vector2(111, 222), 10, PQStyle.GREEN)
	PQStyle.label_at(self, "ROUTER", Vector2(326, 187), 10, PQStyle.CYAN)
	for y: int in range(CableGrid.SIZE.y):
		for x: int in range(CableGrid.SIZE.x):
			var piece: CableCell = CableCell.new()
			piece.cell = Vector2i(x, y)
			piece.position = _cell_center(piece.cell)
			piece.rotated.connect(_rotate)
			cells.append(piece)
			add_child(piece)
	door = PacketDoor.new()
	door.position = Vector2(480, 304)
	door.size = Vector2(16, 304)
	add_child(door)
	reset_node = NetworkNode.new()
	reset_node.position = Vector2(52, 296)
	reset_node.activated.connect(reset_puzzle)
	add_child(reset_node)
	PQStyle.label_at(self, "↻ REINICIAR", Vector2(20, 255), 11, PQStyle.GREEN)
	if GameState.current_world == 2 and GameState.puzzle_complete:
		grid.restore_solution()
	_refresh()

func _rotate(cell: Vector2i) -> void:
	if is_solved:
		return
	grid.rotate_cell(cell)
	_refresh()
	if is_solved:
		Events.puzzle_solved.emit(&"w2_cable")
		solved.emit()

func reset_puzzle() -> void:
	grid.reset()
	_refresh()

func _refresh() -> void:
	var connected: Array[Vector2i] = grid.connected_cells()
	is_solved = CableGrid.ROUTER in connected and bool(grid.openings(CableGrid.ROUTER) & CableGrid.E)
	if GameState.current_world == 2:
		GameState.puzzle_complete = is_solved
	door.set_open(is_solved)
	_caption.text = FACT if is_solved else CAPTION
	_caption.add_theme_color_override("font_color", PQStyle.GREEN if is_solved else PQStyle.EDGE)
	for piece: CableCell in cells:
		piece.openings = grid.openings(piece.cell)
		piece.connected = piece.cell in connected
		piece.collision_layer = 0 if is_solved else 32
		piece.queue_redraw()
	queue_redraw()

func _draw() -> void:
	var entry: Vector2 = _cell_center(CableGrid.ANTENNA)
	draw_line(entry - Vector2(55, 0), entry, PQStyle.GREEN, 3)
	draw_arc(entry - Vector2(55, 0), 9, 0, TAU, 16, PQStyle.GREEN, 2)
	var exit: Vector2 = _cell_center(CableGrid.ROUTER)
	var color: Color = PQStyle.CYAN if is_solved else PQStyle.EDGE
	draw_line(exit, exit + Vector2(64, 0), color, 3)
	draw_rect(Rect2(exit + Vector2(61, -6), Vector2(12, 12)), color, false, 2)

static func _cell_center(cell: Vector2i) -> Vector2:
	return GRID_ORIGIN + Vector2(cell) * CELL_SIZE
