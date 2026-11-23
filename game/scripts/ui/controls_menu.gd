class_name ControlsMenu
extends PacketScreen

signal closed

var _buttons: Dictionary[StringName, Button] = {}
var _capturing: StringName = &""
var _status: Label
var _shift_pending: bool = false

func _ready() -> void:
	super._ready()
	layer = 32
	title("Controles", PQStyle.CYAN, 4)
	var header: Label = PQStyle.label_at(panel, "TECLADO  ·  MANDO", Vector2(223, 43), 10, PQStyle.CYAN)
	header.size.x = 350
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	PQStyle.label_at(panel, "ACCIÓN", Vector2(67, 43), 10, PQStyle.CYAN)
	var focus: Array[Button] = []
	for action: StringName in InputBindings.actions():
		var y: float = 58.0 + focus.size() * 19.0
		var caption: String = InputBindings.action_name(action)
		PQStyle.label_at(panel, caption, Vector2(67, y + 2), 12)
		var row: Button = PQStyle.button(panel, "", Vector2(223, y), _begin_capture.bind(action), 350)
		row.name = action
		row.add_theme_font_size_override("font_size", 11)
		row.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		for state: String in ["normal", "hover", "focus", "pressed"]:
			var box: StyleBoxFlat = (row.get_theme_stylebox(state) as StyleBoxFlat).duplicate() as StyleBoxFlat
			box.content_margin_top = 0
			box.content_margin_bottom = 0
			row.add_theme_stylebox_override(state, box)
		row.size.y = 18
		_buttons[action] = row
		focus.append(row)
	_status = PQStyle.label_at(panel, "", Vector2(28, 288), 12, PQStyle.AMBER)
	_status.size = Vector2(584, 30)
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	focus.append(PQStyle.button(panel, "Restaurar predeterminados", Vector2(68, 322), _restore, 270))
	focus.append(PQStyle.button(panel, "Volver", Vector2(397, 322), _close, 176))
	for index: int in range(focus.size()):
		var row: Button = focus[index]
		row.focus_neighbor_top = row.get_path_to(focus[posmod(index - 1, focus.size())])
		row.focus_neighbor_bottom = row.get_path_to(focus[(index + 1) % focus.size()])
		row.focus_previous = row.focus_neighbor_top
		row.focus_next = row.focus_neighbor_bottom
	GameState.settings_changed.connect(_refresh)
	_refresh("")
	focus[0].grab_focus()

func _refresh(key: String) -> void:
	if not key.is_empty() and key != "bindings":
		return
	for action: StringName in _buttons:
		var row: Button = _buttons[action]
		row.text = InputLabels.summary(action)
		row.tooltip_text = row.text
		row.accessibility_name = "%s. %s" % [InputBindings.action_name(action), row.text]

func _begin_capture(action: StringName) -> void:
	_capturing = action
	_shift_pending = false
	_buttons[action].grab_focus()
	_status.text = "Pulsa una tecla o botón · Escape cancela"
	if _capturing == &"pause":
		_status.text += "\nMayús + Escape asigna Escape a Pausa"

func _input(event: InputEvent) -> void:
	if _capturing.is_empty() or not (event is InputEventKey or event is InputEventJoypadButton or event is InputEventJoypadMotion):
		return
	get_viewport().set_input_as_handled()
	if event.is_echo() or event is InputEventJoypadMotion:
		return
	if event is InputEventKey:
		var code: Key = InputBindings.key_code(event)
		if code == KEY_SHIFT and _capturing == &"pause":
			if event.pressed or not _shift_pending:
				_shift_pending = event.pressed
				return
		elif not event.pressed:
			return
		if code == KEY_ESCAPE and not (_capturing == &"pause" and event.shift_pressed):
			_capturing = &""
			_status.text = "Captura cancelada."
			return
		_assign("keys", code)
	elif event.pressed:
		_assign("buttons", event.button_index)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("pause"):
		get_viewport().set_input_as_handled()
		_close()

func _assign(device: String, code: int) -> void:
	var action: String = String(_capturing)
	if not InputBindings.valid_code(device, code, action):
		return
	_capturing = &""
	var defaults: Dictionary = InputBindings.defaults()
	var updated: Dictionary = defaults.duplicate(true)
	updated.merge((GameState.settings["bindings"] as Dictionary).duplicate(true), true)
	var source: Array = updated[action][device]
	var previous: int = source[0] if not source.is_empty() else -1
	var conflict: String = ""
	for other: String in updated:
		var codes: Array = updated[other][device]
		var slot: int = codes.find(code)
		if slot == -1:
			continue
		if other == action:
			codes[slot] = previous
		elif previous == KEY_ESCAPE and device == "keys":
			_status.text = "Escape se reserva para Pausa. Elige una tecla libre."
			return
		else:
			if previous == -1:
				codes.remove_at(slot)
			else:
				codes[slot] = previous
			conflict = other
		break
	if source.is_empty():
		source.append(code)
	else:
		source[0] = code
	for id: String in defaults:
		if updated[id] == defaults[id]:
			updated.erase(id)
	var message: String = "Control guardado."
	if not conflict.is_empty():
		var format: String = "Botón transferido de %s." if previous == -1 else "Intercambio con %s."
		message = format % InputBindings.action_name(StringName(conflict))
	_save(updated, message)

func _restore() -> void:
	_capturing = &""
	_save({}, "Controles predeterminados restaurados.")

func _save(bindings: Dictionary, message: String) -> void:
	_status.text = message if GameState.update_setting("bindings", bindings) == OK else "No se pudieron guardar los controles."

func _close() -> void:
	hide()
	closed.emit()
	queue_free()
