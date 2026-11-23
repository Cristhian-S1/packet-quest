class_name RoutePuzzle
extends Node2D

signal solved
@export var solution: Array[int] = [0, 3, 0]
var nodes: Array[PuzzleNode] = []
var door: PacketDoor
var is_solved: bool = false
var elapsed: float = 0.0
var reset_node: NetworkNode
var caption: Label

func _ready() -> void:
	var positions: Array[Vector2] = [Vector2(100, 296), Vector2(228, 296), Vector2(228, 248)]
	for index: int in range(3):
		var node: PuzzleNode = PuzzleNode.new()
		node.position = positions[index]
		node.direction = 1
		node.rotated.connect(_rotated)
		nodes.append(node)
		add_child(node)
	door = PacketDoor.new()
	door.position = Vector2(480, 304)
	door.size = Vector2(16, 304)
	add_child(door)
	reset_node = NetworkNode.new()
	reset_node.position = Vector2(36, 296)
	reset_node.activated.connect(reset_puzzle)
	add_child(reset_node)
	PQStyle.label_at(self, "REINICIAR", Vector2(5, 264), 9, PQStyle.GREEN)
	PQStyle.label_at(self, "RUTA DE PAQUETES", Vector2(40, 115), 20, PQStyle.CYAN)
	InputLabels.label_at(self, "%s gira 90°  ·  Conecta emisor y receptor", [&"interact"], Vector2(40, 143), 12)
	caption = PQStyle.label_at(self, "Sigue los cables: →  ↑  →", Vector2(40, 167), 12, PQStyle.EDGE)
	if GameState.puzzle_complete:
		for index: int in range(nodes.size()):
			nodes[index].direction = solution[index]
		check_solution()

func _rotated(_direction: int) -> void:
	check_solution()

func check_solution() -> bool:
	if nodes.size() != solution.size() or nodes.is_empty():
		return false
	var correct: bool = true
	for index: int in range(nodes.size()):
		nodes[index].connected = correct and nodes[index].direction == solution[index]
		correct = nodes[index].connected
		nodes[index].queue_redraw()
	if correct and not is_solved:
		is_solved = true
		if door != null:
			door.set_open(true)
		GameState.puzzle_complete = true
		solved.emit()
		Events.puzzle_solved.emit(&"w1_route")
		if caption != null:
			caption.text = "¡Conexión establecida! La ruta une origen y destino."
	queue_redraw()
	return correct

func reset_puzzle() -> void:
	is_solved = false
	GameState.puzzle_complete = false
	elapsed = 0
	for node: PuzzleNode in nodes:
		node.direction = 1
		node.connected = false
		node.queue_redraw()
	if door != null:
		door.set_open(false)
	if caption != null:
		caption.text = "Sigue los cables: →  ↑  →"
	queue_redraw()

func _process(delta: float) -> void:
	var player: Node2D = get_tree().get_first_node_in_group("player") as Node2D
	if is_solved or player == null or absf(player.global_position.x - global_position.x - 224) > 300:
		return
	elapsed += delta
	for index: int in range(nodes.size()):
		nodes[index].hint = elapsed >= 60 and fmod(elapsed - 60, 10) < 1 and nodes[index].direction != solution[index]

func _draw() -> void:
	var color: Color = PQStyle.CYAN if is_solved else PQStyle.EDGE
	draw_polyline(PackedVector2Array([Vector2(64, 296), Vector2(100, 296), Vector2(228, 296), Vector2(228, 248), Vector2(390, 248)]), color, 2)
	draw_circle(Vector2(64, 296), 5, PQStyle.GREEN)
	draw_rect(Rect2(386, 243, 10, 10), color)
	draw_string(ThemeDB.fallback_font, Vector2(350, 230), "RECEPTOR", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, color)
