extends Node2D

const WORLDS: Array[String] = ["Red Local", "Wi-Fi", "Firewall", "Servidor", "Nube", "Centro de datos"]
const NODE_Y: float = 150.0
var age: float = 0.0
var selected_world: int = 1
var enter_button: Button
var _playable: Array[int] = []

func _ready() -> void:
	StageBuilder.background(self)
	PQStyle.label_at(self, "MAPA DE LA RED", Vector2(36, 28), 22, PQStyle.CYAN)
	PQStyle.label_at(self, "NÚCLEOS: %d" % int(GameState.data.get("data_cores", 0)), Vector2(500, 36), 12, PQStyle.AMBER)
	for index: int in range(WORLDS.size()):
		var world: int = index + 1
		var x: float = node_x(index)
		var name_label: Label = PQStyle.label_at(self, "%02d\n%s" % [world, WORLDS[index]], Vector2(x - 44, NODE_Y + 22), 10)
		name_label.size.x = 88
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		var playable: bool = GameState.is_world_playable(GameState.data, world)
		if playable:
			_playable.append(world)
		var status: String = "DISPONIBLE" if playable else "BLOQUEADO"
		if GameState.is_world_unlocked(GameState.data, world) and not playable:
			status = "PRÓXIMAMENTE"
		var status_label: Label = PQStyle.label_at(self, status, Vector2(x - 44, NODE_Y + 56), 8,
			PQStyle.GREEN if playable else PQStyle.EDGE)
		status_label.size.x = 88
		status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	enter_button = PQStyle.button(self, "", Vector2(36, 250), _enter_world, 240)
	var workshop: Button = PQStyle.button(self, "Taller", Vector2(292, 250), GameState.open_workshop, 120)
	var menu: Button = PQStyle.button(self, "Menú", Vector2(428, 250), GameState.menu, 120)
	enter_button.focus_neighbor_bottom = enter_button.get_path_to(workshop)
	enter_button.focus_next = enter_button.get_path_to(workshop)
	for button: Button in [workshop, menu]:
		button.focus_neighbor_top = button.get_path_to(enter_button)
	PQStyle.label_at(self, "← →  Seleccionar mundo   ·   ↓  Taller y menú", Vector2(36, 299), 11, PQStyle.EDGE)
	enter_button.disabled = _playable.is_empty()
	if enter_button.disabled:
		enter_button.text = "Entrar"
		workshop.grab_focus()
	else:
		selected_world = GameState.current_world if GameState.current_world in _playable else _playable[0]
		_update_entry()
		enter_button.grab_focus()

func _input(event: InputEvent) -> void:
	if not is_instance_valid(enter_button) or not enter_button.has_focus() or _playable.size() < 2:
		return
	var step: int = 0
	if event.is_action_pressed(&"ui_left") or event.is_action_pressed(&"move_left"):
		step = -1
	elif event.is_action_pressed(&"ui_right") or event.is_action_pressed(&"move_right"):
		step = 1
	if step != 0:
		var index: int = _playable.find(selected_world)
		selected_world = _playable[posmod(index + step, _playable.size())]
		_update_entry()
		get_viewport().set_input_as_handled()

func _update_entry() -> void:
	enter_button.text = "Entrar: %s  →" % WORLDS[selected_world - 1]

func _enter_world() -> void:
	GameState.start_run(selected_world)

static func node_x(index: int) -> float:
	return 70.0 + index * 100.0

func _process(delta: float) -> void:
	age += delta
	queue_redraw()

func _draw() -> void:
	for index: int in range(WORLDS.size()):
		var center: Vector2 = Vector2(node_x(index), NODE_Y)
		if index < WORLDS.size() - 1:
			draw_line(center + Vector2(12, 0), Vector2(node_x(index + 1) - 12, NODE_Y), PQStyle.CHIP, 2)
		var selected: bool = not _playable.is_empty() and index + 1 == selected_world
		var color: Color = PQStyle.CYAN if selected else (PQStyle.GREEN if index + 1 in _playable else PQStyle.EDGE)
		var pulse: float = 12.0 + (sin(age * 3.0) * 2.0 if selected else 0.0)
		draw_arc(center, pulse, 0, TAU, 32, color, 2)
		draw_rect(Rect2(center - Vector2(5, 5), Vector2(10, 10)), color)
