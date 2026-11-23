class_name OptionsMenu
extends PacketScreen

signal closed

var _rows: VBoxContainer
var _status: Label
var _focus_order: Array[Control] = []

func _ready() -> void:
	super._ready()
	layer = 31
	title("Opciones", PQStyle.CYAN, 24)
	var settings_panel: PanelContainer = PanelContainer.new()
	settings_panel.position = Vector2(136, 76)
	settings_panel.custom_minimum_size.x = 368
	settings_panel.add_theme_stylebox_override("panel", PQStyle.panel(PQStyle.NIGHT, PQStyle.EDGE))
	panel.add_child(settings_panel)
	_rows = VBoxContainer.new()
	_rows.add_theme_constant_override("separation", 5)
	settings_panel.add_child(_rows)
	_add_toggle("Sacudida de pantalla", "screen_shake")
	_add_toggle("Reducir destellos", "reduce_flashes")
	_add_toggle("Modo asistencia", "assist_mode")
	_add_slider("Música", "music_volume")
	_add_slider("Efectos", "sfx_volume")
	var back: Button = PQStyle.button(panel, "Volver", Vector2(248, 285), _close, 144)
	_focus_order.append(back)
	for index: int in range(_focus_order.size()):
		var control: Control = _focus_order[index]
		var previous: Control = _focus_order[posmod(index - 1, _focus_order.size())]
		var next: Control = _focus_order[(index + 1) % _focus_order.size()]
		control.focus_neighbor_top = control.get_path_to(previous)
		control.focus_neighbor_bottom = control.get_path_to(next)
		control.focus_previous = control.focus_neighbor_top
		control.focus_next = control.focus_neighbor_bottom
	_status = PQStyle.label_at(panel, "", Vector2(136, 327), 13, PQStyle.AMBER)
	_status.size.x = 368
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_focus_order[0].grab_focus()

func _unhandled_input(event: InputEvent) -> void:
	if visible and (event.is_action_pressed("ui_cancel") or event.is_action_pressed("pause")):
		get_viewport().set_input_as_handled()
		_close()

func _add_toggle(label: String, key: String) -> void:
	var toggle: CheckButton = CheckButton.new()
	toggle.text = label
	toggle.custom_minimum_size.y = 30
	toggle.add_theme_font_size_override("font_size", 14)
	toggle.add_theme_stylebox_override("normal", PQStyle.panel(PQStyle.BOARD, PQStyle.EDGE))
	toggle.add_theme_stylebox_override("hover", PQStyle.panel(PQStyle.BOARD, PQStyle.CYAN))
	toggle.add_theme_stylebox_override("pressed", PQStyle.panel(PQStyle.BOARD, PQStyle.EDGE))
	toggle.add_theme_stylebox_override("hover_pressed", PQStyle.panel(PQStyle.BOARD, PQStyle.CYAN))
	toggle.add_theme_stylebox_override("focus", _focus_border())
	toggle.set_pressed_no_signal(bool(GameState.settings[key]))
	PQStyle.menu_feedback(toggle)
	toggle.toggled.connect(_toggle_changed.bind(key, toggle))
	_rows.add_child(toggle)
	_focus_order.append(toggle)

func _add_slider(label: String, key: String) -> void:
	var row: HBoxContainer = HBoxContainer.new()
	row.custom_minimum_size.y = 28
	row.add_theme_constant_override("separation", 12)
	_rows.add_child(row)
	var caption: Label = PQStyle.label_at(row, label, Vector2.ZERO, 14)
	caption.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var slider: HSlider = HSlider.new()
	slider.accessibility_name = label
	slider.custom_minimum_size.x = 140
	slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	slider.max_value = 1.0
	slider.step = 0.1
	slider.add_theme_stylebox_override("slider", _slider_track(PQStyle.CHIP))
	slider.add_theme_stylebox_override("grabber_area", _slider_track(PQStyle.CYAN))
	slider.add_theme_stylebox_override("grabber_area_highlight", _slider_track(PQStyle.CYAN))
	slider.set_value_no_signal(float(GameState.settings[key]))
	row.add_child(slider)
	var outline: Panel = Panel.new()
	outline.mouse_filter = Control.MOUSE_FILTER_IGNORE
	outline.add_theme_stylebox_override("panel", _focus_border())
	outline.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	outline.offset_left = -4.0
	outline.offset_right = 4.0
	outline.hide()
	slider.add_child(outline)
	PQStyle.menu_feedback(slider)
	slider.focus_entered.connect(outline.show)
	slider.focus_exited.connect(outline.hide)
	var value_label: Label = PQStyle.label_at(row, _percent(slider.value), Vector2.ZERO, 13)
	value_label.custom_minimum_size.x = 42
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	slider.value_changed.connect(_slider_changed.bind(key, slider, value_label))
	_focus_order.append(slider)

func _toggle_changed(value: bool, key: String, toggle: CheckButton) -> void:
	if not _save(key, value):
		toggle.set_pressed_no_signal(bool(GameState.settings[key]))

func _slider_changed(value: float, key: String, slider: HSlider, label: Label) -> void:
	if not _save(key, value):
		slider.set_value_no_signal(float(GameState.settings[key]))
	label.text = _percent(slider.value)

func _save(key: String, value: Variant) -> bool:
	var saved: bool = GameState.update_setting(key, value) == OK
	_status.text = "" if saved else "No se pudo guardar el ajuste."
	return saved

func _close() -> void:
	hide()
	closed.emit()
	queue_free()

static func _percent(value: float) -> String:
	return "%d%%" % roundi(value * 100.0)

static func _focus_border() -> StyleBoxFlat:
	return PQStyle.panel(Color.TRANSPARENT, PQStyle.CYAN)

static func _slider_track(color: Color) -> StyleBoxFlat:
	var style: StyleBoxFlat = PQStyle.bar(color)
	style.content_margin_top = 2.0
	style.content_margin_bottom = 2.0
	return style
