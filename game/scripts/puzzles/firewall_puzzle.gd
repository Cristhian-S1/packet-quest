class_name FirewallPuzzle
extends Node2D

signal solved

const EXIT_X: float = 640.0
const MAX_MISTAKES: int = 2
const COLORS: Array[Color] = [PQStyle.RED, PQStyle.GREEN, PQStyle.BLUE]
const COLOR_NAMES: Array[String] = ["ROJO", "VERDE", "AZUL"]
const SHAPE_NAMES: Array[String] = ["CÍRCULO", "TRIÁNGULO", "CUADRADO"]
const FACT: String = "Dato: un firewall deja pasar o bloquea cada paquete según sus reglas."
const INSTRUCTION: String = "Pulsa %s junto a un terminal para decidir."

@export var sequence_seed: int = 0

var pass_node: NetworkNode
var block_node: NetworkNode
var reset_node: NetworkNode
var door: PacketDoor
var is_solved: bool = false
var mistakes: int = 0
var packet_index: int = 0

var _packets: Array[Dictionary] = []
var _status: Label
var _packet_label: Label
var _feedback: Label
var _feedback_pattern: String
var _slide: float = 0.0
var _waiting: float = 0.0
var _hint: bool = false
var _player: PacketPlayer

func _ready() -> void:
	GameState.settings_changed.connect(_settings_changed)
	_packets = FirewallFilter.generate_sequence(sequence_seed)
	_player = get_tree().get_first_node_in_group(&"player") as PacketPlayer
	reset_node = _create_node(64.0, "↺ REINICIAR", PQStyle.AMBER, reset_puzzle)
	pass_node = _create_node(200.0, "PASAR", PQStyle.GREEN, _decide.bind(true))
	block_node = _create_node(288.0, "BLOQUEAR", PQStyle.RED, _decide.bind(false))

	door = PacketDoor.new()
	door.position = Vector2(EXIT_X, 304)
	door.size.y = 304
	add_child(door)
	PQStyle.label_at(self, "FIREWALL  /  FILTRO DE PAQUETES", Vector2(32, 88), 19, PQStyle.CYAN)
	PQStyle.label_at(self, "Bloquea ROJO · Permite ▲", Vector2(32, 117), 16, PQStyle.AMBER)
	_status = PQStyle.label_at(self, "", Vector2(284, 154), 11)
	_packet_label = PQStyle.label_at(self, "", Vector2(284, 173), 12, PQStyle.CYAN)
	_feedback = PQStyle.label_at(self, "", Vector2(32, 218), 12)
	_set_feedback(INSTRUCTION)
	PQStyle.label_at(self, "Firewall Corrupto →", Vector2(498, 273), 12, PQStyle.AMBER)
	if GameState.puzzle_complete:
		is_solved = true
		packet_index = _packets.size()
		door.set_open()
		_set_feedback(FACT)
	_update_display()

func _settings_changed(key: String) -> void:
	if key.is_empty() or key == "reduce_flashes":
		queue_redraw()
	if key.is_empty() or key == "bindings":
		_set_feedback(_feedback_pattern)

func _set_feedback(pattern: String) -> void:
	_feedback_pattern = pattern
	_feedback.text = pattern % InputLabels.for_action(&"interact") if "%s" in pattern else pattern

func _create_node(x: float, title: String, color: Color, action: Callable) -> NetworkNode:
	var node: NetworkNode = NetworkNode.new()
	node.position = Vector2(x, 296)
	node.accent = color
	node.activated.connect(action)
	add_child(node)
	var caption: Label = PQStyle.label_at(self, title, Vector2(x - 43, 249), 10, color)
	caption.size.x = 86
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return node

