class_name CableGrid
extends RefCounted

enum Tile { EMPTY, STRAIGHT, ELBOW, TEE }
const N: int = 1
const E: int = 2
const S: int = 4
const W: int = 8
const SIZE: Vector2i = Vector2i(4, 3)
const ANTENNA: Vector2i = Vector2i(0, 1)
const ROUTER: Vector2i = Vector2i(3, 0)
const TILES: Array[Tile] = [
	Tile.TEE, Tile.ELBOW, Tile.STRAIGHT, Tile.STRAIGHT,
	Tile.STRAIGHT, Tile.ELBOW, Tile.TEE, Tile.ELBOW,
	Tile.ELBOW, Tile.STRAIGHT, Tile.ELBOW, Tile.TEE,
]
const INITIAL: Array[int] = [0, 3, 0, 0, 0, 1, 0, 0, 2, 1, 2, 3]
const SOLUTION: Array[int] = [0, 1, 1, 1, 1, 3, 0, 0, 2, 1, 2, 3]
const BASE_MASKS: Array[int] = [0, N | S, N | E, N | E | S]
const SIDES: Array[int] = [N, E, S, W]
const STEPS: Array[Vector2i] = [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]

var _rotations: Array[int] = INITIAL.duplicate()

func reset() -> void:
	_rotations.assign(INITIAL)

func restore_solution() -> void:
	_rotations.assign(SOLUTION)

func rotate_cell(cell: Vector2i) -> void:
	if Rect2i(Vector2i.ZERO, SIZE).has_point(cell):
		var index: int = cell.y * SIZE.x + cell.x
		_rotations[index] = (_rotations[index] + 1) % 4

func openings(cell: Vector2i) -> int:
	var index: int = cell.y * SIZE.x + cell.x
	var mask: int = BASE_MASKS[TILES[index]]
	for turn: int in range(_rotations[index]):
		mask = ((mask << 1) | (mask >> 3)) & 15
	return mask

func connected_cells() -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	if not openings(ANTENNA) & W:
		return cells
	cells.append(ANTENNA)
	var bounds: Rect2i = Rect2i(Vector2i.ZERO, SIZE)
	var cursor: int = 0
	while cursor < cells.size():
		var cell: Vector2i = cells[cursor]
		var mask: int = openings(cell)
		for direction: int in range(STEPS.size()):
			var next: Vector2i = cell + STEPS[direction]
			if mask & SIDES[direction] and bounds.has_point(next) and next not in cells:
				if openings(next) & SIDES[(direction + 2) % 4]:
					cells.append(next)
		cursor += 1
	return cells

func is_solved() -> bool:
	return bool(openings(ROUTER) & E) and ROUTER in connected_cells()
