class_name PasswordPuzzle
extends Node2D

signal solved

const FACT: String = "Dato: la autenticación comprueba que eres quien dices ser; por eso una contraseña obvia es un riesgo."
const INSTRUCTION: String = "Acércate a los pósteres y pulsa %s en las ranuras para cambiar sus símbolos."
const CLUES: Array[String] = ["● va justo antes que ★", "▲ va antes que ■", "● no va primero", "★ no va al final"]
const POSTERS: Array[Vector2] = [Vector2(22, 195), Vector2(172, 223), Vector2(322, 195), Vector2(472, 223)]

var slots: Array[PasswordSlot] = []
var door: PacketDoor
var reset_node: NetworkNode
var is_solved: bool = false
var _code: Array[PasswordLogic.Symbol] = []
var _clue_labels: Array[Label] = []
var _caption: Label
var _player: PacketPlayer

func _ready() -> void:
	_player = get_tree().get_first_node_in_group(&"player") as PacketPlayer
	PQStyle.label_at(self, "CONTRASEÑAS LÓGICAS", Vector2(24, 85), 22, PQStyle.CYAN)
	_caption = PQStyle.label_at(self, "", Vector2(24, 122), 13, PQStyle.EDGE)
	GameState.settings_changed.connect(_settings_changed)
	_caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_caption.size.x = 575
	for index: int in range(CLUES.size()):
		var poster: Vector2 = POSTERS[index]
		var clue: Label = PQStyle.label_at(self, CLUES[index], poster + Vector2(9, 3), 11, PQStyle.AMBER)
		clue.hide()
		_clue_labels.append(clue)
		var slot: PasswordSlot = PasswordSlot.new()
		slot.position = Vector2(144 + index * 80, 296)
		slot.activated.connect(_cycle.bind(index))
		slots.append(slot)
		add_child(slot)

	door = PacketDoor.new()
	door.position = Vector2(640, 304)
	door.size = Vector2(16, 304)
	add_child(door)
	reset_node = NetworkNode.new()
	reset_node.position = Vector2(56, 296)
	reset_node.activated.connect(reset_puzzle)
	add_child(reset_node)
	PQStyle.label_at(self, "↺ REINICIAR", Vector2(23, 256), 11, PQStyle.GREEN)
	_code.assign(PasswordLogic.SOLUTION if GameState.current_world == 4 and GameState.puzzle_complete else PasswordLogic.INITIAL)
	_refresh()
	set_process(is_instance_valid(_player))

func _process(_delta: float) -> void:
	var player_x: float = to_local(_player.global_position).x
	var all_revealed: bool = true
	for index: int in range(_clue_labels.size()):
		var clue: Label = _clue_labels[index]
		if absf(player_x - (POSTERS[index].x + 67.0)) <= 78.0:
			clue.show()
		all_revealed = all_revealed and clue.visible
	if all_revealed:
		set_process(false)

func _cycle(index: int) -> void:
	if is_solved:
		return
	_code[index] = PasswordLogic.cycle(_code[index]) as PasswordLogic.Symbol
	_refresh()
	if is_solved:
		Events.puzzle_solved.emit(&"w4_password")
		solved.emit()

func reset_puzzle() -> void:
	_code.assign(PasswordLogic.INITIAL)
	_refresh()

func _settings_changed(key: String) -> void:
	if key.is_empty() or key == "bindings":
		_caption.text = FACT if is_solved else INSTRUCTION % InputLabels.for_action(&"interact")

func _refresh() -> void:
	is_solved = PasswordLogic.is_solution(_code)
	if GameState.current_world == 4:
		GameState.puzzle_complete = is_solved
	door.set_open(is_solved)
	_settings_changed("bindings")
	_caption.add_theme_color_override("font_color", PQStyle.GREEN if is_solved else PQStyle.EDGE)
	for index: int in range(slots.size()):
		slots[index].symbol = _code[index]
		slots[index].accepted = is_solved
		slots[index].queue_redraw()

func _draw() -> void:
	for poster: Vector2 in POSTERS:
		var panel: Rect2 = Rect2(poster, Vector2(134, 23))
		draw_rect(panel, PQStyle.NIGHT)
		draw_rect(panel, PQStyle.EDGE, false)
		draw_rect(Rect2(poster + Vector2(125, 5), Vector2(3, 3)), PQStyle.AMBER)