func _decide(pass_packet: bool) -> void:
	if packet_index >= _packets.size():
		return
	var correct: bool = pass_packet == _packet_allowed()
	if not correct:
		mistakes += 1
	packet_index += 1
	_waiting = 0.0
	_hint = false
	_slide = 1.0
	_set_feedback("Decisión correcta." if correct else "Ese paquete seguía la otra salida.")
	if packet_index == _packets.size():
		if mistakes <= MAX_MISTAKES:
			is_solved = true
			GameState.puzzle_complete = true
			door.set_open()
			_set_feedback(FACT)
			solved.emit()
			Events.puzzle_solved.emit(&"w3_firewall")
		else:
			_set_feedback("Demasiados fallos. Pulsa %s en ↺ REINICIAR.")
	_update_display()

func reset_puzzle() -> void:
	packet_index = 0
	mistakes = 0
	is_solved = false
	GameState.puzzle_complete = false
	_waiting = 0.0
	_hint = false
	_slide = 0.0
	door.set_open(false)
	_set_feedback(INSTRUCTION)
	_update_display()

func _packet_allowed() -> bool:
	var packet: Dictionary = _packets[packet_index]
	return FirewallFilter.is_allowed(packet["shape"], packet["color"], FirewallFilter.TRIANGLE, FirewallFilter.RED)

func _update_display() -> void:
	_status.text = "PAQUETE %02d/%02d  ·  FALLOS %d/%d" % [
		mini(packet_index + 1, _packets.size()), _packets.size(), mistakes, MAX_MISTAKES]
	if packet_index < _packets.size():
		var packet: Dictionary = _packets[packet_index]
		_packet_label.text = "%s / %s" % [SHAPE_NAMES[packet["shape"]], COLOR_NAMES[packet["color"]]]
	else:
		_packet_label.text = "CONEXIÓN ESTABLECIDA" if is_solved else "REINICIO NECESARIO"
	queue_redraw()

func _process(delta: float) -> void:
	if packet_index >= _packets.size():
		return
	if _slide > 0.0:
		_slide = maxf(0.0, _slide - delta * 4.0)
		queue_redraw()
	if is_instance_valid(_player) and _player.global_position.x >= global_position.x:
		_waiting += delta
	var hint: bool = _waiting >= 60.0 and fposmod(_waiting - 60.0, 10.0) < 1.0
	if hint != _hint or hint and not GameState.reduce_flashes:
		_hint = hint
		queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(32, 146, 216, 60), PQStyle.NIGHT)
	var rail_color: Color = PQStyle.GREEN if is_solved else PQStyle.EDGE
	for y: float in [146.0, 206.0]:
		draw_line(Vector2(32, y), Vector2(248, y), rail_color, 2.0)
		for x: int in range(40, 245, 16):
			draw_line(Vector2(x, y), Vector2(x + 4, y + 4), rail_color)
	draw_polyline(PackedVector2Array([Vector2(200, 206), Vector2(200, 239), Vector2(288, 239)]), rail_color, 1.0)
	if packet_index < _packets.size():
		_draw_packet(_packets[packet_index], Vector2(140.0 - 86.0 * _slide, 176))
		if _hint and (GameState.reduce_flashes or int(_waiting * 6.0) % 2 == 0):
			var target: NetworkNode = pass_node if _packet_allowed() else block_node
			draw_arc(target.position, 17.0, 0.0, TAU, 16, Color.WHITE, 1.0)

func _draw_packet(packet: Dictionary, center: Vector2) -> void:
	var tint: Color = COLORS[packet["color"]]
	draw_rect(Rect2(center - Vector2(23, 23), Vector2(46, 46)), Color(tint, 0.12))
	draw_rect(Rect2(center - Vector2(23, 23), Vector2(46, 46)), tint, false)
	match int(packet["shape"]):
		FirewallFilter.CIRCLE:
			draw_circle(center, 13, tint)
		FirewallFilter.TRIANGLE:
			draw_colored_polygon(PackedVector2Array([center + Vector2(0, -14),
				center + Vector2(14, 11), center + Vector2(-14, 11)]), tint)
		FirewallFilter.SQUARE:
			draw_rect(Rect2(center - Vector2(12, 12), Vector2(24, 24)), tint)
