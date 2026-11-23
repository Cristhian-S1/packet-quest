class_name QosRoom
extends Node2D

signal solved

const INSTRUCTION: String = "Pulsa %s en los interruptores, de más a menos bloques de urgencia."
const FACT: String = "Dato: QoS prioriza el tráfico urgente (voz y vídeo) sobre las descargas."
const BRIDGE_SIZE: Vector2 = Vector2(76, 8)
const BRIDGE_Y: float = 260.0
const FALL_TIME: float = 0.4

var activated: Array[StringName] = []
var is_solved: bool = false

var _bridge_shapes: Array[CollisionShape2D] = []
var _player: PacketPlayer
var _caption: Label
var _elapsed: float = 0.0
var _fall: float = 0.0
var _hint_bridge: StringName = &""

@onready var nodes: Array[QosNode] = [$Correo, $Voz, $Descarga, $Video]
@onready var door: PacketDoor = $Door
@onready var reset_node: NetworkNode = $Reset

func _ready() -> void:
	_player = get_tree().get_first_node_in_group(&"player") as PacketPlayer
	PQStyle.label_at(self, "PRIORIDAD DE TRÁFICO", Vector2(28, 109), 22, PQStyle.CYAN)
	_caption = PQStyle.label_at(self, INSTRUCTION % InputLabels.for_action(&"interact"), Vector2(28, 148), 13, PQStyle.EDGE)
	GameState.settings_changed.connect(_settings_changed)
	PQStyle.label_at(self, "↺", Vector2(25, 257), 15, PQStyle.GREEN)
	for node: QosNode in nodes:
		node.pressed.connect(_on_pressed)
		var bridge: StaticBody2D = StaticBody2D.new()
		bridge.collision_layer = 1
		bridge.collision_mask = 0
		bridge.position = Vector2(node.position.x, BRIDGE_Y)
		var shape: CollisionShape2D = PQStyle.box_shape(BRIDGE_SIZE)
		shape.one_way_collision = true
		shape.disabled = true
		bridge.add_child(shape)
		add_child(bridge)
		_bridge_shapes.append(shape)
	reset_node.activated.connect(reset_puzzle)
	set_process(is_instance_valid(_player))
	if GameState.current_world == 5 and GameState.puzzle_complete:
		activated.assign(QosPuzzle.PRIORITY)
		_set_solved(true)
	_refresh()

func _on_pressed(id: StringName) -> void:
	if is_solved or id in activated:
		return
	activated.append(id)
	if activated.size() == QosPuzzle.PRIORITY.size():
		if QosPuzzle.is_correct_order(activated):
			_set_solved(true)
			Events.puzzle_solved.emit(&"w5_qos")
			solved.emit()
		else:
			activated.clear()
			_fall = FALL_TIME
			_caption.text = "Orden incorrecto. Prueba de nuevo."
			set_process(true)
	_refresh()

func reset_puzzle() -> void:
	activated.clear()
	_elapsed = 0.0
	_fall = 0.0
	_set_solved(false)
	_refresh()

func _set_solved(value: bool) -> void:
	is_solved = value
	_fall = 0.0
	if GameState.current_world == 5:
		GameState.puzzle_complete = value
	door.set_open(value)
	_settings_changed("bindings")
	_caption.add_theme_color_override(&"font_color", PQStyle.GREEN if value else PQStyle.EDGE)
	set_process(not value and is_instance_valid(_player))

func _process(delta: float) -> void:
	if _fall > 0.0:
		_fall = maxf(0.0, _fall - delta)
		if is_zero_approx(_fall):
			_settings_changed("bindings")
			set_process(is_instance_valid(_player) and not is_solved)
		queue_redraw()
	if not is_instance_valid(_player):
		return
	var x: float = to_local(_player.global_position).x
	if x >= 0.0 and x < door.position.x:
		_elapsed += delta
	var hint: StringName = &""
	if _elapsed >= 60.0 and fposmod(_elapsed - 60.0, 10.0) < 1.0:
		hint = QosPuzzle.next_expected(activated)
	_update_lights(hint)

func _settings_changed(key: String) -> void:
	if (key.is_empty() or key == "bindings") and _fall <= 0.0:
		_caption.text = FACT if is_solved else INSTRUCTION % InputLabels.for_action(&"interact")

func _refresh() -> void:
	_update_lights(&"")
	for index: int in range(nodes.size()):
		var active: bool = StringName(nodes[index].traffic_id) in activated
		_bridge_shapes[index].set_deferred(&"disabled", not active)
	queue_redraw()

func _update_lights(hint: StringName) -> void:
	if hint != _hint_bridge:
		_hint_bridge = hint
		queue_redraw()
	for node: QosNode in nodes:
		var id: StringName = StringName(node.traffic_id)
		node.set_lights(id in activated, id == hint)

func _draw() -> void:
	var fall_progress: float = 1.0 - _fall / FALL_TIME
	for node: QosNode in nodes:
		var position_at: Vector2 = Vector2(node.position.x, BRIDGE_Y)
		var id: StringName = StringName(node.traffic_id)
		var active: bool = id in activated
		if _fall > 0.0 and not active:
			position_at.y += 42.0 * fall_progress * fall_progress
			draw_rect(Rect2(position_at - BRIDGE_SIZE / 2.0, BRIDGE_SIZE),
				Color(PQStyle.CYAN, 1.0 - fall_progress))
		else:
			var color: Color = PQStyle.CYAN if active or id == _hint_bridge else Color(PQStyle.EDGE, 0.28)
			draw_rect(Rect2(position_at - BRIDGE_SIZE / 2.0, BRIDGE_SIZE),
				color, active)
